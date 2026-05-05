public enum ContainerRuntimeInstallationStatus: Equatable, Sendable {
    case noSupportedRuntimeInstalled
    case oneRuntimeAvailable(ContainerRuntimeKind)
    case multipleRuntimesAvailable([ContainerRuntimeKind])
}
