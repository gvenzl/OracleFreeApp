public protocol PodmanRuntime: ContainerRuntime, Sendable {
    func discoverMachines() async throws -> [PodmanMachine]
    func startMachine(named name: String) async throws
}
