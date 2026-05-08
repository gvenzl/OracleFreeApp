public enum ContainerRuntimeKind: String, CaseIterable, Equatable, Hashable, Sendable {
    case docker
    case podman
    case rancherDesktop

    public var displayName: String {
        switch self {
        case .docker:
            return "Docker"
        case .podman:
            return "Podman"
        case .rancherDesktop:
            return "Rancher Desktop"
        }
    }

    var requiredExecutableNames: [String] {
        switch self {
        case .docker:
            return ["docker"]
        case .podman:
            return ["podman"]
        case .rancherDesktop:
            return ["rdctl", "nerdctl"]
        }
    }
}
