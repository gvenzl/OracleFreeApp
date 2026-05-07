import Testing
@testable import OracleFreeKit

struct ContainerRuntimeKindTests {
    @Test func runtimeKindsDefineUserFacingNamesAndSelectionOrder() {
        #expect(ContainerRuntimeKind.allCases == [.docker, .podman, .rancherDesktop])
        #expect(ContainerRuntimeKind.docker.displayName == "Docker")
        #expect(ContainerRuntimeKind.podman.displayName == "Podman")
        #expect(ContainerRuntimeKind.rancherDesktop.displayName == "Rancher Desktop")
        #expect(ContainerRuntimeKind.docker.requiredExecutableNames == ["docker"])
        #expect(ContainerRuntimeKind.podman.requiredExecutableNames == ["podman"])
        #expect(ContainerRuntimeKind.rancherDesktop.requiredExecutableNames == ["rdctl", "nerdctl"])
    }
}
