public protocol ContainerRuntimeFactory: Sendable {
    func makeRuntime(
        for kind: ContainerRuntimeKind,
        executablePaths: ContainerRuntimeExecutablePaths
    ) -> any ContainerRuntime
}

public extension ContainerRuntimeFactory {
    func makeRuntime(for kind: ContainerRuntimeKind) -> any ContainerRuntime {
        makeRuntime(for: kind, executablePaths: .empty)
    }
}

public struct DefaultContainerRuntimeFactory: ContainerRuntimeFactory {
    public init() {}

    public func makeRuntime(
        for kind: ContainerRuntimeKind,
        executablePaths: ContainerRuntimeExecutablePaths = .empty
    ) -> any ContainerRuntime {
        switch kind {
        case .docker:
            return DockerCommandRuntime(
                commandPath: executablePaths.path(for: "docker") ?? "docker"
            )
        case .podman:
            return PodmanCommandRuntime(
                commandPath: executablePaths.path(for: "podman") ?? "podman"
            )
        case .rancherDesktop:
            return RancherDesktopCommandRuntime(
                commandPath: executablePaths.path(for: "nerdctl") ?? "nerdctl"
            )
        }
    }
}
