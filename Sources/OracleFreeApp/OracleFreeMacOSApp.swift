import SwiftUI
import OracleFreeKit

@main
struct OracleFreeMacOSApp: App {
    @State private var appViewModel = AppViewModel(runtimeDetector: DefaultContainerRuntimeDetector())
    @State private var selectionViewModel = MachineSelectionViewModel()
    @State private var runtimeSelectionViewModel = RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker])
    @State private var oracleInstanceViewModel = Self.makeOracleInstanceViewModel(for: .podman)

    private static let runtimeFactory = DefaultContainerRuntimeFactory()

    var body: some Scene {
        WindowGroup {
            RootView(
                appViewModel: appViewModel,
                selectionViewModel: selectionViewModel,
                runtimeSelectionViewModel: runtimeSelectionViewModel,
                oracleInstanceViewModel: oracleInstanceViewModel
            )
            .task {
                await appViewModel.loadRuntimes()
                await configureRuntimeAfterDetection()
                await oracleInstanceViewModel.loadStatus()
            }
            .onChange(of: runtimeSelectionViewModel.selectedRuntime) { _, selectedRuntime in
                guard let selectedRuntime else {
                    return
                }

                configureRuntime(selectedRuntime)
                Task {
                    await oracleInstanceViewModel.loadStatus()
                }
            }
        }
    }

    private func configureRuntimeAfterDetection() async {
        guard case let .runtimeAvailability(runtimeAvailability) = appViewModel.status else {
            return
        }

        switch runtimeAvailability {
        case let .oneRuntimeAvailable(runtime):
            configureRuntime(runtime)
        case .multipleRuntimesAvailable:
            if let selectedRuntime = runtimeSelectionViewModel.selectedRuntime {
                configureRuntime(selectedRuntime)
            }
        case .noSupportedRuntimeInstalled:
            return
        }
    }

    private func configureRuntime(_ runtime: ContainerRuntimeKind) {
        oracleInstanceViewModel = Self.makeOracleInstanceViewModel(for: runtime)
    }

    private static func makeOracleInstanceViewModel(for runtime: ContainerRuntimeKind) -> OracleInstanceViewModel {
        OracleInstanceViewModel(
            service: OracleInstanceService(
                runtime: runtimeFactory.makeRuntime(for: runtime)
            )
        )
    }
}
