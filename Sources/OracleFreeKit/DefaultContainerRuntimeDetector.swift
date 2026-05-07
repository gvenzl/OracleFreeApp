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
        let installedRuntimes = ContainerRuntimeKind.allCases.filter { runtime in
            runtime.requiredExecutableNames.allSatisfy { executableName in
                lookupExecutableNamed(executableName) != nil
            }
        }

        switch installedRuntimes.count {
        case 0:
            return .noSupportedRuntimeInstalled
        case 1:
            return .oneRuntimeAvailable(installedRuntimes[0])
        default:
            return .multipleRuntimesAvailable(installedRuntimes)
        }
    }

    static func defaultLookupExecutable(named executableName: String) -> String? {
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
