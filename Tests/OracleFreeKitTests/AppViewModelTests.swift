import Foundation
import Testing
@testable import OracleFreeKit

@MainActor
struct AppViewModelTests {
    @Test func appViewModelStartsInLoadingState() {
        let viewModel = AppViewModel(runtimeDetector: FakeRuntimeDetector(result: .success(.noSupportedRuntimeInstalled)))

        #expect(viewModel.status == .loading)
    }

    @Test func appViewModelLoadsRuntimeAvailabilityFromDetector() async throws {
        let detector = FakeRuntimeDetector(result: .success(.oneRuntimeAvailable(.podman)))
        let viewModel = AppViewModel(runtimeDetector: detector)

        await viewModel.loadRuntimes()

        #expect(detector.detectionCallCount == 1)
        #expect(viewModel.status == .runtimeAvailability(.oneRuntimeAvailable(.podman)))
    }

    @Test func appViewModelExposesRuntimeDetectionFailureMessage() async throws {
        let viewModel = AppViewModel(
            runtimeDetector: FakeRuntimeDetector(result: .failure(FakeRuntimeError(message: "Unable to detect runtimes")))
        )

        await viewModel.loadRuntimes()

        #expect(viewModel.status == .failed(message: "Unable to detect runtimes"))
    }
}

private struct FakeRuntimeError: Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

private final class FakeRuntimeDetector: ContainerRuntimeDetector, @unchecked Sendable {
    let result: Result<ContainerRuntimeInstallationStatus, Error>
    private(set) var detectionCallCount = 0

    init(result: Result<ContainerRuntimeInstallationStatus, Error>) {
        self.result = result
    }

    func detectInstalledRuntimes() async throws -> ContainerRuntimeInstallationStatus {
        detectionCallCount += 1
        return try result.get()
    }
}
