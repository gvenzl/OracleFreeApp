public struct ContainerEnvironmentVariable: Equatable, Sendable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public var assignment: String {
        "\(name)=\(value)"
    }
}
