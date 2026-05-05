public struct PodmanMachine: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let isRunning: Bool
    public let isDefault: Bool
    public let connectionName: String

    public init(
        id: String,
        name: String,
        isRunning: Bool,
        isDefault: Bool,
        connectionName: String
    ) {
        self.id = id
        self.name = name
        self.isRunning = isRunning
        self.isDefault = isDefault
        self.connectionName = connectionName
    }
}
