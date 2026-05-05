import SwiftUI

@MainActor
public protocol OracleInstanceViewing: AnyObject {
    var status: OracleInstanceStatus { get }
    func createInstance() async
    func startInstance() async
    func stopInstance() async
    func deleteInstance() async
}

public struct OracleInstanceView<ViewModel: OracleInstanceViewing>: View {
    @State private var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    @ViewBuilder
    public var body: some View {
        switch viewModel.status {
        case .missing:
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free container has not been created yet")
                Button("Create Oracle Database Free") {
                    Task {
                        await viewModel.createInstance()
                    }
                }
            }
        case .creating:
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free is being created")
                ProgressView()
            }
        case .stopped:
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free is stopped")
                Button("Start Oracle Database Free") {
                    Task {
                        await viewModel.startInstance()
                    }
                }
                Button("Delete Oracle Database Free") {
                    Task {
                        await viewModel.deleteInstance()
                    }
                }
            }
        case .running:
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free is starting")
                Button("Stop Oracle Database Free") {
                    Task {
                        await viewModel.stopInstance()
                    }
                }
            }
        case let .ready(connectionInfo):
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free is ready")
                Text("Service: \(connectionInfo.serviceName)")
                Text("Host: \(connectionInfo.host)")
                Text("Port: \(connectionInfo.port)")
                Button("Stop Oracle Database Free") {
                    Task {
                        await viewModel.stopInstance()
                    }
                }
                Button("Delete Oracle Database Free") {
                    Task {
                        await viewModel.deleteInstance()
                    }
                }
            }
        case let .failed(message):
            VStack(alignment: .leading, spacing: 12) {
                Text("Oracle Database Free failed")
                Text(message)
            }
        }
    }
}

extension OracleInstanceViewModel: OracleInstanceViewing {}
