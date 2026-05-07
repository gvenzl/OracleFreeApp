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
}

public struct OracleInstanceView<ViewModel: OracleInstanceViewing>: View {
    @State private var viewModel: ViewModel
    @State private var showsDeleteConfirmation = false
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
            .confirmationDialog(
                "Delete Oracle Database Free?",
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Oracle Database Free", role: .destructive) {
                    Task {
                        await viewModel.deleteInstance()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the container and configured volume.")
            }
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
                Text("Oracle Database Free is stopped")
                containerDetailsBox(details, trafficLight: .stopped)
                Button("Start Oracle Database Free") {
                    Task {
                        await viewModel.startInstance()
                    }
                }
                deleteButton()
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
                Text("Oracle Database Free is ready")
                connectionDetailsView(details.connectionInfo)
                containerDetailsBox(details, trafficLight: .running)
                Button("Stop Oracle Database Free") {
                    Task {
                        await viewModel.stopInstance()
                    }
                }
                deleteButton()
            }
        case let .failed(message):
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free failed")
                Text(message)
                containerLogsView()
            }
        }
    }

    private func deleteButton() -> some View {
        Button("Delete Oracle Database Free", role: .destructive) {
            showsDeleteConfirmation = true
        }
    }

    private func connectionDetailsView(_ connectionInfo: OracleConnectionInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Connection Details")
            Text("Service: \(connectionInfo.serviceName)")
            Text("Host: \(connectionInfo.host)")
            Text("Port: \(String(connectionInfo.port))")
            Text("Username: \(connectionInfo.username)")
            Text("Password: \(connectionInfo.password)")
            Text("Connection String: \(connectionString(for: connectionInfo))")
        }
        .textSelection(.enabled)
    }

    private func connectionString(for connectionInfo: OracleConnectionInfo) -> String {
        "\(connectionInfo.username)/\(connectionInfo.password)@\(connectionInfo.host):\(connectionInfo.port)/\(connectionInfo.serviceName)"
    }

    private func containerDetailsBox(
        _ details: OracleContainerDetails,
        trafficLight: OracleContainerTrafficLight
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
                Circle()
                    .fill(trafficLight.color)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(.primary.opacity(0.25), lineWidth: 0.5)
                    )
                Text(trafficLight.title)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Container state: \(trafficLight.title)")
            Text("Name: \(details.containerName)")
            Text("Image: \(details.image)")
            Text("Port: \(String(details.hostPort)):\(String(details.databasePort))")
            Text("Volume: \(displayVolumeName(for: details.volumeName))")
            Text("State: \(details.state)")
            Text("Status: \(details.status)")
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
