import Foundation

public struct RancherDesktopCommandRuntime: ContainerRuntime {
    public let commandPath: String

    private let dockerCompatibleRuntime: DockerCommandRuntime

    public init(commandPath: String = "nerdctl") {
        self.commandPath = commandPath
        self.dockerCompatibleRuntime = DockerCommandRuntime(
            commandPath: commandPath,
            runtimeName: "Rancher Desktop"
        )
    }

    public init(commandRunner: @escaping @Sendable ([String]) async throws -> Data) {
        self.commandPath = "<custom>"
        self.dockerCompatibleRuntime = DockerCommandRuntime(commandRunner: commandRunner)
    }

    public func listContainers() async throws -> [ContainerSummary] {
        try await dockerCompatibleRuntime.listContainers()
    }

    public func createContainer(configuration: OracleContainerConfiguration) async throws {
        try await dockerCompatibleRuntime.createContainer(configuration: configuration)
    }

    public func startContainer(named name: String) async throws {
        try await dockerCompatibleRuntime.startContainer(named: name)
    }

    public func stopContainer(named name: String) async throws {
        try await dockerCompatibleRuntime.stopContainer(named: name)
    }

    public func deleteContainer(named name: String) async throws {
        try await dockerCompatibleRuntime.deleteContainer(named: name)
    }

    public func deleteVolume(named name: String) async throws {
        try await dockerCompatibleRuntime.deleteVolume(named: name)
    }

    public func containerLogs(named name: String) async throws -> String {
        try await dockerCompatibleRuntime.containerLogs(named: name)
    }
}
