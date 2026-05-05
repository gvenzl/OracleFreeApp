public protocol ContainerRuntimeDetector: Sendable {
    func detectInstalledRuntimes() async throws -> ContainerRuntimeInstallationStatus
}
