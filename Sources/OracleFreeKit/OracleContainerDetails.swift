public struct OracleContainerDetails: Equatable, Sendable {
    public let containerName: String
    public let image: String
    public let hostPort: Int
    public let databasePort: Int
    public let volumeName: String
    public let state: String
    public let status: String
    public let connectionInfo: OracleConnectionInfo

    public init(
        containerName: String,
        image: String,
        hostPort: Int,
        databasePort: Int,
        volumeName: String,
        state: String,
        status: String,
        connectionInfo: OracleConnectionInfo
    ) {
        self.containerName = containerName
        self.image = image
        self.hostPort = hostPort
        self.databasePort = databasePort
        self.volumeName = volumeName
        self.state = state
        self.status = status
        self.connectionInfo = connectionInfo
    }

    public static let `default` = OracleContainerDetails(
        containerName: OracleContainerConfiguration.default.containerName,
        image: OracleContainerConfiguration.default.image,
        hostPort: OracleContainerConfiguration.default.hostPort,
        databasePort: OracleContainerConfiguration.default.databasePort,
        volumeName: OracleContainerConfiguration.default.volumeName,
        state: "running",
        status: "healthy",
        connectionInfo: .default
    )
}
