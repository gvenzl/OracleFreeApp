import Foundation

public struct DefaultContainerRuntimeDetector: ContainerRuntimeDetector {
    private let lookupExecutable: @Sendable (ContainerRuntimeKind) -> String?

    public init() {
        self.lookupExecutable = Self.defaultLookupExecutable
    }

    public init(lookupExecutable: @escaping @Sendable (ContainerRuntimeKind) -> String?) {
        self.lookupExecutable = lookupExecutable
    }

    public func detectInstalledRuntimes() async throws -> ContainerRuntimeInstallationStatus {
        let installedRuntimes = ContainerRuntimeKind.allCases.filter { runtime in
            lookupExecutable(runtime) != nil
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

    static func defaultLookupExecutable(_ runtime: ContainerRuntimeKind) -> String? {
        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [runtime.rawValue]
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
