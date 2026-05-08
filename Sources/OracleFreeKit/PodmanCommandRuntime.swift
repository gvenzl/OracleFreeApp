import Foundation

public struct PodmanCommandRuntime: PodmanRuntime {
    public let commandPath: String

    private let commandRunner: @Sendable ([String]) async throws -> Data

    public init(commandPath: String = "podman") {
        self.commandPath = commandPath
        self.commandRunner = { arguments in
            try await Self.runPodmanCommand(commandPath: commandPath, arguments: arguments)
        }
    }

    public init(commandRunner: @escaping @Sendable ([String]) async throws -> Data) {
        self.commandPath = "<custom>"
        self.commandRunner = commandRunner
    }

    public func discoverMachines() async throws -> [PodmanMachine] {
        let data = try await commandRunner(["machine", "list", "--format", "json"])
        let machines: [PodmanMachineRecord]

        do {
            machines = try JSONDecoder().decode([PodmanMachineRecord].self, from: data)
        } catch {
            throw ContainerRuntimeDataError.invalidRuntimeJSON(context: "Podman machine list")
        }

        return machines.map {
            PodmanMachine(
                id: $0.name,
                name: $0.name,
                isRunning: $0.running,
                isDefault: $0.defaultMachine,
                connectionName: $0.connectionName ?? $0.name
            )
        }
    }

    public func startMachine(named name: String) async throws {
        _ = try await commandRunner(["machine", "start", name])
    }

    public func listContainers() async throws -> [ContainerSummary] {
        let data = try await commandRunner(["ps", "--all", "--format", "json"])
        let containers: [PodmanContainerRecord]

        do {
            containers = try JSONDecoder().decode([PodmanContainerRecord].self, from: data)
        } catch {
            throw ContainerRuntimeDataError.invalidRuntimeJSON(context: "Podman container list")
        }

        return containers.map {
            ContainerSummary(
                id: $0.id,
                name: $0.names.first ?? $0.id,
                image: $0.image,
                state: $0.state,
                status: $0.status
            )
        }
    }

    public func createContainer(configuration: OracleContainerConfiguration) async throws {
        var arguments = [
            "run",
            "--detach",
            "--name", configuration.containerName,
            "--publish", "\(configuration.hostPort):\(configuration.databasePort)"
        ]

        let volumeName = configuration.volumeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !volumeName.isEmpty {
            arguments += ["--volume", "\(volumeName):/opt/oracle/oradata"]
        }

        arguments += [
            "--health-cmd", configuration.healthCheck.command,
            "--health-interval", configuration.healthCheck.interval,
            "--health-timeout", configuration.healthCheck.timeout,
            "--health-retries", "\(configuration.healthCheck.retries)"
        ]

        for environmentVariable in configuration.environmentVariables {
            arguments += ["-e", environmentVariable.assignment]
        }

        arguments.append(configuration.image)

        _ = try await commandRunner(arguments)
    }

    public func startContainer(named name: String) async throws {
        _ = try await commandRunner(["start", name])
    }

    public func stopContainer(named name: String) async throws {
        _ = try await commandRunner(["stop", name])
    }

    public func deleteContainer(named name: String) async throws {
        _ = try await commandRunner(["rm", "--force", name])
    }

    public func deleteVolume(named name: String) async throws {
        _ = try await commandRunner(["volume", "rm", "--force", name])
    }

    public func containerLogs(named name: String) async throws -> String {
        let data = try await commandRunner(["logs", "--tail", "120", name])
        return String(decoding: data, as: UTF8.self)
    }

    public static func runPodmanCommand(arguments: [String]) async throws -> Data {
        try await runPodmanCommand(commandPath: "podman", arguments: arguments)
    }

    public static func runPodmanCommand(commandPath: String, arguments: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            if commandPath.hasPrefix("/") {
                process.executableURL = URL(fileURLWithPath: commandPath)
                process.arguments = arguments
            } else {
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = [commandPath] + arguments
            }
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                guard process.terminationStatus == 0 else {
                    let message = String(decoding: errorData, as: UTF8.self)
                    continuation.resume(throwing: ContainerRuntimeCommandFailure(
                        runtimeName: "Podman",
                        operation: ContainerRuntimeOperation(arguments: arguments),
                        message: message
                    ))
                    return
                }

                continuation.resume(returning: outputData)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ContainerRuntimeCommandFailure(
                    runtimeName: "Podman",
                    operation: ContainerRuntimeOperation(arguments: arguments),
                    message: error.localizedDescription
                ))
            }
        }
    }
}

private struct PodmanMachineRecord: Decodable {
    let name: String
    let running: Bool
    let defaultMachine: Bool
    let connectionName: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case running = "Running"
        case defaultMachine = "Default"
        case connectionName = "ConnectionName"
    }
}

private struct PodmanContainerRecord: Decodable {
    let id: String
    let names: [String]
    let image: String
    let state: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case names = "Names"
        case image = "Image"
        case state = "State"
        case status = "Status"
    }
}
