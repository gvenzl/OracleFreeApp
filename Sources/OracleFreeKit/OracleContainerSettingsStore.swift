import Foundation

public struct OracleContainerSettingsStore: Sendable {
    public let settingsFileURL: URL

    public init(settingsFileURL: URL = Self.defaultSettingsFileURL()) {
        self.settingsFileURL = settingsFileURL
    }

    public func loadSettings() throws -> OracleContainerSettings {
        guard FileManager.default.fileExists(atPath: settingsFileURL.path) else {
            return .default
        }

        let data = try Data(contentsOf: settingsFileURL)
        return try JSONDecoder().decode(OracleContainerSettings.self, from: data)
    }

    public func save(settings: OracleContainerSettings) throws {
        let directoryURL = settingsFileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: settingsFileURL, options: [.atomic])
    }

    public static func defaultSettingsFileURL() -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)

        return applicationSupportURL
            .appendingPathComponent(OracleFreeAppMetadata.displayName, isDirectory: true)
            .appendingPathComponent("container-settings.json", isDirectory: false)
    }
}
