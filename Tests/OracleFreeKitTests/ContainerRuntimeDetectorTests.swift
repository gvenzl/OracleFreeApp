import Testing
@testable import OracleFreeKit

struct ContainerRuntimeDetectorTests {
    @Test func detectorReportsNoSupportedRuntimeInstalled() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutable: { _ in nil }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .noSupportedRuntimeInstalled)
    }

    @Test func detectorReportsOneInstalledRuntime() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutable: { runtime in
                switch runtime {
                case .podman:
                    "/opt/homebrew/bin/podman"
                case .docker:
                    nil
                }
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .oneRuntimeAvailable(.podman))
    }

    @Test func detectorReportsMultipleInstalledRuntimes() async throws {
        let detector = DefaultContainerRuntimeDetector(
            lookupExecutable: { runtime in
                switch runtime {
                case .podman:
                    "/opt/homebrew/bin/podman"
                case .docker:
                    "/Applications/Docker.app/Contents/Resources/bin/docker"
                }
            }
        )

        let status = try await detector.detectInstalledRuntimes()

        #expect(status == .multipleRuntimesAvailable([.podman, .docker]))
    }
}
