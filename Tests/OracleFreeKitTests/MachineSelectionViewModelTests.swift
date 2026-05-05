import Testing
@testable import OracleFreeKit

@MainActor
struct MachineSelectionViewModelTests {
    @Test func machineSelectionStartsWithoutSelectedMachine() {
        let viewModel = MachineSelectionViewModel()

        #expect(viewModel.selectedMachine == nil)
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
    }
}
