import SwiftUI

public struct OracleFreeMenuBarView<ViewModel: OracleInstanceViewing>: View {
    private let viewModel: ViewModel
    private let openConfiguration: @MainActor () -> Void

    public init(
        viewModel: ViewModel,
        openConfiguration: @escaping @MainActor () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.openConfiguration = openConfiguration
    }

    @ViewBuilder
    public var body: some View {
        Text("Oracle Database Free")
        Text("Status: \(statusTitle)")

        Divider()

        Button("Configuration") {
            openConfiguration()
        }

        Divider()

        switch viewModel.status {
        case .missing:
            Button("Create Container") {
                Task {
                    await viewModel.createInstance()
                }
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        case .creating:
            Text("Container Busy")
        case .stopped:
            Button("Start Container") {
                Task {
                    await viewModel.startInstance()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        case .running, .ready:
            Button("Stop Container") {
                Task {
                    await viewModel.stopInstance()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        case .failed:
            Text("Action Unavailable")
        }
    }

    private var statusTitle: String {
        switch viewModel.status {
        case .missing:
            return "Not Created"
        case .creating:
            return "Creating"
        case .stopped:
            return "Stopped"
        case .running:
            return "Starting"
        case .ready:
            return "Running"
        case .failed:
            return "Failed"
        }
    }
}

public struct OracleFreeMenuBarIcon: View {
    public init() {}

    @ViewBuilder
    public var body: some View {
        if let image = OracleFreeAppIconResource.menuBarImage() {
            Image(nsImage: image)
                .accessibilityLabel("Oracle Database Free")
        } else {
            Image(systemName: "externaldrive.connected.to.line.below")
                .accessibilityLabel("Oracle Database Free")
        }
    }
}
