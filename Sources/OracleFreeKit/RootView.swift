import SwiftUI

public struct RootView<OracleViewModel: OracleInstanceViewing>: View {
    private let appViewModel: AppViewModel
    private let selectionViewModel: MachineSelectionViewModel
    private let runtimeSelectionViewModel: RuntimeSelectionViewModel
    private let oracleInstanceViewModel: OracleViewModel

    public init(
        appViewModel: AppViewModel,
        selectionViewModel: MachineSelectionViewModel,
        runtimeSelectionViewModel: RuntimeSelectionViewModel,
        oracleInstanceViewModel: OracleViewModel
    ) {
        self.appViewModel = appViewModel
        self.selectionViewModel = selectionViewModel
        self.runtimeSelectionViewModel = runtimeSelectionViewModel
        self.oracleInstanceViewModel = oracleInstanceViewModel
    }

    @ViewBuilder
    public var body: some View {
        switch appViewModel.status {
        case .loading:
            Text("Loading runtimes")
        case let .failed(message):
            VStack(alignment: .leading, spacing: 12) {
                Text("Runtime unavailable")
                Text(message)
            }
            .padding()
        case let .runtimeAvailability(status):
            runtimeAvailabilityView(for: status)
                .padding()
        }
    }

    @ViewBuilder
    private func runtimeAvailabilityView(for status: ContainerRuntimeInstallationStatus) -> some View {
        switch status {
        case .noSupportedRuntimeInstalled:
            VStack(alignment: .leading, spacing: 12) {
                Text("No supported container runtime found")
                Text("Install a supported runtime such as Podman or Docker, then try again.")
            }
        case .oneRuntimeAvailable:
            OracleInstanceView(viewModel: oracleInstanceViewModel)
        case .multipleRuntimesAvailable:
            if runtimeSelectionViewModel.selection != nil {
                OracleInstanceView(viewModel: oracleInstanceViewModel)
            } else {
                RuntimeSelectionView(viewModel: runtimeSelectionViewModel)
            }
        }
    }
}
