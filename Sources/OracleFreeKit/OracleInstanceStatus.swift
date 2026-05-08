public enum OracleInstanceStatus: Equatable, Sendable {
    case missing
    case creating
    case stopped(OracleContainerDetails)
    case running(OracleContainerDetails)
    case ready(OracleContainerDetails)
    case failed(message: String)

    public var containerStateMessage: String? {
        switch self {
        case .stopped:
            return "Oracle Database Free is stopped"
        case .ready:
            return "Oracle Database Free is ready"
        case .missing, .creating, .running, .failed:
            return nil
        }
    }
}
