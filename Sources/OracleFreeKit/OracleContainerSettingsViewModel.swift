import Foundation
import Observation

@MainActor
@Observable
public final class OracleContainerSettingsViewModel {
    public private(set) var settings: OracleContainerSettings
    public private(set) var warningMessage: String?

    private let store: OracleContainerSettingsStore

    public init(store: OracleContainerSettingsStore = OracleContainerSettingsStore()) {
        self.store = store

        do {
            self.settings = try store.loadSettings()
            self.warningMessage = nil
        } catch {
            self.settings = .default
            self.warningMessage = Self.warningMessage(
                prefix: "Unable to load container configuration. Defaults are being used.",
                error: error
            )
        }
    }

    public func updateSettings(_ settings: OracleContainerSettings) {
        self.settings = settings

        do {
            try store.save(settings: settings)
            warningMessage = nil
        } catch {
            warningMessage = Self.warningMessage(
                prefix: "Unable to save container configuration. Changes may not persist after restart.",
                error: error
            )
        }
    }

    public func clearWarning() {
        warningMessage = nil
    }

    private static func warningMessage(prefix: String, error: Error) -> String {
        let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return "\(prefix) \(errorMessage)"
    }
}
