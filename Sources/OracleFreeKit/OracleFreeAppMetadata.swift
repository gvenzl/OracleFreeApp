import Foundation

public enum OracleFreeAppMetadata {
    public static let displayName = "Oracle Free App"
    public static let author = "Gerald Venzl"
    public static let version = OracleFreeAppVersion.current
}

private enum OracleFreeAppVersion {
    static var current: String {
        if let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !bundleVersion.isEmpty {
            return bundleVersion
        }

        if let fileVersion = readRootVersionFile() {
            return fileVersion
        }

        return "unknown"
    }

    private static func readRootVersionFile() -> String? {
        var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        while true {
            let versionFile = directory.appendingPathComponent("VERSION")
            if let version = try? String(contentsOf: versionFile, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !version.isEmpty {
                return version
            }

            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else {
                return nil
            }

            directory = parent
        }
    }
}
