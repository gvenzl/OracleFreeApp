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

    @Test func podmanRuntimeReportsInvalidContainerJson() async {
        let runtime = PodmanCommandRuntime(commandRunner: { _ in
            Data("not-json".utf8)
        })

        await #expect(throws: ContainerRuntimeDataError.self) {
            _ = try await runtime.listContainers()
        }
    }

    @Test func podmanRuntimeReportsInvalidMachineJson() async {
        let runtime = PodmanCommandRuntime(commandRunner: { _ in
            Data("not-json".utf8)
        })

        await #expect(throws: ContainerRuntimeDataError.self) {
            _ = try await runtime.discoverMachines()
        }
    }

    @Test func podmanRuntimeStartsContainer() async throws {
        let recorder = CommandRecorder()
        let runtime = PodmanCommandRuntime(commandRunner: recorder.recordingRunner)

        try await runtime.startContainer(named: "oracle-free")

        #expect(await recorder.recordedArguments == [["start", "oracle-free"]])
    }

    @Test func podmanRuntimeStartsMachine() async throws {
        let recorder = CommandRecorder()
        let runtime = PodmanCommandRuntime(commandRunner: recorder.recordingRunner)

        try await runtime.startMachine(named: "podman-machine-default")

        #expect(await recorder.recordedArguments == [["machine", "start", "podman-machine-default"]])
    }

    @Test func podmanRuntimeDeletesVolume() async throws {
        let recorder = CommandRecorder()
        let runtime = PodmanCommandRuntime(commandRunner: recorder.recordingRunner)

        try await runtime.deleteVolume(named: "oracle-free-data")

        #expect(await recorder.recordedArguments == [["volume", "rm", "--force", "oracle-free-data"]])
    }

    @Test func podmanRuntimeLoadsContainerLogs() async throws {
        let runtime = PodmanCommandRuntime(commandRunner: { arguments in
            #expect(arguments == ["logs", "--tail", "120", "oracle-free"])
            return Data("startup logs".utf8)
        })

        let logs = try await runtime.containerLogs(named: "oracle-free")

        #expect(logs == "startup logs")
    }

    @Test func podmanRuntimeListsMachinesWhenConnectionNameIsMissing() async throws {
        let runtime = PodmanCommandRuntime(commandRunner: { arguments in
            #expect(arguments == ["machine", "list", "--format", "json"])
            return Data("""
            [
              {
                "Name": "podman-machine-default",
                "Default": true,
                "Running": false,
                "Starting": false,
                "RemoteUsername": "core"
              }
            ]
            """.utf8)
        })

        let machines = try await runtime.discoverMachines()

        #expect(machines == [
            PodmanMachine(
                id: "podman-machine-default",
                name: "podman-machine-default",
                isRunning: false,
                isDefault: true,
                connectionName: "podman-machine-default"
            )
        ])
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
            "-e", "ORACLE_PWD=LocalPassword123",
            "-e", "ORACLE_CHARACTERSET=AL32UTF8",
            "container-registry.oracle.com/database/free:latest-lite"
        ]])
    }

    @Test func podmanRuntimeOmitsVolumeOptionWhenVolumeNameIsEmpty() async throws {
        let configuration = OracleContainerConfiguration(
            containerName: "oracle-dev",
            image: "container-registry.oracle.com/database/free:latest-lite",
            databasePort: 1521,
            hostPort: 11521,
            volumeName: "",
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
            "--health-cmd", "healthcheck.sh",
            "--health-interval", "10s",
            "--health-timeout", "5s",
            "--health-retries", "10",
            "-e", "ORACLE_PWD=LocalPassword123",
            "-e", "ORACLE_CHARACTERSET=AL32UTF8",
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
