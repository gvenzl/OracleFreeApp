import AppKit
import SwiftUI

@MainActor
public protocol OracleInstanceViewing: AnyObject {
    var status: OracleInstanceStatus { get }
    var containerLogs: String? { get }
    var containerSettings: OracleContainerSettings { get set }
    func createInstance() async
    func startInstance() async
    func stopInstance() async
    func deleteInstance() async
    func deleteInstance(preservesVolume: Bool) async
}

public extension OracleInstanceViewing {
    func deleteInstance(preservesVolume: Bool) async {
        await deleteInstance()
    }
}

public struct OracleInstanceView<ViewModel: OracleInstanceViewing>: View {
    @State private var viewModel: ViewModel
    @State private var showsDeleteConfirmation = false
    @State private var preservesVolumeOnDelete = false
    @State private var deleteConfirmationVolumeName = ""
    private let openConfiguration: @MainActor () -> Void

    public init(
        viewModel: ViewModel,
        openConfiguration: @escaping @MainActor () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.openConfiguration = openConfiguration
    }

    @ViewBuilder
    public var body: some View {
        statusContent
            .sheet(isPresented: $showsDeleteConfirmation) {
                DeleteOracleInstanceDialogView(
                    volumeName: deleteConfirmationVolumeName,
                    preservesVolume: $preservesVolumeOnDelete,
                    onCancel: {
                        showsDeleteConfirmation = false
                    },
                    onDelete: { preservesVolume in
                        showsDeleteConfirmation = false
                        Task {
                            await viewModel.deleteInstance(preservesVolume: preservesVolume)
                        }
                    }
                )
            }
    }

    private func showDeleteConfirmation(volumeName: String) {
        deleteConfirmationVolumeName = volumeName
        preservesVolumeOnDelete = false
        showsDeleteConfirmation = true
    }

    @ViewBuilder
    private var statusContent: some View {
        switch viewModel.status {
        case .missing:
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free container has not been created yet")
                HStack {
                    Button("Create Oracle Database Free") {
                        Task {
                            await viewModel.createInstance()
                        }
                    }
                    Button("Configuration") {
                        openConfiguration()
                    }
                }
            }
        case .creating:
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free is being created")
                ProgressView()
            }
        case let .stopped(details):
            VStack(alignment: .leading, spacing: 12) {
                containerDetailsBox(
                    details,
                    trafficLight: .stopped,
                    stateMessage: viewModel.status.containerStateMessage
                )
                Button("Start Oracle Database Free") {
                    Task {
                        await viewModel.startInstance()
                    }
                }
                deleteButton(volumeName: details.volumeName)
            }
        case let .running(details):
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free is starting")
                ProgressView()
                containerDetailsBox(details, trafficLight: .starting)
                containerLogsView()
                Button("Stop Oracle Database Free") {
                    Task {
                        await viewModel.stopInstance()
                    }
                }
            }
        case let .ready(details):
            VStack(alignment: .leading, spacing: 12) {
                containerDetailsBox(
                    details,
                    trafficLight: .running,
                    stateMessage: viewModel.status.containerStateMessage
                )
                connectionDetailsView(details.connectionInfo)
                Button("Stop Oracle Database Free") {
                    Task {
                        await viewModel.stopInstance()
                    }
                }
                deleteButton(volumeName: details.volumeName)
            }
        case let .failed(message):
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free failed")
                Text(message)
                containerLogsView()
            }
        }
    }

    private func deleteButton(volumeName: String) -> some View {
        Button("Delete Oracle Database Free", role: .destructive) {
            showDeleteConfirmation(volumeName: volumeName)
        }
    }

    private func connectionDetailsView(_ connectionInfo: OracleConnectionInfo) -> some View {
        let connectionString = connectionInfo.connectionString

        return GroupBox("Connection Details") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        connectionDetailRow(title: "Host", value: connectionInfo.host)
                        connectionDetailRow(title: "Port", value: String(connectionInfo.port))
                        connectionDetailRow(title: "Service", value: connectionInfo.serviceName)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        connectionDetailRow(title: "Username", value: connectionInfo.username)
                        connectionDetailRow(title: "Password", value: connectionInfo.password)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Connect String")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(connectionString)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            copyConnectionString(connectionString)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .textSelection(.enabled)
    }

    private func connectionDetailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
    }

    private func copyConnectionString(_ connectionString: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(connectionString, forType: .string)
    }

    private func containerDetailsBox(
        _ details: OracleContainerDetails,
        trafficLight: OracleContainerTrafficLight,
        stateMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                OracleFreeAppIconView(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Container")
                    Text(details.containerName)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(trafficLight.color)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(.primary.opacity(0.25), lineWidth: 0.5)
                            )
                        Text(trafficLight.title)
                    }
                    if let stateMessage {
                        Text(stateMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Container state: \(trafficLight.title)")
            Text("Name: \(details.containerName)")
            Text("Image: \(details.image)")
            Text("Port: \(String(details.hostPort)):\(String(details.databasePort))")
            Text("Volume: \(displayVolumeName(for: details.volumeName))")
            Text("Con State: \(details.state)")
            Text("Con status: \(details.status)")
        }
        .padding(12)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.separator, lineWidth: 1)
        )
    }

    private func displayVolumeName(for volumeName: String) -> String {
        let trimmedVolumeName = volumeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedVolumeName.isEmpty ? "No volume defined" : trimmedVolumeName
    }

    @ViewBuilder
    private func containerLogsView() -> some View {
        if let logs = viewModel.containerLogs?.trimmingCharacters(in: .whitespacesAndNewlines),
           !logs.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Container Logs")
                ScrollView {
                    Text(logs)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 80, maxHeight: 180)
            }
        }
    }
}

extension OracleInstanceViewModel: OracleInstanceViewing {}

struct DeleteOracleInstanceDialogView: View {
    let volumeName: String
    @Binding var preservesVolume: Bool
    let onCancel: @MainActor () -> Void
    let onDelete: @MainActor (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Delete Oracle Database Free?")
                .font(.headline)

            Text(deleteMessage)
                .foregroundStyle(.secondary)

            if hasConfiguredVolume {
                Toggle("Preserve volume \(trimmedVolumeName)", isOn: $preservesVolume)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                Button("Delete Oracle Database Free", role: .destructive) {
                    onDelete(preservesVolume)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private var deleteMessage: String {
        if hasConfiguredVolume {
            return "This removes the container. Leave Preserve volume unchecked to delete the configured volume alongside it."
        }

        return "This removes the container. No volume is configured."
    }

    private var hasConfiguredVolume: Bool {
        !trimmedVolumeName.isEmpty
    }

    private var trimmedVolumeName: String {
        volumeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct OracleContainerTrafficLightRGB: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

enum OracleContainerTrafficLight {
    case stopped
    case starting
    case running

    var title: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        }
    }

    var color: Color {
        rgb.color
    }

    var rgb: OracleContainerTrafficLightRGB {
        switch self {
        case .stopped:
            return OracleContainerTrafficLightRGB(red: 1.0, green: 95.0 / 255.0, blue: 87.0 / 255.0)
        case .starting:
            return OracleContainerTrafficLightRGB(red: 1.0, green: 189.0 / 255.0, blue: 46.0 / 255.0)
        case .running:
            return OracleContainerTrafficLightRGB(red: 40.0 / 255.0, green: 200.0 / 255.0, blue: 64.0 / 255.0)
        }
    }
}

private struct OracleFreeAppIconView: View {
    let size: CGFloat

    @ViewBuilder
    var body: some View {
        if let image = OracleFreeAppIconResource.image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                .accessibilityLabel("Oracle Free App icon")
        } else {
            Image(systemName: "externaldrive.connected.to.line.below")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(.red)
                .accessibilityLabel("Oracle Free App icon")
        }
    }
}
