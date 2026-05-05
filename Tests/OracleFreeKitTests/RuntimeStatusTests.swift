import Testing
@testable import OracleFreeKit

@Test func runtimeStatusExposesFailureMessage() {
    let status = RuntimeStatus.failed(message: "Runtime unavailable")

    if case let .failed(message) = status {
        #expect(message == "Runtime unavailable")
    } else {
        Issue.record("Expected failed runtime status")
    }
}

@Test func runtimeStatusExposesLoadingState() {
    let status = RuntimeStatus.loading

    if case .loading = status {
        #expect(Bool(true))
    } else {
        Issue.record("Expected loading runtime status")
    }
}

@Test func runtimeStatusExposesRuntimeAvailabilityState() {
    let status = RuntimeStatus.runtimeAvailability(.oneRuntimeAvailable(.podman))

    if case let .runtimeAvailability(availability) = status {
        #expect(availability == .oneRuntimeAvailable(.podman))
    } else {
        Issue.record("Expected runtime availability status")
    }
}
