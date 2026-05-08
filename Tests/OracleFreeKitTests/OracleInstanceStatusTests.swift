import Testing
@testable import OracleFreeKit

struct OracleInstanceStatusTests {
    @Test func stoppedStatusProvidesContainerStateMessage() {
        #expect(OracleInstanceStatus.stopped(.stoppedPreview).containerStateMessage == "Oracle Database Free is stopped")
    }

    @Test func readyStatusProvidesContainerStateMessage() {
        #expect(OracleInstanceStatus.ready(.default).containerStateMessage == "Oracle Database Free is ready")
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
