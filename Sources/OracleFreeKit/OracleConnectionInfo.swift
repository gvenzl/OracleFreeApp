public struct OracleConnectionInfo: Equatable, Sendable {
    public let host: String
    public let port: Int
    public let serviceName: String
    public let username: String
    public let password: String

    public init(host: String, port: Int, serviceName: String, username: String, password: String) {
        self.host = host
        self.port = port
        self.serviceName = serviceName
        self.username = username
        self.password = password
    }

    public static let `default` = OracleConnectionInfo(
        host: "localhost",
        port: 1521,
        serviceName: "FREEPDB1",
        username: "system",
        password: "OracleFree123"
    )
}
