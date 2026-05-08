import Testing
@testable import OracleFreeKit

struct ContainerRuntimeFactoryTests {
    @Test func defaultFactoryCreatesPodmanRuntimeForPodmanSelection() {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(for: .podman)

        #expect(runtime is PodmanCommandRuntime)
    }

    @Test func defaultFactoryUsesResolvedPodmanExecutablePath() throws {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(
            for: .podman,
            executablePaths: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                "podman": "/opt/homebrew/bin/podman"
            ])
        )

        let podmanRuntime = try #require(runtime as? PodmanCommandRuntime)
        #expect(podmanRuntime.commandPath == "/opt/homebrew/bin/podman")
    }

    @Test func defaultFactoryCreatesDockerRuntimeForDockerSelection() {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(for: .docker)

        #expect(runtime is DockerCommandRuntime)
    }

    @Test func defaultFactoryUsesResolvedDockerExecutablePath() throws {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(
            for: .docker,
            executablePaths: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                "docker": "/Applications/Docker.app/Contents/Resources/bin/docker"
            ])
        )

        let dockerRuntime = try #require(runtime as? DockerCommandRuntime)
        #expect(dockerRuntime.commandPath == "/Applications/Docker.app/Contents/Resources/bin/docker")
    }

    @Test func defaultFactoryCreatesRancherDesktopRuntimeForRancherSelection() {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(for: .rancherDesktop)

        #expect(runtime is RancherDesktopCommandRuntime)
    }

    @Test func defaultFactoryUsesResolvedRancherDesktopExecutablePath() throws {
        let factory = DefaultContainerRuntimeFactory()

        let runtime = factory.makeRuntime(
            for: .rancherDesktop,
            executablePaths: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                "nerdctl": "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
            ])
        )

        let rancherRuntime = try #require(runtime as? RancherDesktopCommandRuntime)
        #expect(rancherRuntime.commandPath == "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl")
    }
}
