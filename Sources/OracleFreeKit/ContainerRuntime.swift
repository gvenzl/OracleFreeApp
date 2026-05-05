public protocol ContainerRuntime: Sendable {
    func listContainers() async throws -> [ContainerSummary]
    func createContainer(configuration: OracleContainerConfiguration) async throws
    func startContainer(named name: String) async throws
    func stopContainer(named name: String) async throws
    func deleteContainer(named name: String) async throws
}
