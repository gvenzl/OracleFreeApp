public enum OracleInstanceStatus: Equatable, Sendable {
    case missing
    case creating
    case stopped(OracleContainerDetails)
    case running(OracleContainerDetails)
    case ready(OracleContainerDetails)
    case failed(message: String)
}
