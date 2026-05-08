public struct ContainerRuntimeExecutablePaths: Equatable, Sendable {
    public static let empty = ContainerRuntimeExecutablePaths()

    public let pathsByExecutableName: [String: String]

    public init(pathsByExecutableName: [String: String] = [:]) {
        self.pathsByExecutableName = pathsByExecutableName
    }

    public func path(for executableName: String) -> String? {
        pathsByExecutableName[executableName]
    }
}
