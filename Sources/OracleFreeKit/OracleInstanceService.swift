import Foundation

public protocol OracleInstanceServicing: Sendable {
    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus
    func createInstance(configuration: OracleContainerConfiguration) async throws
    func startInstance(configuration: OracleContainerConfiguration) async throws
    func stopInstance(configuration: OracleContainerConfiguration) async throws
    func deleteInstance(configuration: OracleContainerConfiguration) async throws
    func deleteInstance(configuration: OracleContainerConfiguration, preservesVolume: Bool) async throws
    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String
}

public extension OracleInstanceServicing {
    func deleteInstance(configuration: OracleContainerConfiguration, preservesVolume: Bool) async throws {
        try await deleteInstance(configuration: configuration)
    }
}

public struct OracleInstanceService: OracleInstanceServicing {
    private let runtime: any ContainerRuntime
    private let defaultConfiguration: OracleContainerConfiguration

    public init(runtime: any ContainerRuntime, configuration: OracleContainerConfiguration = .default) {
        self.runtime = runtime
        self.defaultConfiguration = configuration
    }

    public func inspectInstance() async throws -> OracleInstanceStatus {
        try await inspectInstance(configuration: defaultConfiguration)
    }

    public func createInstance() async throws {
        try await createInstance(configuration: defaultConfiguration)
    }

    public func startInstance() async throws {
        try await startInstance(configuration: defaultConfiguration)
    }

    public func stopInstance() async throws {
        try await stopInstance(configuration: defaultConfiguration)
    }

    public func deleteInstance() async throws {
        try await deleteInstance(configuration: defaultConfiguration)
    }

    public func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        let containers = try await runtime.listContainers()

        guard let container = containers.first(where: { $0.name == configuration.containerName }) else {
            return .missing
        }

        switch container.state.lowercased() {
        case "running":
            if Self.isReadyStatus(container.status) {
                return .ready(containerDetails(for: container, configuration: configuration))
            }
            return .running(containerDetails(for: container, configuration: configuration))
        case "exited", "stopped", "created":
            return .stopped(containerDetails(for: container, configuration: configuration))
        default:
            return .stopped(containerDetails(for: container, configuration: configuration))
        }
    }

    public func createInstance(configuration: OracleContainerConfiguration) async throws {
        try await runtime.createContainer(configuration: configuration)
    }

    public func startInstance(configuration: OracleContainerConfiguration) async throws {
        try await runtime.startContainer(named: configuration.containerName)
    }

    public func stopInstance(configuration: OracleContainerConfiguration) async throws {
        try await runtime.stopContainer(named: configuration.containerName)
    }

    public func deleteInstance(configuration: OracleContainerConfiguration) async throws {
        try await deleteInstance(configuration: configuration, preservesVolume: false)
    }

    public func deleteInstance(configuration: OracleContainerConfiguration, preservesVolume: Bool) async throws {
        try await runtime.deleteContainer(named: configuration.containerName)

        let volumeName = configuration.volumeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !preservesVolume, !volumeName.isEmpty {
            try await runtime.deleteVolume(named: volumeName)
        }
    }

    public func containerLogs(configuration: OracleContainerConfiguration) async throws -> String {
        try await runtime.containerLogs(named: configuration.containerName)
    }

    private func containerDetails(
        for container: ContainerSummary,
        configuration: OracleContainerConfiguration
    ) -> OracleContainerDetails {
        OracleContainerDetails(
            containerName: configuration.containerName,
            image: container.image,
            hostPort: configuration.hostPort,
            databasePort: configuration.databasePort,
            volumeName: configuration.volumeName,
            state: container.state,
            status: container.status,
            connectionInfo: OracleConnectionInfo(
                host: "localhost",
                port: configuration.hostPort,
                serviceName: "FREEPDB1",
                username: "system",
                password: password(from: configuration)
            )
        )
    }

    private func password(from configuration: OracleContainerConfiguration) -> String {
        configuration.environmentVariables.first { variable in
            let name = variable.name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            return name == "ORACLE_PASSWORD" || name == "ORACLE_PWD"
        }?.value ?? ""
    }

    private static func isReadyStatus(_ status: String) -> Bool {
        let normalizedStatus = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedStatus == "healthy"
            || normalizedStatus.contains("(healthy)")
            || normalizedStatus.contains("health: healthy")
    }
}
