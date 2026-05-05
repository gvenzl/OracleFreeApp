public enum RuntimeStatus: Equatable, Sendable {
    case loading
    case runtimeAvailability(ContainerRuntimeInstallationStatus)
    case failed(message: String)
}
