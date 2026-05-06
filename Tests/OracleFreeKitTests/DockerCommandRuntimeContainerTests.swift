import Foundation
import Testing
@testable import OracleFreeKit

struct DockerCommandRuntimeContainerTests {
    @Test func dockerRuntimeListsContainersFromLineDelimitedJson() async throws {
        let runtime = DockerCommandRuntime(commandRunner: { arguments in
            #expect(arguments == ["ps", "--all", "--format", "json"])
            return Data("""
            {"ID":"container-1","Names":"oracle-free","Image":"ghcr.io/gvenzl/oracle-free","State":"running","Status":"Up 5 seconds (healthy)"}
            {"ID":"container-2","Names":"other-container","Image":"busybox","State":"exited","Status":"Exited (0)"}
            """.utf8)
        })

        let containers = try await runtime.listContainers()

        #expect(containers == [
            ContainerSummary(
                id: "container-1",
                name: "oracle-free",
                image: "ghcr.io/gvenzl/oracle-free",
                state: "running",
                status: "Up 5 seconds (healthy)"
            ),
            ContainerSummary(
                id: "container-2",
                name: "other-container",
                image: "busybox",
                state: "exited",
                status: "Exited (0)"
            )
        ])
    }

    @Test func dockerRuntimeCreatesContainerWithConfiguration() async throws {
        let configuration = OracleContainerConfiguration(
            containerName: "oracle-dev",
            image: "ghcr.io/gvenzl/oracle-free:slim",
            databasePort: 1521,
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            healthCheck: ContainerHealthCheckConfiguration(
                command: "healthcheck.sh",
                interval: "10s",
                timeout: "5s",
                retries: 10
            ),
            environmentVariables: [
                ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "LocalPassword123")
            ]
        )
        let recorder = CommandRecorder()
        let runtime = DockerCommandRuntime(commandRunner: recorder.recordingRunner)

        try await runtime.createContainer(configuration: configuration)

        #expect(await recorder.recordedArguments == [[
            "run",
            "--detach",
            "--name", "oracle-dev",
            "--publish", "11521:1521",
            "--volume", "oracle-dev-data:/opt/oracle/oradata",
            "--health-cmd", "healthcheck.sh",
            "--health-interval", "10s",
            "--health-timeout", "5s",
            "--health-retries", "10",
            "--env", "ORACLE_PASSWORD=LocalPassword123",
            "ghcr.io/gvenzl/oracle-free:slim"
        ]])
    }

    @Test func dockerRuntimeStartsContainer() async throws {
        let recorder = CommandRecorder()
        let runtime = DockerCommandRuntime(commandRunner: recorder.recordingRunner)

        try await runtime.startContainer(named: "oracle-free")

        #expect(await recorder.recordedArguments == [["start", "oracle-free"]])
    }
}

private actor CommandRecorder {
    private(set) var recordedArguments: [[String]] = []

    func recordingRunner(arguments: [String]) async throws -> Data {
        recordedArguments.append(arguments)
        return Data()
    }
}
