import Foundation

public struct DockerCommandRuntime: ContainerRuntime {
    private let commandRunner: @Sendable ([String]) async throws -> Data

    public init(commandRunner: @escaping @Sendable ([String]) async throws -> Data = Self.runDockerCommand) {
        self.commandRunner = commandRunner
    }

    public func listContainers() async throws -> [ContainerSummary] {
        let data = try await commandRunner(["ps", "--all", "--format", "json"])
        let output = String(decoding: data, as: UTF8.self)
        let records = try output
            .split(whereSeparator: \.isNewline)
            .map { line in
                try JSONDecoder().decode(DockerContainerRecord.self, from: Data(line.utf8))
            }

        return records.map {
            ContainerSummary(
                id: $0.id,
                name: $0.names,
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
            "--publish", "\(configuration.hostPort):\(configuration.databasePort)",
            "--volume", "\(configuration.volumeName):/opt/oracle/oradata",
            "--health-cmd", configuration.healthCheck.command,
            "--health-interval", configuration.healthCheck.interval,
            "--health-timeout", configuration.healthCheck.timeout,
            "--health-retries", "\(configuration.healthCheck.retries)"
        ]

        for environmentVariable in configuration.environmentVariables {
            arguments += ["--env", environmentVariable.assignment]
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

    public static func runDockerCommand(arguments: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["docker"] + arguments
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                guard process.terminationStatus == 0 else {
                    let message = String(decoding: errorData, as: UTF8.self)
                    continuation.resume(throwing: DockerCommandRuntimeError.commandFailed(message: message.trimmingCharacters(in: .whitespacesAndNewlines)))
                    return
                }

                continuation.resume(returning: outputData)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: DockerCommandRuntimeError.commandFailed(message: error.localizedDescription))
            }
        }
    }
}

private struct DockerContainerRecord: Decodable {
    let id: String
    let names: String
    let image: String
    let state: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case names = "Names"
        case image = "Image"
        case state = "State"
        case status = "Status"
    }
}

private enum DockerCommandRuntimeError: LocalizedError {
    case commandFailed(message: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(message) where !message.isEmpty:
            return message
        case .commandFailed:
            return "Unable to run Docker command"
        }
    }
}
