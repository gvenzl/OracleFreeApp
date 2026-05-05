import SwiftUI
import OracleFreeKit

@main
struct OracleFreeMacOSApp: App {
    @State private var appViewModel = AppViewModel(runtimeDetector: DefaultContainerRuntimeDetector())
    @State private var selectionViewModel = MachineSelectionViewModel()
    @State private var runtimeSelectionViewModel = RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker])
    @State private var oracleInstanceViewModel = OracleInstanceViewModel(
        service: OracleInstanceService(runtime: PodmanCommandRuntime())
    )

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
                await oracleInstanceViewModel.loadStatus()
            }
        }
    }
}
