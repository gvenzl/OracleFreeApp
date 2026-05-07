import Testing
@testable import OracleFreeKit

struct ContainerRuntimeCommandFailureTests {
    @Test func commandFailureExplainsPortConflicts() {
        let failure = ContainerRuntimeCommandFailure(
            runtimeName: "Docker",
            operation: .createContainer,
            message: "Error starting userland proxy: listen tcp 0.0.0.0:1521: bind: address already in use"
        )

        #expect(failure.errorDescription == "Port conflict while creating Oracle Database Free. Another process or container is already using the configured host port. Change the host port in Configuration or stop the process using it.")
    }

    @Test func commandFailureExplainsMissingRuntimeCommand() {
        let failure = ContainerRuntimeCommandFailure(
            runtimeName: "Rancher Desktop",
            operation: .listContainers,
            message: "env: nerdctl: No such file or directory"
        )

        #expect(failure.errorDescription == "Unable to find Rancher Desktop's command line tool. Install Rancher Desktop or choose another container runtime.")
    }

    @Test func commandFailureExplainsImagePullFailures() {
        let failure = ContainerRuntimeCommandFailure(
            runtimeName: "Podman",
            operation: .createContainer,
            message: "manifest unknown: requested image not found"
        )

        #expect(failure.errorDescription == "Unable to pull the Oracle Database Free container image. Check the configured image name and your network access.")
    }

    @Test func commandFailureExplainsOperationFailures() {
        let failure = ContainerRuntimeCommandFailure(
            runtimeName: "Docker",
            operation: .stopContainer,
            message: "container is not running"
        )

        #expect(failure.errorDescription == "Unable to stop Oracle Database Free with Docker. Details: container is not running")
    }
}
