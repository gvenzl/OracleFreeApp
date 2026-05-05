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

        #expect(status == .stopped)
    }

    @Test func serviceReportsReadyContainerWithConnectionInfo() async throws {
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

        #expect(status == .ready(OracleConnectionInfo.default))
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

    @Test func serviceDeletesContainerThroughRuntime() async throws {
        let runtime = FakeContainerRuntime(containers: [])
        let service = OracleInstanceService(runtime: runtime, configuration: .default)

        try await service.deleteInstance()

        let recordedDeletes = await runtime.deletedContainerNames
        #expect(recordedDeletes == [OracleContainerConfiguration.default.containerName])
    }
}

private actor FakeContainerRuntime: ContainerRuntime {
    let containers: [ContainerSummary]
    private(set) var startedContainerNames: [String] = []
    private(set) var stoppedContainerNames: [String] = []
    private(set) var deletedContainerNames: [String] = []
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
}
