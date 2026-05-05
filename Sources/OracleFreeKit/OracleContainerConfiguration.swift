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

    public static let `default` = OracleContainerConfiguration(
        containerName: "oracle-free",
        image: "ghcr.io/gvenzl/oracle-free",
        databasePort: 1521,
        hostPort: 1521,
        volumeName: "oracle-free-data",
        healthCheck: ContainerHealthCheckConfiguration(
            command: "healthcheck.sh",
            interval: "10s",
            timeout: "5s",
            retries: 10
        ),
        environmentVariables: [
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "OracleFree123")
        ]
    )
}
