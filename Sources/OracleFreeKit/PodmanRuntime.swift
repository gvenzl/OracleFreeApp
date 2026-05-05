public protocol PodmanRuntime: ContainerRuntime, Sendable {
    func discoverMachines() async throws -> [PodmanMachine]
}
