import Foundation
import Testing
@testable import OracleFreeKit

struct RancherDesktopCommandRuntimeTests {
    @Test func rancherDesktopRuntimeUsesDockerCompatibleContainerCommands() async throws {
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
        let runtime = RancherDesktopCommandRuntime(commandRunner: recorder.recordingRunner)

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
            "-e", "ORACLE_PASSWORD=LocalPassword123",
            "ghcr.io/gvenzl/oracle-free:slim"
        ]])
    }

    @Test func rancherDesktopRuntimeLoadsContainerLogs() async throws {
        let runtime = RancherDesktopCommandRuntime(commandRunner: { arguments in
            #expect(arguments == ["logs", "--tail", "120", "oracle-free"])
            return Data("startup logs".utf8)
        })

        let logs = try await runtime.containerLogs(named: "oracle-free")

        #expect(logs == "startup logs")
    }
}

private actor CommandRecorder {
    private(set) var recordedArguments: [[String]] = []

    func recordingRunner(arguments: [String]) async throws -> Data {
        recordedArguments.append(arguments)
        return Data()
    }
}
