public protocol ContainerRuntimeFactory: Sendable {
    func makeRuntime(for kind: ContainerRuntimeKind) -> any ContainerRuntime
}

public struct DefaultContainerRuntimeFactory: ContainerRuntimeFactory {
    public init() {}

    public func makeRuntime(for kind: ContainerRuntimeKind) -> any ContainerRuntime {
        switch kind {
        case .docker:
            return DockerCommandRuntime()
        case .podman:
            return PodmanCommandRuntime()
        case .rancherDesktop:
            return RancherDesktopCommandRuntime()
        }
    }
}
