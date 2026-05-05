public enum OracleInstanceStatus: Equatable, Sendable {
    case missing
    case creating
    case stopped
    case running
    case ready(OracleConnectionInfo)
    case failed(message: String)
}
