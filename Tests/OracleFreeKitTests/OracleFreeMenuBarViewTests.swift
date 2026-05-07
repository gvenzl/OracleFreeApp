import Observation
import Testing
@testable import OracleFreeKit

@MainActor
struct OracleFreeMenuBarViewTests {
    @Test func menuBarViewOffersStartWhenContainerIsStopped() {
        let view = OracleFreeMenuBarView(viewModel: PreviewMenuBarOracleInstanceViewModel(status: .stopped(.stoppedPreview)))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free"))
        #expect(output.contains("Status: Stopped"))
        #expect(output.contains("Configuration"))
        #expect(output.contains("Start Container"))
    }

    @Test func menuBarViewOffersStopWhenContainerIsReady() {
        let view = OracleFreeMenuBarView(viewModel: PreviewMenuBarOracleInstanceViewModel(status: .ready(.default)))

        let output = String(describing: view.body)

        #expect(output.contains("Status: Running"))
        #expect(output.contains("Stop Container"))
    }

    @Test func menuBarViewOffersStopWhileContainerIsStarting() {
        let view = OracleFreeMenuBarView(viewModel: PreviewMenuBarOracleInstanceViewModel(status: .running(.default)))

        let output = String(describing: view.body)

        #expect(output.contains("Status: Starting"))
        #expect(output.contains("Stop Container"))
    }
}

private extension OracleContainerDetails {
    static let stoppedPreview = OracleContainerDetails(
        containerName: OracleContainerConfiguration.default.containerName,
        image: OracleContainerConfiguration.default.image,
        hostPort: OracleContainerConfiguration.default.hostPort,
        databasePort: OracleContainerConfiguration.default.databasePort,
        volumeName: OracleContainerConfiguration.default.volumeName,
        state: "exited",
        status: "Exited (0)",
        connectionInfo: .default
    )
}

@MainActor
@Observable
private final class PreviewMenuBarOracleInstanceViewModel: OracleInstanceViewing {
    let status: OracleInstanceStatus
    let containerLogs: String? = nil
    var containerSettings: OracleContainerSettings = .default

    init(status: OracleInstanceStatus) {
        self.status = status
    }

    func createInstance() async {}
    func startInstance() async {}
    func stopInstance() async {}
    func deleteInstance() async {}
}
