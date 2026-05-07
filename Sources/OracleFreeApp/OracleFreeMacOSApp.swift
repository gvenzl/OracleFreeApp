import AppKit
import SwiftUI
import OracleFreeKit

@main
struct OracleFreeMacOSApp: App {
    @NSApplicationDelegateAdaptor(OracleFreeApplicationDelegate.self) private var appDelegate
    @State private var appViewModel = AppViewModel(runtimeDetector: DefaultContainerRuntimeDetector())
    @State private var selectionViewModel = MachineSelectionViewModel()
    @State private var runtimeSelectionViewModel = RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker])
    @State private var oracleInstanceViewModel = Self.makeOracleInstanceViewModel(for: .podman)
    @State private var showsConfigurationDialog = false

    private static let runtimeFactory = DefaultContainerRuntimeFactory()

    var body: some Scene {
        WindowGroup(OracleFreeAppMetadata.displayName, id: OracleFreeWindowID.main) {
            RootView(
                appViewModel: appViewModel,
                selectionViewModel: selectionViewModel,
                runtimeSelectionViewModel: runtimeSelectionViewModel,
                oracleInstanceViewModel: oracleInstanceViewModel,
                openConfiguration: {
                    showsConfigurationDialog = true
                }
            )
            .sheet(isPresented: $showsConfigurationDialog) {
                OracleContainerConfigurationDialogView(
                    settings: Binding {
                        oracleInstanceViewModel.containerSettings
                    } set: { settings in
                        oracleInstanceViewModel.containerSettings = settings
                    }
                )
            }
            .task {
                configureShutdownHandler()
                await appViewModel.loadRuntimes()
                if let runtime = configureRuntimeAfterDetection() {
                    await loadOracleStatusIfRuntimeIsReady(runtime)
                }
            }
            .onChange(of: runtimeSelectionViewModel.selectedRuntime) { _, selectedRuntime in
                guard let selectedRuntime else {
                    return
                }

                configureRuntime(selectedRuntime)
                Task {
                    await loadOracleStatusIfRuntimeIsReady(selectedRuntime)
                }
            }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About \(OracleFreeAppMetadata.displayName)") {
                    OracleFreeAppInfoDialog.show()
                }
            }
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .saveItem) {}
            CommandGroup(replacing: .importExport) {}
            CommandGroup(replacing: .printItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .textFormatting) {}
            CommandGroup(replacing: .help) {
                Button("\(OracleFreeAppMetadata.displayName) Help") {
                    OracleFreeAppInfoDialog.show()
                }
            }
        }

        MenuBarExtra {
            OracleFreeMenuBarView(
                viewModel: oracleInstanceViewModel,
                openConfiguration: {
                    showsConfigurationDialog = true
                }
            )
        } label: {
            OracleFreeMenuBarIcon()
        }
        .menuBarExtraStyle(.menu)
    }

    private func configureRuntimeAfterDetection() -> ContainerRuntimeKind? {
        guard case let .runtimeAvailability(runtimeAvailability) = appViewModel.status else {
            return nil
        }

        switch runtimeAvailability {
        case let .oneRuntimeAvailable(runtime):
            configureRuntime(runtime)
            return runtime
        case .multipleRuntimesAvailable:
            if let selectedRuntime = runtimeSelectionViewModel.selectedRuntime {
                configureRuntime(selectedRuntime)
                return selectedRuntime
            }
        case .noSupportedRuntimeInstalled:
            return nil
        }

        return nil
    }

    private func configureRuntime(_ runtime: ContainerRuntimeKind) {
        let containerRuntime = Self.runtimeFactory.makeRuntime(for: runtime)
        oracleInstanceViewModel = OracleInstanceViewModel(
            service: OracleInstanceService(runtime: containerRuntime)
        )
        configureShutdownHandler()

        if let podmanRuntime = containerRuntime as? any PodmanRuntime {
            let oracleInstanceViewModel = oracleInstanceViewModel
            selectionViewModel.configure(runtime: podmanRuntime) { _ in
                Task {
                    await oracleInstanceViewModel.loadStatus()
                }
            }
            Task {
                await selectionViewModel.loadMachines()
            }
        } else {
            selectionViewModel.reset()
        }
    }

    private func loadOracleStatusIfRuntimeIsReady(_ runtime: ContainerRuntimeKind) async {
        switch runtime {
        case .docker:
            await oracleInstanceViewModel.loadStatus()
        case .podman:
            guard case .selected = selectionViewModel.status else {
                return
            }
            await oracleInstanceViewModel.loadStatus()
        }
    }

    private static func makeOracleInstanceViewModel(for runtime: ContainerRuntimeKind) -> OracleInstanceViewModel {
        OracleInstanceViewModel(
            service: OracleInstanceService(
                runtime: runtimeFactory.makeRuntime(for: runtime)
            )
        )
    }

    private func configureShutdownHandler() {
        let oracleInstanceViewModel = oracleInstanceViewModel
        appDelegate.shutdownHandler = {
            await oracleInstanceViewModel.stopInstanceBeforeTermination()
        }
    }
}

@MainActor
private enum OracleFreeAppInfoDialog {
    static func show() {
        let alert = NSAlert()
        alert.messageText = OracleFreeAppMetadata.displayName
        alert.informativeText = """
        By: \(OracleFreeAppMetadata.author)
        Version: \(OracleFreeAppMetadata.version)
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

@MainActor
final class OracleFreeApplicationDelegate: NSObject, NSApplicationDelegate {
    var shutdownHandler: (() async -> Void)?

    private var terminationIsInProgress = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        removeUnsupportedTopLevelMenus()
    }

    func applicationDidUpdate(_ notification: Notification) {
        removeUnsupportedTopLevelMenus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !terminationIsInProgress else {
            return .terminateNow
        }

        terminationIsInProgress = true

        guard let shutdownHandler else {
            return .terminateNow
        }

        Task { @MainActor in
            await shutdownHandler()
            sender.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    private func removeMenus(titled titles: Set<String>) {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }

        for title in titles {
            if let menuItem = mainMenu.items.first(where: { $0.title == title }) {
                mainMenu.removeItem(menuItem)
            }
        }
    }

    private func removeUnsupportedTopLevelMenus() {
        DispatchQueue.main.async {
            self.removeMenus(titled: ["File", "Edit", "Format"])
        }
    }
}
