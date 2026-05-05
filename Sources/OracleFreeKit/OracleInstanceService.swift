import Foundation

public protocol OracleInstanceServicing: Sendable {
    func inspectInstance() async throws -> OracleInstanceStatus
    func createInstance() async throws
    func startInstance() async throws
    func stopInstance() async throws
    func deleteInstance() async throws
}

public struct OracleInstanceService: OracleInstanceServicing {
    private let runtime: any ContainerRuntime
    private let configuration: OracleContainerConfiguration

    public init(runtime: any ContainerRuntime, configuration: OracleContainerConfiguration = .default) {
        self.runtime = runtime
        self.configuration = configuration
    }

    public func inspectInstance() async throws -> OracleInstanceStatus {
        let containers = try await runtime.listContainers()

        guard let container = containers.first(where: { $0.name == configuration.containerName }) else {
            return .missing
        }

        switch container.state.lowercased() {
        case "running":
            if container.status.lowercased().contains("healthy") {
                return .ready(.default)
            }
            return .running
        case "exited", "stopped", "created":
            return .stopped
        default:
            return .stopped
        }
    }

    public func createInstance() async throws {
        try await runtime.createContainer(configuration: configuration)
    }

    public func startInstance() async throws {
        try await runtime.startContainer(named: configuration.containerName)
    }

    public func stopInstance() async throws {
        try await runtime.stopContainer(named: configuration.containerName)
    }

    public func deleteInstance() async throws {
        try await runtime.deleteContainer(named: configuration.containerName)
    }
}
