import SwiftUI

public struct MachineListView: View {
    private let machines: [PodmanMachine]
    private let selectionViewModel: MachineSelectionViewModel

    public init(machines: [PodmanMachine], selectionViewModel: MachineSelectionViewModel) {
        self.machines = machines
        self.selectionViewModel = selectionViewModel
    }

    public var body: some View {
        List(machines) { machine in
            Button {
                selectionViewModel.select(machine)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(machine.name)
                    Text(machine.connectionName)
                    if let selectionText = selectionText(for: machine) {
                        Text(selectionText)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    func selectionText(for machine: PodmanMachine) -> String? {
        guard selectionViewModel.selectedMachine == machine else {
            return nil
        }

        return "Selected for this session"
    }
}
