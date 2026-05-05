public struct ContainerHealthCheckConfiguration: Equatable, Sendable {
    public let command: String
    public let interval: String
    public let timeout: String
    public let retries: Int

    public init(command: String, interval: String, timeout: String, retries: Int) {
        self.command = command
        self.interval = interval
        self.timeout = timeout
        self.retries = retries
    }
}
