import Foundation
import Observation

@MainActor
@Observable
public final class OracleInstanceViewModel {
    public private(set) var status: OracleInstanceStatus
    public private(set) var containerLogs: String?
    public var containerSettings: OracleContainerSettings

    private let service: any OracleInstanceServicing
    private let maximumReadinessChecks: Int
    private let readinessCheckDelay: @MainActor @Sendable () async -> Void
    private var activeConfiguration: OracleContainerConfiguration

    public init(
        service: any OracleInstanceServicing,
        containerSettings: OracleContainerSettings = .default,
        maximumReadinessChecks: Int = 60,
        readinessCheckDelay: @escaping @MainActor @Sendable () async -> Void = {
            try? await Task.sleep(for: .seconds(2))
        }
    ) {
        self.service = service
        self.containerSettings = containerSettings
        self.maximumReadinessChecks = maximumReadinessChecks
        self.readinessCheckDelay = readinessCheckDelay
        self.activeConfiguration = containerSettings.containerConfiguration()
        self.status = .missing
    }

    public func loadStatus() async {
        await refreshStatus(after: nil, configuration: activeConfiguration)
    }

    public func createInstance() async {
        let configuration = containerSettings.containerConfiguration()
        activeConfiguration = configuration
        status = .creating
        await refreshStatus(
            after: {
                try await self.service.createInstance(configuration: configuration)
            },
            configuration: configuration,
            waitsForReadiness: true
        )
    }

    public func startInstance() async {
        let configuration = activeConfiguration
        if case let .stopped(details) = status {
            status = .running(Self.startingDetails(from: details))
        }
        await refreshStatus(
            after: {
                try await self.service.startInstance(configuration: configuration)
            },
            configuration: configuration,
            waitsForReadiness: true
        )
    }

    public func stopInstance() async {
        let configuration = activeConfiguration
        await refreshStatus(
            after: {
                try await self.service.stopInstance(configuration: configuration)
            },
            configuration: configuration
        )
    }

    public func stopInstanceBeforeTermination() async {
        switch status {
        case .creating, .running, .ready:
            do {
                try await service.stopInstance(configuration: activeConfiguration)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                status = .failed(message: message)
            }
        case .missing, .stopped, .failed:
            return
        }
    }

    public func deleteInstance() async {
        await deleteInstance(preservesVolume: false)
    }

    public func deleteInstance(preservesVolume: Bool) async {
        let configuration = activeConfiguration
        await refreshStatus(
            after: {
                try await self.service.deleteInstance(
                    configuration: configuration,
                    preservesVolume: preservesVolume
                )
            },
            configuration: configuration
        )

        if case .missing = status {
            activeConfiguration = containerSettings.containerConfiguration()
        }
    }

    private func refreshStatus(
        after action: (() async throws -> Void)?,
        configuration: OracleContainerConfiguration,
        waitsForReadiness: Bool = false
    ) async {
        do {
            if let action {
                try await action()
            }
            let inspectedStatus = try await service.inspectInstance(configuration: configuration)
            if waitsForReadiness {
                status = try await waitForReadiness(startingWith: inspectedStatus, configuration: configuration)
            } else {
                status = inspectedStatus
            }
            await updateContainerLogs(for: status, configuration: configuration)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = .failed(message: message)
            containerLogs = try? await service.containerLogs(configuration: configuration)
        }
    }

    private func waitForReadiness(
        startingWith initialStatus: OracleInstanceStatus,
        configuration: OracleContainerConfiguration
    ) async throws -> OracleInstanceStatus {
        var currentStatus = initialStatus

        for checkIndex in 0..<maximumReadinessChecks {
            switch currentStatus {
            case let .running(details):
                status = .running(details)
                guard checkIndex < maximumReadinessChecks - 1 else {
                    return currentStatus
                }
                await readinessCheckDelay()
                currentStatus = try await service.inspectInstance(configuration: configuration)
            case .missing, .creating, .stopped, .ready, .failed:
                return currentStatus
            }
        }

        return currentStatus
    }

    private func updateContainerLogs(
        for status: OracleInstanceStatus,
        configuration: OracleContainerConfiguration
    ) async {
        switch status {
        case .running, .failed:
            containerLogs = try? await service.containerLogs(configuration: configuration)
        case .missing, .creating, .stopped, .ready:
            containerLogs = nil
        }
    }

    private static func startingDetails(from details: OracleContainerDetails) -> OracleContainerDetails {
        OracleContainerDetails(
            containerName: details.containerName,
            image: details.image,
            hostPort: details.hostPort,
            databasePort: details.databasePort,
            volumeName: details.volumeName,
            state: "running",
            status: "starting",
            connectionInfo: details.connectionInfo
        )
    }
}
