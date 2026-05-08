import Foundation
import Testing
@testable import OracleFreeKit

@MainActor
struct OracleInstanceViewModelTests {
    @Test func oracleInstanceViewModelLoadsStatusFromService() async throws {
        let viewModel = OracleInstanceViewModel(service: FakeOracleInstanceService(status: .missing))

        await viewModel.loadStatus()

        #expect(viewModel.status == .missing)
    }

    @Test func oracleInstanceViewModelStartsInstanceAndRefreshesStatus() async throws {
        let service = SequenceOracleInstanceService(statuses: [.running(.default), .ready(.default)])
        let viewModel = Self.makeViewModel(service: service)

        await viewModel.startInstance()

        #expect(await service.startCallCount == 1)
        #expect(viewModel.status == .ready(.default))
    }

    @Test func oracleInstanceViewModelCreatesInstanceAndRefreshesStatus() async throws {
        let service = SequenceOracleInstanceService(statuses: [.running(.default), .ready(.default)])
        let viewModel = Self.makeViewModel(service: service)

        await viewModel.createInstance()

        #expect(await service.createCallCount == 1)
        #expect(viewModel.status == .ready(.default))
        #expect(await service.inspectCallCount == 2)
    }

    @Test func oracleInstanceViewModelLoadsContainerLogsWhenReadinessDoesNotComplete() async throws {
        let service = SequenceOracleInstanceService(
            statuses: [.running(.default)],
            logs: "DATABASE IS READY TO USE would appear here after startup completes"
        )
        let viewModel = Self.makeViewModel(service: service, maximumReadinessChecks: 1)

        await viewModel.createInstance()

        #expect(viewModel.status == .running(.default))
        #expect(viewModel.containerLogs == "DATABASE IS READY TO USE would appear here after startup completes")
        #expect(await service.logsCallCount == 1)
    }

    @Test func oracleInstanceViewModelLoadsContainerLogsWhenCreateFails() async throws {
        let service = FailingCreateOracleInstanceService(logs: "listener failed to bind to host port")
        let viewModel = Self.makeViewModel(service: service)

        await viewModel.createInstance()

        #expect(viewModel.status == .failed(message: "create failed"))
        #expect(viewModel.containerLogs == "listener failed to bind to host port")
        #expect(await service.logsCallCount == 1)
    }

    @Test func oracleInstanceViewModelCreatesWithCurrentSettingsAndKeepsOriginalConfiguration() async throws {
        let service = RecordingOracleInstanceService()
        let initialSettings = OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:slim",
            containerName: "oracle-dev",
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            password: "LocalPassword123",
            extraEnvironmentVariables: []
        )
        let replacementSettings = OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:full",
            containerName: "oracle-next",
            hostPort: 21521,
            volumeName: "oracle-next-data",
            password: "NextPassword123",
            extraEnvironmentVariables: []
        )
        let viewModel = Self.makeViewModel(service: service, settings: initialSettings, maximumReadinessChecks: 1)

        await viewModel.createInstance()
        viewModel.containerSettings = replacementSettings
        await viewModel.deleteInstance()

        #expect(await service.createdConfigurations == [initialSettings.containerConfiguration()])
        #expect(await service.deletedConfigurations == [initialSettings.containerConfiguration()])
    }

    @Test func oracleInstanceViewModelShowsCreatingStateWhileCreateIsRunning() async throws {
        let service = SuspendedCreateOracleInstanceService(statusAfterCreate: .running(.default))
        let viewModel = Self.makeViewModel(service: service, maximumReadinessChecks: 1)

        let task = Task {
            await viewModel.createInstance()
        }
        await service.waitUntilCreateStarted()

        #expect(viewModel.status == .creating)

        await service.finishCreate()
        await task.value

        #expect(viewModel.status == .running(.default))
    }

    @Test func oracleInstanceViewModelStopsInstanceAndRefreshesStatus() async throws {
        let service = FakeOracleInstanceService(status: .stopped(.default))
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.stopInstance()

        #expect(await service.stopCallCount == 1)
        #expect(viewModel.status == .stopped(.default))
    }

    @Test func oracleInstanceViewModelStopsReadyInstanceBeforeTermination() async throws {
        let service = FakeOracleInstanceService(status: .ready(.default))
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.loadStatus()
        await viewModel.stopInstanceBeforeTermination()

        #expect(await service.stopCallCount == 1)
    }

    @Test func oracleInstanceViewModelDoesNotStopMissingInstanceBeforeTermination() async throws {
        let service = FakeOracleInstanceService(status: .missing)
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.loadStatus()
        await viewModel.stopInstanceBeforeTermination()

        #expect(await service.stopCallCount == 0)
    }

    @Test func oracleInstanceViewModelDeletesInstanceAndRefreshesStatus() async throws {
        let service = FakeOracleInstanceService(status: .missing)
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.deleteInstance()

        #expect(await service.deleteCallCount == 1)
        #expect(viewModel.status == .missing)
    }

    @Test func oracleInstanceViewModelCanPreserveVolumeWhenDeletingInstance() async throws {
        let service = RecordingOracleInstanceService()
        let viewModel = Self.makeViewModel(service: service)

        await viewModel.deleteInstance(preservesVolume: true)

        #expect(await service.deleteRequests == [
            DeleteRequest(configuration: .default, preservesVolume: true)
        ])
    }

    private static func makeViewModel(
        service: any OracleInstanceServicing,
        settings: OracleContainerSettings = .default,
        maximumReadinessChecks: Int = 3
    ) -> OracleInstanceViewModel {
        OracleInstanceViewModel(
            service: service,
            containerSettings: settings,
            maximumReadinessChecks: maximumReadinessChecks,
            readinessCheckDelay: {}
        )
    }
}

private actor FakeOracleInstanceService: OracleInstanceServicing {
    private let nextStatus: OracleInstanceStatus
    private(set) var createCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var deleteCallCount = 0

    init(status: OracleInstanceStatus) {
        self.nextStatus = status
    }

    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        nextStatus
    }

    func createInstance(configuration: OracleContainerConfiguration) async throws {
        createCallCount += 1
    }

    func startInstance(configuration: OracleContainerConfiguration) async throws {
        startCallCount += 1
    }

    func stopInstance(configuration: OracleContainerConfiguration) async throws {
        stopCallCount += 1
    }

    func deleteInstance(configuration: OracleContainerConfiguration) async throws {
        deleteCallCount += 1
    }

    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String {
        ""
    }
}

private actor SequenceOracleInstanceService: OracleInstanceServicing {
    private var statuses: [OracleInstanceStatus]
    private let logs: String
    private(set) var inspectCallCount = 0
    private(set) var createCallCount = 0
    private(set) var startCallCount = 0
    private(set) var logsCallCount = 0

    init(statuses: [OracleInstanceStatus], logs: String = "") {
        self.statuses = statuses
        self.logs = logs
    }

    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        inspectCallCount += 1
        guard statuses.count > 1 else {
            return statuses[0]
        }

        return statuses.removeFirst()
    }

    func createInstance(configuration: OracleContainerConfiguration) async throws {
        createCallCount += 1
    }

    func startInstance(configuration: OracleContainerConfiguration) async throws {
        startCallCount += 1
    }

    func stopInstance(configuration: OracleContainerConfiguration) async throws {}
    func deleteInstance(configuration: OracleContainerConfiguration) async throws {}

    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String {
        logsCallCount += 1
        return logs
    }
}

private actor FailingCreateOracleInstanceService: OracleInstanceServicing {
    private let logs: String
    private(set) var logsCallCount = 0

    init(logs: String) {
        self.logs = logs
    }

    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        .missing
    }

    func createInstance(configuration: OracleContainerConfiguration) async throws {
        throw FailingCreateError()
    }

    func startInstance(configuration: OracleContainerConfiguration) async throws {}
    func stopInstance(configuration: OracleContainerConfiguration) async throws {}
    func deleteInstance(configuration: OracleContainerConfiguration) async throws {}

    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String {
        logsCallCount += 1
        return logs
    }
}

private struct FailingCreateError: LocalizedError {
    var errorDescription: String? {
        "create failed"
    }
}

private actor RecordingOracleInstanceService: OracleInstanceServicing {
    struct DeleteRequest: Equatable {
        let configuration: OracleContainerConfiguration
        let preservesVolume: Bool
    }

    private(set) var createdConfigurations: [OracleContainerConfiguration] = []
    private(set) var deletedConfigurations: [OracleContainerConfiguration] = []
    private(set) var deleteRequests: [DeleteRequest] = []

    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        .missing
    }

    func createInstance(configuration: OracleContainerConfiguration) async throws {
        createdConfigurations.append(configuration)
    }

    func startInstance(configuration: OracleContainerConfiguration) async throws {}
    func stopInstance(configuration: OracleContainerConfiguration) async throws {}

    func deleteInstance(configuration: OracleContainerConfiguration) async throws {
        deletedConfigurations.append(configuration)
    }

    func deleteInstance(configuration: OracleContainerConfiguration, preservesVolume: Bool) async throws {
        deletedConfigurations.append(configuration)
        deleteRequests.append(DeleteRequest(configuration: configuration, preservesVolume: preservesVolume))
    }

    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String {
        ""
    }
}

private typealias DeleteRequest = RecordingOracleInstanceService.DeleteRequest

private actor SuspendedCreateOracleInstanceService: OracleInstanceServicing {
    private let statusAfterCreate: OracleInstanceStatus
    private var createStarted = false
    private var createStartedContinuation: CheckedContinuation<Void, Never>?
    private var finishCreateContinuation: CheckedContinuation<Void, Never>?

    init(statusAfterCreate: OracleInstanceStatus) {
        self.statusAfterCreate = statusAfterCreate
    }

    func waitUntilCreateStarted() async {
        guard !createStarted else {
            return
        }

        await withCheckedContinuation { continuation in
            createStartedContinuation = continuation
        }
    }

    func finishCreate() {
        finishCreateContinuation?.resume()
        finishCreateContinuation = nil
    }

    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        statusAfterCreate
    }

    func createInstance(configuration: OracleContainerConfiguration) async throws {
        await withCheckedContinuation { continuation in
            finishCreateContinuation = continuation
            createStarted = true
            createStartedContinuation?.resume()
            createStartedContinuation = nil
        }
    }

    func startInstance(configuration: OracleContainerConfiguration) async throws {}
    func stopInstance(configuration: OracleContainerConfiguration) async throws {}
    func deleteInstance(configuration: OracleContainerConfiguration) async throws {}

    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String {
        ""
    }
}
