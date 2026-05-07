import Testing
@testable import OracleFreeKit

struct ContainerRuntimeFactoryTests {
    @Test func defaultFactoryCreatesPodmanRuntimeForPodmanSelection() {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(for: .podman)

        #expect(runtime is PodmanCommandRuntime)
    }

    @Test func defaultFactoryCreatesDockerRuntimeForDockerSelection() {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(for: .docker)

        #expect(runtime is DockerCommandRuntime)
    }

    @Test func defaultFactoryCreatesRancherDesktopRuntimeForRancherSelection() {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(for: .rancherDesktop)

        #expect(runtime is RancherDesktopCommandRuntime)
    }
}
