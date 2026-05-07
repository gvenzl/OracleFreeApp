import Testing
@testable import OracleFreeKit

struct ContainerRuntimeDetectorTests {
    @Test func detectorReportsNoSupportedRuntimeInstalled() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutableNamed: { _ in nil }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .noSupportedRuntimeInstalled)
    }

    @Test func detectorReportsOneInstalledRuntime() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutableNamed: { executableName in
                executableName == "podman" ? "/opt/homebrew/bin/podman" : nil
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .oneRuntimeAvailable(.podman))
    }

    @Test func detectorReportsMultipleInstalledRuntimes() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutableNamed: { executableName in
                switch executableName {
                case "docker":
                    "/Applications/Docker.app/Contents/Resources/bin/docker"
                case "podman":
                    "/opt/homebrew/bin/podman"
                case "rdctl":
                    "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/rdctl"
                case "nerdctl":
                    "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
                default:
                    nil
                }
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .multipleRuntimesAvailable([.docker, .podman, .rancherDesktop]))
    }

    @Test func detectorReportsRancherDesktopWhenRancherDesktopCommandsAreInstalled() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutableNamed: { executableName in
                switch executableName {
                case "rdctl":
                    "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/rdctl"
                case "nerdctl":
                    "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
                default:
                    nil
                }
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .oneRuntimeAvailable(.rancherDesktop))
    }

    @Test func detectorDoesNotReportRancherDesktopWhenNerdctlIsMissing() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutableNamed: { executableName in
                executableName == "rdctl" ? "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/rdctl" : nil
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .noSupportedRuntimeInstalled)
    }
}
