import Foundation

public struct DefaultContainerRuntimeDetector: ContainerRuntimeDetector {
    private let lookupExecutableNamed: @Sendable (String) -> String?

    public init() {
        self.lookupExecutableNamed = Self.defaultLookupExecutable(named:)
    }

    public init(lookupExecutableNamed: @escaping @Sendable (String) -> String?) {
        self.lookupExecutableNamed = lookupExecutableNamed
    }

    public func detectInstalledRuntimes() async throws -> ContainerRuntimeInstallationStatus {
        var executablePathsByRuntime: [ContainerRuntimeKind: ContainerRuntimeExecutablePaths] = [:]
        let installedRuntimes = ContainerRuntimeKind.allCases.compactMap { runtime -> ContainerRuntimeKind? in
            var pathsByExecutableName: [String: String] = [:]

            for executableName in runtime.requiredExecutableNames {
                guard let path = lookupExecutableNamed(executableName) else {
                    return nil
                }

                pathsByExecutableName[executableName] = path
            }

            executablePathsByRuntime[runtime] = ContainerRuntimeExecutablePaths(
                pathsByExecutableName: pathsByExecutableName
            )
            return runtime
        }

        switch installedRuntimes.count {
        case 0:
            return .noSupportedRuntimeInstalled
        case 1:
            let runtime = installedRuntimes[0]
            return .oneRuntimeAvailable(
                runtime,
                executablePaths: executablePathsByRuntime[runtime] ?? .empty
            )
        default:
            return .multipleRuntimesAvailable(
                installedRuntimes,
                executablePathsByRuntime: executablePathsByRuntime
            )
        }
    }

    static func defaultLookupExecutable(named executableName: String) -> String? {
        let fileManager = FileManager.default
        if let candidatePath = candidateExecutablePaths(named: executableName).first(where: {
            fileManager.isExecutableFile(atPath: $0)
        }) {
            return candidatePath
        }

        return lookupExecutableOnCurrentPath(named: executableName)
    }

    static func candidateExecutablePaths(named executableName: String) -> [String] {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        var candidates: [String] = []

        func append(_ path: String) {
            if !candidates.contains(path) {
                candidates.append(path)
            }
        }

        switch executableName {
        case "docker":
            append("/Applications/Docker.app/Contents/Resources/bin/docker")
        case "rdctl":
            append("/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/rdctl")
            append("\(homeDirectory)/.rd/bin/rdctl")
        case "nerdctl":
            append("/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl")
            append("\(homeDirectory)/.rd/bin/nerdctl")
        default:
            break
        }

        for directory in [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ] {
            append("\(directory)/\(executableName)")
        }

        return candidates
    }

    private static func lookupExecutableOnCurrentPath(named executableName: String) -> String? {
        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [executableName]
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }
}
