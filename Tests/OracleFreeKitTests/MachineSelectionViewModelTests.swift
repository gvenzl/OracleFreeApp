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

@MainActor
private final class ReadyMachineRecorder {
    private(set) var machines: [PodmanMachine] = []

    func record(_ machine: PodmanMachine) {
        machines.append(machine)
    }
}
