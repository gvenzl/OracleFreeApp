import Testing
@testable import OracleFreeKit

@MainActor
struct MachineSelectionViewModelTests {
    @Test func machineSelectionStartsWithoutSelectedMachine() {
        let viewModel = MachineSelectionViewModel()

        #expect(viewModel.selectedMachine == nil)
        #expect(viewModel.status == .loading)
    }

    @Test func machineSelectionStoresSelectedMachineInMemory() {
        let machine = PodmanMachine(
            id: "machine-default",
            name: "podman-machine-default",
            isRunning: true,
            isDefault: true,
            connectionName: "podman-machine-default-root"
        )
        let viewModel = MachineSelectionViewModel()

        viewModel.select(machine)

        #expect(viewModel.selectedMachine == machine)
        #expect(viewModel.status == .selected(machine))
    }

    @Test func machineSelectionAutoSelectsSingleRunningDefaultMachine() async {
        let machine = Self.machine(isRunning: true, isDefault: true)
        let runtime = FakePodmanRuntime(machines: [machine])
        let viewModel = MachineSelectionViewModel(runtime: runtime)

        await viewModel.loadMachines()

        #expect(viewModel.selectedMachine == machine)
        #expect(viewModel.status == .selected(machine))
    }

    @Test func machineSelectionNotifiesWhenRunningDefaultMachineIsReady() async {
        let machine = Self.machine(isRunning: true, isDefault: true)
        let runtime = FakePodmanRuntime(machines: [machine])
        let recorder = ReadyMachineRecorder()
        let viewModel = MachineSelectionViewModel(
            runtime: runtime,
            machineReadyHandler: recorder.record
        )

        await viewModel.loadMachines()

        #expect(recorder.machines == [machine])
    }

    @Test func machineSelectionReportsNoMachinesFound() async {
        let runtime = FakePodmanRuntime(machines: [])
        let viewModel = MachineSelectionViewModel(runtime: runtime)

        await viewModel.loadMachines()

        #expect(viewModel.selectedMachine == nil)
        #expect(viewModel.status == .noMachinesFound)
    }

    @Test func machineSelectionReportsStoppedDefaultMachine() async {
        let machine = Self.machine(isRunning: false, isDefault: true)
        let runtime = FakePodmanRuntime(machines: [machine])
        let viewModel = MachineSelectionViewModel(runtime: runtime)

        await viewModel.loadMachines()

        #expect(viewModel.selectedMachine == machine)
        #expect(viewModel.status == .stopped(machine))
    }

    @Test func machineSelectionRequiresSelectionWhenMultipleMachinesAreAvailable() async {
        let machines = [
            Self.machine(id: "machine-a", name: "machine-a", isRunning: true, isDefault: false),
            Self.machine(id: "machine-b", name: "machine-b", isRunning: true, isDefault: false)
        ]
        let runtime = FakePodmanRuntime(machines: machines)
        let viewModel = MachineSelectionViewModel(runtime: runtime)

        await viewModel.loadMachines()

        #expect(viewModel.selectedMachine == nil)
        #expect(viewModel.status == .selectionRequired(machines))
    }

    @Test func machineSelectionStartsSelectedStoppedMachine() async {
        let machine = Self.machine(isRunning: false, isDefault: true)
        let runtime = FakePodmanRuntime(machines: [machine])
        let viewModel = MachineSelectionViewModel(runtime: runtime)

        await viewModel.loadMachines()
        await viewModel.startSelectedMachine()

        let startedMachines = await runtime.startedMachineNames
        #expect(startedMachines == [machine.name])
        #expect(viewModel.selectedMachine?.isRunning == true)
        #expect(viewModel.status == .selected(Self.machine(isRunning: true, isDefault: true)))
    }

    @Test func machineSelectionIgnoresDuplicateStartRequestsWhileMachineIsStarting() async {
        let machine = Self.machine(isRunning: false, isDefault: true)
        let runtime = BlockingStartPodmanRuntime(machines: [machine])
        let viewModel = MachineSelectionViewModel(runtime: runtime)

        await viewModel.loadMachines()

        let firstStart = Task {
            await viewModel.startSelectedMachine()
        }
        await runtime.waitForStartAttemptCount(1)
        #expect(viewModel.status == .starting(machine))

        let secondStart = Task {
            await viewModel.startSelectedMachine()
        }
        try? await Task.sleep(nanoseconds: 10_000_000)

        let startedMachineNames = await runtime.startedMachineNames
        #expect(startedMachineNames == [machine.name])

        await runtime.resumeStarts()
        await firstStart.value
        await secondStart.value
    }

    @Test func machineSelectionNotifiesWhenStoppedMachineStarts() async {
        let machine = Self.machine(isRunning: false, isDefault: true)
        let runtime = FakePodmanRuntime(machines: [machine])
        let recorder = ReadyMachineRecorder()
        let viewModel = MachineSelectionViewModel(
            runtime: runtime,
            machineReadyHandler: recorder.record
        )

        await viewModel.loadMachines()
        await viewModel.startSelectedMachine()

        #expect(recorder.machines == [Self.machine(isRunning: true, isDefault: true)])
    }

    @Test func machineSelectionRefreshDetectsSelectedMachineStoppedOutsideApp() async {
        let runningMachine = Self.machine(isRunning: true, isDefault: true)
        let stoppedMachine = Self.machine(isRunning: false, isDefault: true)
        let runtime = MutablePodmanMachineRuntime(machines: [runningMachine])
        let viewModel = MachineSelectionViewModel(runtime: runtime, selectedMachine: runningMachine)

        await runtime.updateMachines([stoppedMachine])
        await viewModel.refreshSelectedMachineStatus()

        #expect(viewModel.selectedMachine == stoppedMachine)
        #expect(viewModel.status == .stopped(stoppedMachine))
    }

    @Test func machineSelectionRefreshReturnsToNoMachinesWhenSelectedMachineDisappears() async {
        let runningMachine = Self.machine(isRunning: true, isDefault: true)
        let runtime = MutablePodmanMachineRuntime(machines: [runningMachine])
        let viewModel = MachineSelectionViewModel(runtime: runtime, selectedMachine: runningMachine)

        await runtime.updateMachines([])
        await viewModel.refreshSelectedMachineStatus()

        #expect(viewModel.selectedMachine == nil)
        #expect(viewModel.status == .noMachinesFound)
    }

    @Test func machineSelectionMonitorDetectsSelectedMachineStoppedOutsideApp() async {
        let runningMachine = Self.machine(isRunning: true, isDefault: true)
        let stoppedMachine = Self.machine(isRunning: false, isDefault: true)
        let runtime = MutablePodmanMachineRuntime(machines: [runningMachine])
        let viewModel = MachineSelectionViewModel(runtime: runtime, selectedMachine: runningMachine)
        let monitorTask = Task {
            await viewModel.monitorSelectedMachineStatus(intervalNanoseconds: 1_000_000)
        }

        await runtime.updateMachines([stoppedMachine])
        await Self.waitForStatus(.stopped(stoppedMachine), in: viewModel)
        monitorTask.cancel()
        await monitorTask.value

        #expect(viewModel.selectedMachine == stoppedMachine)
        #expect(viewModel.status == .stopped(stoppedMachine))
    }

    private static func machine(
        id: String = "machine-default",
        name: String = "podman-machine-default",
        isRunning: Bool,
        isDefault: Bool
    ) -> PodmanMachine {
        PodmanMachine(
            id: id,
            name: name,
            isRunning: isRunning,
            isDefault: isDefault,
            connectionName: "\(name)-root"
        )
    }

    private static func waitForStatus(
        _ expectedStatus: PodmanMachineStatus,
        in viewModel: MachineSelectionViewModel
    ) async {
        for _ in 0..<100 {
            if viewModel.status == expectedStatus {
                return
            }

            try? await Task.sleep(nanoseconds: 1_000_000)
        }

        Issue.record("Timed out waiting for \(expectedStatus); current status is \(viewModel.status)")
    }
}

private actor FakePodmanRuntime: PodmanRuntime {
    let machines: [PodmanMachine]
    private(set) var startedMachineNames: [String] = []

    init(machines: [PodmanMachine]) {
        self.machines = machines
    }

    func discoverMachines() async throws -> [PodmanMachine] {
        machines
    }

    func startMachine(named name: String) async throws {
        startedMachineNames.append(name)
    }

    func listContainers() async throws -> [ContainerSummary] {
        []
    }

    func createContainer(configuration: OracleContainerConfiguration) async throws {}
    func startContainer(named name: String) async throws {}
    func stopContainer(named name: String) async throws {}
    func deleteContainer(named name: String) async throws {}
    func deleteVolume(named name: String) async throws {}
    func containerLogs(named name: String) async throws -> String { "" }
}

private actor BlockingStartPodmanRuntime: PodmanRuntime {
    let machines: [PodmanMachine]
    private(set) var startedMachineNames: [String] = []

    private var pendingStartContinuations: [CheckedContinuation<Void, Never>] = []
    private var startCountContinuations: [(Int, CheckedContinuation<Void, Never>)] = []

    init(machines: [PodmanMachine]) {
        self.machines = machines
    }

    func discoverMachines() async throws -> [PodmanMachine] {
        machines
    }

    func startMachine(named name: String) async throws {
        startedMachineNames.append(name)
        resumeSatisfiedStartCountWaiters()
        await withCheckedContinuation { continuation in
            pendingStartContinuations.append(continuation)
        }
    }

    func waitForStartAttemptCount(_ count: Int) async {
        guard startedMachineNames.count < count else {
            return
        }

        await withCheckedContinuation { continuation in
            startCountContinuations.append((count, continuation))
        }
    }

    func resumeStarts() {
        let continuations = pendingStartContinuations
        pendingStartContinuations = []
        continuations.forEach { $0.resume() }
    }

    func listContainers() async throws -> [ContainerSummary] {
        []
    }

    func createContainer(configuration: OracleContainerConfiguration) async throws {}
    func startContainer(named name: String) async throws {}
    func stopContainer(named name: String) async throws {}
    func deleteContainer(named name: String) async throws {}
    func deleteVolume(named name: String) async throws {}
    func containerLogs(named name: String) async throws -> String { "" }

    private func resumeSatisfiedStartCountWaiters() {
        let currentCount = startedMachineNames.count
        let readyContinuations = startCountContinuations
            .filter { requiredCount, _ in currentCount >= requiredCount }
            .map(\.1)

        startCountContinuations.removeAll { requiredCount, _ in
            currentCount >= requiredCount
        }

        readyContinuations.forEach { $0.resume() }
    }
}

private actor MutablePodmanMachineRuntime: PodmanRuntime {
    private var machines: [PodmanMachine]

    init(machines: [PodmanMachine]) {
        self.machines = machines
    }

    func updateMachines(_ machines: [PodmanMachine]) {
        self.machines = machines
    }

    func discoverMachines() async throws -> [PodmanMachine] {
        machines
    }

    func startMachine(named name: String) async throws {}
    func listContainers() async throws -> [ContainerSummary] { [] }
    func createContainer(configuration: OracleContainerConfiguration) async throws {}
    func startContainer(named name: String) async throws {}
    func stopContainer(named name: String) async throws {}
    func deleteContainer(named name: String) async throws {}
    func deleteVolume(named name: String) async throws {}
    func containerLogs(named name: String) async throws -> String { "" }
}

@MainActor
private final class ReadyMachineRecorder {
    private(set) var machines: [PodmanMachine] = []

    func record(_ machine: PodmanMachine) {
        machines.append(machine)
    }
}
