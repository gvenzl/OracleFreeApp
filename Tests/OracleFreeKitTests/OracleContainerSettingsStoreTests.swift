import Foundation
import Testing
@testable import OracleFreeKit

struct OracleContainerSettingsStoreTests {
    @Test func settingsStoreLoadsDefaultsWhenFileDoesNotExist() throws {
        let store = OracleContainerSettingsStore(settingsFileURL: temporarySettingsFileURL())

        let settings = try store.loadSettings()

        #expect(settings == .default)
    }

    @Test func settingsStorePersistsSettingsToJsonFile() throws {
        let fileURL = temporarySettingsFileURL()
        let store = OracleContainerSettingsStore(settingsFileURL: fileURL)
        let settings = OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:slim",
            containerName: "oracle-dev",
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            password: "LocalPassword123",
            extraEnvironmentVariables: [
                ContainerEnvironmentVariable(name: "app_user", value: "demo")
            ]
        )

        try store.save(settings: settings)

        #expect(try store.loadSettings() == OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:slim",
            containerName: "oracle-dev",
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            password: "LocalPassword123",
            extraEnvironmentVariables: [
                ContainerEnvironmentVariable(name: "APP_USER", value: "demo")
            ]
        ))
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    private func temporarySettingsFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("container-settings.json")
    }
}
