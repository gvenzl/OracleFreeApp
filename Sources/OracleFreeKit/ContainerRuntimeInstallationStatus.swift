public enum ContainerRuntimeInstallationStatus: Equatable, Sendable {
    case noSupportedRuntimeInstalled
    case oneRuntimeAvailable(
        ContainerRuntimeKind,
        executablePaths: ContainerRuntimeExecutablePaths = .empty
    )
    case multipleRuntimesAvailable(
        [ContainerRuntimeKind],
        executablePathsByRuntime: [ContainerRuntimeKind: ContainerRuntimeExecutablePaths] = [:]
    )

    public func executablePaths(for runtime: ContainerRuntimeKind) -> ContainerRuntimeExecutablePaths? {
        switch self {
        case .noSupportedRuntimeInstalled:
            return nil
        case let .oneRuntimeAvailable(availableRuntime, executablePaths):
            return availableRuntime == runtime ? executablePaths : nil
        case let .multipleRuntimesAvailable(_, executablePathsByRuntime):
            return executablePathsByRuntime[runtime]
        }
    }
}
