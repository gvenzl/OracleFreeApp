import Foundation

public struct DockerCommandRuntime: ContainerRuntime {
    private let commandRunner: @Sendable ([String]) async throws -> Data

    public init(commandName: String = "docker", runtimeName: String = "Docker") {
        self.commandRunner = { arguments in
            try await Self.runCommand(commandName: commandName, runtimeName: runtimeName, arguments: arguments)
        }
    }

    public init(commandRunner: @escaping @Sendable ([String]) async throws -> Data) {
        self.commandRunner = commandRunner
    }

    public func listContainers() async throws -> [ContainerSummary] {
        let data = try await commandRunner(["ps", "--all", "--format", "json"])
        let output = String(decoding: data, as: UTF8.self)
        let records: [DockerContainerRecord]

        do {
            records = try output
                .split(whereSeparator: \.isNewline)
                .map { line in
                    try JSONDecoder().decode(DockerContainerRecord.self, from: Data(line.utf8))
                }
        } catch {
            throw ContainerRuntimeDataError.invalidRuntimeJSON(context: "Docker container list")
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

    public static func runDockerCommand(arguments: [String]) async throws -> Data {
        try await runCommand(commandName: "docker", runtimeName: "Docker", arguments: arguments)
    }

    public static func runCommand(
        commandName: String,
        runtimeName: String = "Docker",
        arguments: [String]
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [commandName] + arguments
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                guard process.terminationStatus == 0 else {
                    let message = String(decoding: errorData, as: UTF8.self)
                    continuation.resume(throwing: ContainerRuntimeCommandFailure(
                        runtimeName: runtimeName,
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
                    runtimeName: runtimeName,
                    operation: ContainerRuntimeOperation(arguments: arguments),
                    message: error.localizedDescription
                ))
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
