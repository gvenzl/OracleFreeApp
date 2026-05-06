public protocol ContainerRuntimeFactory: Sendable {
    func makeRuntime(for kind: ContainerRuntimeKind) -> any ContainerRuntime
}

public struct DefaultContainerRuntimeFactory: ContainerRuntimeFactory {
    public init() {}

    public func makeRuntime(for kind: ContainerRuntimeKind) -> any ContainerRuntime {
        switch kind {
        case .podman:
            return PodmanCommandRuntime()
        case .docker:
            return DockerCommandRuntime()
        }
    }
}
