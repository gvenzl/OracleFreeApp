import Foundation
import Testing
@testable import OracleFreeKit

struct OracleInstanceServiceTests {
    @Test func serviceReportsMissingContainer() async throws {
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        let status = try await service.inspectInstance()

        #expect(status == .missing)
    }

    @Test func serviceReportsStoppedContainer() async throws {
        let runtime = FakeContainerRuntime(containers: [
            ContainerSummary(
                id: "container-1",
                name: OracleContainerConfiguration.default.containerName,
                image: OracleContainerConfiguration.default.image,
                state: "exited",
                status: "Exited (0)"
            )
        ])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        let status = try await service.inspectInstance()

        #expect(status == .stopped(OracleContainerDetails(
            containerName: OracleContainerConfiguration.default.containerName,
            image: OracleContainerConfiguration.default.image,
            hostPort: OracleContainerConfiguration.default.hostPort,
            databasePort: OracleContainerConfiguration.default.databasePort,
            volumeName: OracleContainerConfiguration.default.volumeName,
            state: "exited",
            status: "Exited (0)",
            connectionInfo: .default
        )))
    }

    @Test func serviceReportsReadyContainerWithDetails() async throws {
        let runtime = FakeContainerRuntime(containers: [
            ContainerSummary(
                id: "container-1",
                name: OracleContainerConfiguration.default.containerName,
                image: OracleContainerConfiguration.default.image,
                state: "running",
                status: "healthy"
            )
        ])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        let status = try await service.inspectInstance()

        #expect(status == .ready(.default))
    }

    @Test func serviceKeepsRunningContainerInStartingStateUntilHealthIsReady() async throws {
        let runtime = FakeContainerRuntime(containers: [
            ContainerSummary(
                id: "container-1",
                name: OracleContainerConfiguration.default.containerName,
                image: OracleContainerConfiguration.default.image,
                state: "running",
                status: "Up 30 seconds (health: starting)"
            )
        ])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        let status = try await service.inspectInstance()

        #expect(status == .running(OracleContainerDetails(
            containerName: OracleContainerConfiguration.default.containerName,
            image: OracleContainerConfiguration.default.image,
            hostPort: OracleContainerConfiguration.default.hostPort,
            databasePort: OracleContainerConfiguration.default.databasePort,
            volumeName: OracleContainerConfiguration.default.volumeName,
            state: "running",
            status: "Up 30 seconds (health: starting)",
            connectionInfo: .default
        )))
    }

    @Test func serviceDoesNotTreatUnhealthyContainerAsReady() async throws {
        let runtime = FakeContainerRuntime(containers: [
            ContainerSummary(
                id: "container-1",
                name: OracleContainerConfiguration.default.containerName,
                image: OracleContainerConfiguration.default.image,
                state: "running",
                status: "unhealthy"
            )
        ])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        let status = try await service.inspectInstance()

        #expect(status == .running(OracleContainerDetails(
            containerName: OracleContainerConfiguration.default.containerName,
            image: OracleContainerConfiguration.default.image,
            hostPort: OracleContainerConfiguration.default.hostPort,
            databasePort: OracleContainerConfiguration.default.databasePort,
            volumeName: OracleContainerConfiguration.default.volumeName,
            state: "running",
            status: "unhealthy",
            connectionInfo: .default
        )))
    }

    @Test func serviceStartsContainerThroughRuntime() async throws {
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        try await service.startInstance()

        let recordedStarts = await runtime.startedContainerNames
        #expect(recordedStarts == [OracleContainerConfiguration.default.containerName])
    }

    @Test func serviceCreatesContainerThroughRuntime() async throws {
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        try await service.createInstance()

        let recordedConfigurations = await runtime.createdConfigurations
        #expect(recordedConfigurations == [.default])
    }

    @Test func serviceStopsContainerThroughRuntime() async throws {
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        try await service.stopInstance()

        let recordedStops = await runtime.stoppedContainerNames
        #expect(recordedStops == [OracleContainerConfiguration.default.containerName])
    }

    @Test func serviceDeletesContainerAndVolumeThroughRuntime() async throws {
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        try await service.deleteInstance()

        let recordedDeletes = await runtime.deletedContainerNames
        let recordedVolumeDeletes = await runtime.deletedVolumeNames
        #expect(recordedDeletes == [OracleContainerConfiguration.default.containerName])
        #expect(recordedVolumeDeletes == [OracleContainerConfiguration.default.volumeName])
    }

    @Test func serviceSkipsVolumeDeleteWhenVolumeNameIsEmpty() async throws {
        let configuration = OracleContainerConfiguration(
            containerName: "oracle-dev",
            image: "ghcr.io/gvenzl/oracle-free",
            databasePort: 1521,
            hostPort: 11521,
            volumeName: "",
            healthCheck: ContainerHealthCheckConfiguration(
                command: "healthcheck.sh",
                interval: "10s",
                timeout: "5s",
                retries: 10
            ),
            environmentVariables: []
        )
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: configuration)

        try await service.deleteInstance()

        let recordedDeletes = await runtime.deletedContainerNames
        let recordedVolumeDeletes = await runtime.deletedVolumeNames
        #expect(recordedDeletes == ["oracle-dev"])
        #expect(recordedVolumeDeletes == [])
    }
}

private actor FakeContainerRuntime: ContainerRuntime {
    let containers: [ContainerSummary]
    private(set) var startedContainerNames: [String] = []
    private(set) var stoppedContainerNames: [String] = []
    private(set) var deletedContainerNames: [String] = []
    private(set) var deletedVolumeNames: [String] = []
    private(set) var createdConfigurations: [OracleContainerConfiguration] = []

    init(containers: [ContainerSummary]) {
        self.containers = containers
    }

    func listContainers() async throws -> [ContainerSummary] {
        containers
    }

    func createContainer(configuration: OracleContainerConfiguration) async throws {
        createdConfigurations.append(configuration)
    }

    func startContainer(named name: String) async throws {
        startedContainerNames.append(name)
    }

    func stopContainer(named name: String) async throws {
        stoppedContainerNames.append(name)
    }

    func deleteContainer(named name: String) async throws {
        deletedContainerNames.append(name)
    }

    func deleteVolume(named name: String) async throws {
        deletedVolumeNames.append(name)
    }
}
