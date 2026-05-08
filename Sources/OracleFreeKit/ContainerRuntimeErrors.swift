import Foundation

enum ContainerRuntimeOperation: Equatable, Sendable {
    case listContainers
    case createContainer
    case startContainer
    case stopContainer
    case deleteContainer
    case deleteVolume
    case containerLogs
    case listMachines
    case startMachine
    case unknown

    init(arguments: [String]) {
        switch arguments.first {
        case "ps":
            self = .listContainers
        case "run":
            self = .createContainer
        case "start":
            self = .startContainer
        case "stop":
            self = .stopContainer
        case "rm":
            self = .deleteContainer
        case "logs":
            self = .containerLogs
        case "machine":
            if arguments.dropFirst().first == "list" {
                self = .listMachines
            } else if arguments.dropFirst().first == "start" {
                self = .startMachine
            } else {
                self = .unknown
            }
        case "volume":
            self = arguments.dropFirst().first == "rm" ? .deleteVolume : .unknown
        default:
            self = .unknown
        }
    }

    var actionDescription: String {
        switch self {
        case .listContainers:
            return "inspect Oracle Database Free containers"
        case .createContainer:
            return "create Oracle Database Free"
        case .startContainer:
            return "start Oracle Database Free"
        case .stopContainer:
            return "stop Oracle Database Free"
        case .deleteContainer:
            return "delete Oracle Database Free"
        case .deleteVolume:
            return "delete Oracle Database Free volume"
        case .containerLogs:
            return "load Oracle Database Free container logs"
        case .listMachines:
            return "load Podman machines"
        case .startMachine:
            return "start Podman machine"
        case .unknown:
            return "run container runtime command"
        }
    }
}

struct ContainerRuntimeCommandFailure: LocalizedError, Equatable, Sendable {
    let runtimeName: String
    let operation: ContainerRuntimeOperation
    let message: String

    var errorDescription: String? {
        if isMissingRuntimeCommand {
            return "Unable to find \(runtimeName)'s command line tool. Install \(runtimeName) or choose another container runtime."
        }

        if isRuntimeConnectionFailure {
            return "Unable to connect to \(runtimeName). Make sure \(runtimeName) is running, then try again."
        }

        if operation == .createContainer, isPortConflict {
            return "Port conflict while creating Oracle Database Free. Another process or container is already using the configured host port. Change the host port in Configuration or stop the process using it."
        }

        if operation == .createContainer, isImagePullFailure {
            return "Unable to pull the Oracle Database Free container image. Check the configured image name and your network access."
        }

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            return "Unable to \(operation.actionDescription) with \(runtimeName)."
        }

        return "Unable to \(operation.actionDescription) with \(runtimeName). Details: \(trimmedMessage)"
    }

    private var normalizedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isMissingRuntimeCommand: Bool {
        normalizedMessage.contains("no such file or directory")
            || normalizedMessage.contains("command not found")
            || normalizedMessage.contains("executable file not found")
    }

    private var isRuntimeConnectionFailure: Bool {
        normalizedMessage.contains("cannot connect")
            || normalizedMessage.contains("can't connect")
            || normalizedMessage.contains("connection refused")
            || normalizedMessage.contains("is the docker daemon running")
            || normalizedMessage.contains("podman machine")
            || normalizedMessage.contains("docker daemon is not running")
    }

    private var isPortConflict: Bool {
        normalizedMessage.contains("address already in use")
            || normalizedMessage.contains("port is already allocated")
            || normalizedMessage.contains("port is already in use")
    }

    private var isImagePullFailure: Bool {
        normalizedMessage.contains("pull access denied")
            || normalizedMessage.contains("manifest unknown")
            || normalizedMessage.contains("requested image not found")
            || normalizedMessage.contains("repository does not exist")
            || normalizedMessage.contains("failed to resolve reference")
            || normalizedMessage.contains("unable to find image")
    }
}

enum ContainerRuntimeDataError: LocalizedError, Equatable, Sendable {
    case invalidRuntimeJSON(context: String)

    var errorDescription: String? {
        switch self {
        case let .invalidRuntimeJSON(context):
            return "Unable to read \(context). The runtime returned invalid JSON."
        }
    }
}
