import SwiftUI

public struct RootView<OracleViewModel: OracleInstanceViewing>: View {
    private let appViewModel: AppViewModel
    private let selectionViewModel: MachineSelectionViewModel
    private let runtimeSelectionViewModel: RuntimeSelectionViewModel
    private let oracleInstanceViewModel: OracleViewModel
    private let openConfiguration: @MainActor () -> Void

    public init(
        appViewModel: AppViewModel,
        selectionViewModel: MachineSelectionViewModel,
        runtimeSelectionViewModel: RuntimeSelectionViewModel,
        oracleInstanceViewModel: OracleViewModel,
        openConfiguration: @escaping @MainActor () -> Void = {}
    ) {
        self.appViewModel = appViewModel
        self.selectionViewModel = selectionViewModel
        self.runtimeSelectionViewModel = runtimeSelectionViewModel
        self.oracleInstanceViewModel = oracleInstanceViewModel
        self.openConfiguration = openConfiguration
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
                Text("Install Docker, Podman, or Rancher Desktop, then try again.")
            }
        case let .oneRuntimeAvailable(runtime):
            selectedRuntimeView(for: runtime, canChangeRuntime: false)
        case .multipleRuntimesAvailable:
            if let runtime = runtimeSelectionViewModel.selectedRuntime {
                selectedRuntimeView(for: runtime, canChangeRuntime: true)
            } else {
                RuntimeSelectionView(viewModel: runtimeSelectionViewModel)
            }
        }
    }

    @ViewBuilder
    private func selectedRuntimeView(
        for runtime: ContainerRuntimeKind,
        canChangeRuntime: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            runtimeHeader(for: runtime, canChangeRuntime: canChangeRuntime)

            switch runtime {
            case .podman:
                podmanRuntimeView()
            case .docker, .rancherDesktop:
                OracleInstanceView(
                    viewModel: oracleInstanceViewModel,
                    openConfiguration: openConfiguration
                )
            }
        }
    }

    private func runtimeHeader(
        for runtime: ContainerRuntimeKind,
        canChangeRuntime: Bool
    ) -> some View {
        HStack {
            Text("Runtime: \(runtime.displayName)")
            Spacer()
            if canChangeRuntime {
                Button("Change Runtime") {
                    runtimeSelectionViewModel.clearSelection()
                }
            }
        }
    }

    @ViewBuilder
    private func podmanRuntimeView() -> some View {
        switch selectionViewModel.status {
        case .selected:
            OracleInstanceView(
                viewModel: oracleInstanceViewModel,
                openConfiguration: openConfiguration
            )
        default:
            PodmanMachineReadinessView(viewModel: selectionViewModel)
        }
    }
}
