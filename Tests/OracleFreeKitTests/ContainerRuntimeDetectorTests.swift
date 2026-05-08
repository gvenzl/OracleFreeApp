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

        #expect(status == .oneRuntimeAvailable(
            .podman,
            executablePaths: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                "podman": "/opt/homebrew/bin/podman"
            ])
        ))
    }

    @Test func detectorIncludesResolvedExecutablePathsForAvailableRuntimes() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutableNamed: { executableName in
                executableName == "podman" ? "/opt/homebrew/bin/podman" : nil
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status.executablePaths(for: .podman)?.path(for: "podman") == "/opt/homebrew/bin/podman")
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

        #expect(status == .multipleRuntimesAvailable(
            [.docker, .podman, .rancherDesktop],
            executablePathsByRuntime: [
                .docker: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                    "docker": "/Applications/Docker.app/Contents/Resources/bin/docker"
                ]),
                .podman: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                    "podman": "/opt/homebrew/bin/podman"
                ]),
                .rancherDesktop: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                    "rdctl": "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/rdctl",
                    "nerdctl": "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
                ])
            ]
        ))
        #expect(
            status.executablePaths(for: .rancherDesktop)?.path(for: "nerdctl") ==
                "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
        )
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

        #expect(status == .oneRuntimeAvailable(
            .rancherDesktop,
            executablePaths: ContainerRuntimeExecutablePaths(pathsByExecutableName: [
                "rdctl": "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/rdctl",
                "nerdctl": "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
            ])
        ))
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

    @Test func defaultLookupSearchesCommonMacOSInstallLocations() {
        #expect(DefaultContainerRuntimeDetector.candidateExecutablePaths(named: "podman").contains("/opt/homebrew/bin/podman"))
        #expect(DefaultContainerRuntimeDetector.candidateExecutablePaths(named: "docker").contains("/Applications/Docker.app/Contents/Resources/bin/docker"))
        #expect(
            DefaultContainerRuntimeDetector.candidateExecutablePaths(named: "nerdctl").contains(
                "/Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/bin/nerdctl"
            )
        )
    }
}
