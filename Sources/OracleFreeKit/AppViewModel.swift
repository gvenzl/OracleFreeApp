import Foundation
import Observation

@MainActor
@Observable
public final class AppViewModel {
    public private(set) var status: RuntimeStatus

    private let runtimeDetector: any ContainerRuntimeDetector

    public init(runtimeDetector: any ContainerRuntimeDetector) {
        self.runtimeDetector = runtimeDetector
        self.status = .loading
    }

    public func loadRuntimes() async {
        do {
            let status = try await runtimeDetector.detectInstalledRuntimes()
            self.status = .runtimeAvailability(status)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = .failed(message: message)
        }
    }
}
