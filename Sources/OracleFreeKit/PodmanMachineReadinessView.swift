import SwiftUI

public struct PodmanMachineReadinessView: View {
    @State private var viewModel: MachineSelectionViewModel

    public init(viewModel: MachineSelectionViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    @ViewBuilder
    public var body: some View {
        switch viewModel.status {
        case .loading:
            Text("Loading Podman machines")
        case .noMachinesFound:
            VStack(alignment: .leading, spacing: 12) {
                Text("No Podman machines found")
                Text("Create and start a Podman machine, then try again.")
            }
        case let .selectionRequired(machines):
            VStack(alignment: .leading, spacing: 12) {
                Text("Select a Podman machine")
                MachineListView(machines: machines, selectionViewModel: viewModel)
            }
        case let .stopped(machine):
            VStack(alignment: .leading, spacing: 12) {
                Text("Podman machine is stopped")
                Text(machine.name)
                Button("Start Podman machine") {
                    Task {
                        await viewModel.startSelectedMachine()
                    }
                }
            }
        case let .starting(machine):
            VStack(alignment: .leading, spacing: 12) {
                Text("Starting Podman machine")
                Text(machine.name)
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Waiting for Podman machine to start")
                }
                Button("Start Podman machine") {}
                    .disabled(true)
            }
        case .selected:
            EmptyView()
        case let .failed(message):
            VStack(alignment: .leading, spacing: 12) {
                Text("Unable to load Podman machines")
                Text(message)
            }
        }
    }
}
