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
        let service = FakeOracleInstanceService(status: .ready(.default))
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.startInstance()

        #expect(await service.startCallCount == 1)
        #expect(viewModel.status == .ready(.default))
    }

    @Test func oracleInstanceViewModelCreatesInstanceAndRefreshesStatus() async throws {
        let service = FakeOracleInstanceService(status: .running)
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.createInstance()

        #expect(await service.createCallCount == 1)
        #expect(viewModel.status == .running)
    }

    @Test func oracleInstanceViewModelShowsCreatingStateWhileCreateIsRunning() async throws {
        let service = SuspendedCreateOracleInstanceService(statusAfterCreate: .running)
        let viewModel = OracleInstanceViewModel(service: service)

        let task = Task {
            await viewModel.createInstance()
        }
        await service.waitUntilCreateStarted()

        #expect(viewModel.status == .creating)

        await service.finishCreate()
        await task.value

        #expect(viewModel.status == .running)
    }

    @Test func oracleInstanceViewModelStopsInstanceAndRefreshesStatus() async throws {
        let service = FakeOracleInstanceService(status: .stopped)
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.stopInstance()

        #expect(await service.stopCallCount == 1)
        #expect(viewModel.status == .stopped)
    }

    @Test func oracleInstanceViewModelDeletesInstanceAndRefreshesStatus() async throws {
        let service = FakeOracleInstanceService(status: .missing)
        let viewModel = OracleInstanceViewModel(service: service)

        await viewModel.deleteInstance()

        #expect(await service.deleteCallCount == 1)
        #expect(viewModel.status == .missing)
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

    func inspectInstance() async throws -> OracleInstanceStatus {
        nextStatus
    }

    func createInstance() async throws {
        createCallCount += 1
    }

    func startInstance() async throws {
        startCallCount += 1
    }

    func stopInstance() async throws {
        stopCallCount += 1
    }

    func deleteInstance() async throws {
        deleteCallCount += 1
    }
}

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

    func inspectInstance() async throws -> OracleInstanceStatus {
        statusAfterCreate
    }

    func createInstance() async throws {
        await withCheckedContinuation { continuation in
            finishCreateContinuation = continuation
            createStarted = true
            createStartedContinuation?.resume()
            createStartedContinuation = nil
        }
    }

    func startInstance() async throws {}
    func stopInstance() async throws {}
    func deleteInstance() async throws {}
}
