public struct ContainerSummary: Equatable, Sendable {
    public let id: String
    public let name: String
    public let image: String
    public let state: String
    public let status: String

    public init(id: String, name: String, image: String, state: String, status: String) {
        self.id = id
        self.name = name
        self.image = image
        self.state = state
        self.status = status
    }
}
