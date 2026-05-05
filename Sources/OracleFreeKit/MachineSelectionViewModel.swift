import Observation

@MainActor
@Observable
public final class MachineSelectionViewModel {
    public private(set) var selectedMachine: PodmanMachine?

    public init(selectedMachine: PodmanMachine? = nil) {
        self.selectedMachine = selectedMachine
    }

    public func select(_ machine: PodmanMachine) {
        selectedMachine = machine
    }
}
