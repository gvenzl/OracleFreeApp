public struct OracleContainerSettings: Codable, Equatable, Sendable {
    public var image: String
    public var containerName: String
    public var hostPort: Int
    public var volumeName: String
    public var password: String
    private var normalizedExtraEnvironmentVariables: [ContainerEnvironmentVariable]
    public var extraEnvironmentVariables: [ContainerEnvironmentVariable] {
        get {
            normalizedExtraEnvironmentVariables
        }
        set {
            normalizedExtraEnvironmentVariables = Self.normalizedExtraEnvironmentVariables(newValue)
        }
    }

    public init(
        image: String,
        containerName: String,
        hostPort: Int,
        volumeName: String,
        password: String,
        extraEnvironmentVariables: [ContainerEnvironmentVariable]
    ) {
        self.image = image
        self.containerName = containerName
        self.hostPort = hostPort
        self.volumeName = volumeName
        self.password = password
        self.normalizedExtraEnvironmentVariables = Self.normalizedExtraEnvironmentVariables(extraEnvironmentVariables)
    }

    enum CodingKeys: String, CodingKey {
        case image
        case containerName
        case hostPort
        case volumeName
        case password
        case extraEnvironmentVariables
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            image: try container.decode(String.self, forKey: .image),
            containerName: try container.decode(String.self, forKey: .containerName),
            hostPort: try container.decode(Int.self, forKey: .hostPort),
            volumeName: try container.decode(String.self, forKey: .volumeName),
            password: try container.decode(String.self, forKey: .password),
            extraEnvironmentVariables: try container.decode(
                [ContainerEnvironmentVariable].self,
                forKey: .extraEnvironmentVariables
            )
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image, forKey: .image)
        try container.encode(containerName, forKey: .containerName)
        try container.encode(hostPort, forKey: .hostPort)
        try container.encode(volumeName, forKey: .volumeName)
        try container.encode(password, forKey: .password)
        try container.encode(extraEnvironmentVariables, forKey: .extraEnvironmentVariables)
    }

    public static let `default` = OracleContainerSettings(
        image: "ghcr.io/gvenzl/oracle-free",
        containerName: "oracle-free",
        hostPort: 1521,
        volumeName: "oracle-free-data",
        password: "OracleFree123",
        extraEnvironmentVariables: []
    )

    public func containerConfiguration() -> OracleContainerConfiguration {
        OracleContainerConfiguration(
            containerName: containerName,
            image: image,
            databasePort: 1521,
            hostPort: hostPort,
            volumeName: volumeName,
            healthCheck: ContainerHealthCheckConfiguration(
                command: "healthcheck.sh",
                interval: "10s",
                timeout: "5s",
                retries: 10
            ),
            environmentVariables: environmentVariables
        )
    }

    public static func extraEnvironmentVariables(from text: String) -> [ContainerEnvironmentVariable] {
        text.split(whereSeparator: \.isNewline).compactMap { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmedLine.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)

            guard parts.count == 2 else {
                return nil
            }

            let name = Self.normalizedEnvironmentVariableName(parts[0])
            guard !name.isEmpty else {
                return nil
            }

            return ContainerEnvironmentVariable(
                name: name,
                value: parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    public static func extraEnvironmentVariablesText(from variables: [ContainerEnvironmentVariable]) -> String {
        variables.map(\.assignment).joined(separator: "\n")
    }

    private var environmentVariables: [ContainerEnvironmentVariable] {
        [
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: password)
        ] + extraEnvironmentVariables.compactMap { variable in
            let name = Self.normalizedEnvironmentVariableName(variable.name)
            guard !name.isEmpty, name != "ORACLE_PASSWORD" else {
                return nil
            }

            return ContainerEnvironmentVariable(
                name: name,
                value: variable.value.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    private static func normalizedExtraEnvironmentVariables(
        _ variables: [ContainerEnvironmentVariable]
    ) -> [ContainerEnvironmentVariable] {
        variables.map { variable in
            ContainerEnvironmentVariable(
                name: normalizedEnvironmentVariableName(variable.name),
                value: variable.value
            )
        }
    }

    private static func normalizedEnvironmentVariableName(_ name: some StringProtocol) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
