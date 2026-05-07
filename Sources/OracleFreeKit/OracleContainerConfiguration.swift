public struct OracleContainerConfiguration: Equatable, Sendable {
    public let containerName: String
    public let image: String
    public let databasePort: Int
    public let hostPort: Int
    public let volumeName: String
    public let healthCheck: ContainerHealthCheckConfiguration
    public let environmentVariables: [ContainerEnvironmentVariable]

    public init(
        containerName: String,
        image: String,
        databasePort: Int,
        hostPort: Int,
        volumeName: String,
        healthCheck: ContainerHealthCheckConfiguration,
        environmentVariables: [ContainerEnvironmentVariable]
    ) {
        self.containerName = containerName
        self.image = image
        self.databasePort = databasePort
        self.hostPort = hostPort
        self.volumeName = volumeName
        self.healthCheck = healthCheck
        self.environmentVariables = environmentVariables
    }

    public static let `default` = OracleContainerSettings.default.containerConfiguration()
}
