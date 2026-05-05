import Foundation
import Observation

@MainActor
@Observable
public final class OracleInstanceViewModel {
    public private(set) var status: OracleInstanceStatus

    private let service: any OracleInstanceServicing

    public init(service: any OracleInstanceServicing) {
        self.service = service
        self.status = .missing
    }

    public func loadStatus() async {
        await refreshStatus(after: nil)
    }

    public func createInstance() async {
        status = .creating
        await refreshStatus(after: service.createInstance)
    }

    public func startInstance() async {
        await refreshStatus(after: service.startInstance)
    }

    public func stopInstance() async {
        await refreshStatus(after: service.stopInstance)
    }

    public func deleteInstance() async {
        await refreshStatus(after: service.deleteInstance)
    }

    private func refreshStatus(after action: (() async throws -> Void)?) async {
        do {
            if let action {
                try await action()
            }
            status = try await service.inspectInstance()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = .failed(message: message)
        }
    }
}
