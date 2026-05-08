import Foundation
import Testing
@testable import OracleFreeKit

@MainActor
struct OracleContainerSettingsViewModelTests {
    @Test func settingsViewModelFallsBackToDefaultsAndReportsLoadFailure() throws {
        let fileURL = temporarySettingsFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: fileURL)

        let viewModel = OracleContainerSettingsViewModel(
            store: OracleContainerSettingsStore(settingsFileURL: fileURL)
        )

        #expect(viewModel.settings == .default)
        #expect(viewModel.warningMessage?.contains("Unable to load container configuration") == true)
    }

    @Test func settingsViewModelReportsSaveFailure() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let viewModel = OracleContainerSettingsViewModel(
            store: OracleContainerSettingsStore(settingsFileURL: directoryURL)
        )

        viewModel.updateSettings(.default)

        #expect(viewModel.settings == .default)
        #expect(viewModel.warningMessage?.contains("Unable to save container configuration") == true)
    }

    @Test func settingsViewModelClearsWarningAfterSuccessfulSave() throws {
        let fileURL = temporarySettingsFileURL()
        let viewModel = OracleContainerSettingsViewModel(
            store: OracleContainerSettingsStore(settingsFileURL: fileURL)
        )

        viewModel.updateSettings(.default)

        #expect(viewModel.warningMessage == nil)
        #expect(try OracleContainerSettingsStore(settingsFileURL: fileURL).loadSettings() == .default)
    }

    private func temporarySettingsFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("container-settings.json")
    }
}
