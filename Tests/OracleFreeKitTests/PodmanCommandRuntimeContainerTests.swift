import Foundation
import Testing
@testable import OracleFreeKit

struct PodmanCommandRuntimeContainerTests {
    @Test func podmanRuntimeListsContainers() async throws {
        let runtime = PodmanCommandRuntime(commandRunner: { arguments in
            #expect(arguments == ["ps", "--all", "--format", "json"])
            return Data("""
            [
              {
                "Id": "container-1",
                "Names": ["oracle-free"],
                "Image": "container-registry.oracle.com/database/free:latest",
                "State": "running",
                "Status": "Up 5 seconds"
              }
            ]
            """.utf8)
        })

        let containers = try await runtime.listContainers()

        #expect(containers.count == 1)
        #expect(containers[0] == ContainerSummary(
            id: "container-1",
            name: "oracle-free",
            image: "container-registry.oracle.com/database/free:latest",
            state: "running",
            status: "Up 5 seconds"
        ))
    }

    @Test func podmanRuntimeStartsContainer() async throws {
        let recorder = CommandRecorder()
        let runtime = PodmanCommandRuntime(commandRunner: recorder.recordingRunner)

        try await runtime.startContainer(named: "oracle-free")

        #expect(await recorder.recordedArguments == [["start", "oracle-free"]])
    }

    @Test func podmanRuntimeCreatesContainerWithConfiguration() async throws {
        let configuration = OracleContainerConfiguration(
            containerName: "oracle-dev",
            image: "container-registry.oracle.com/database/free:latest-lite",
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
                ContainerEnvironmentVariable(name: "ORACLE_PWD", value: "LocalPassword123"),
                ContainerEnvironmentVariable(name: "ORACLE_CHARACTERSET", value: "AL32UTF8")
            ]
        )
        let recorder = CommandRecorder()
        let runtime = PodmanCommandRuntime(commandRunner: recorder.recordingRunner)

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
            "--env", "ORACLE_PWD=LocalPassword123",
            "--env", "ORACLE_CHARACTERSET=AL32UTF8",
            "container-registry.oracle.com/database/free:latest-lite"
        ]])
    }

    @Test func podmanRuntimePropagatesReadableContainerErrors() async {
        let runtime = PodmanCommandRuntime(commandRunner: { _ in
            throw FakeContainerError(message: "container failure")
        })

        await #expect(throws: FakeContainerError.self) {
            _ = try await runtime.listContainers()
        }
    }
}

private struct FakeContainerError: Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

private actor CommandRecorder {
    private(set) var recordedArguments: [[String]] = []

    func recordingRunner(arguments: [String]) async throws -> Data {
        recordedArguments.append(arguments)
        return Data()
    }
}
