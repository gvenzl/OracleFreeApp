public struct ContainerRuntimeSelection: Equatable, Sendable {
    public let runtime: ContainerRuntimeKind

    public init(runtime: ContainerRuntimeKind) {
        self.runtime = runtime
    }
}
