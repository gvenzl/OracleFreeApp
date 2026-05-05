import SwiftUI
import Testing
@testable import OracleFreeKit

@MainActor
struct RootViewTests {
    @Test func rootViewRendersLoadingState() {
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.noSupportedRuntimeInstalled)))
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker]),
            oracleInstanceViewModel: OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("Loading runtimes"))
    }

    @Test func rootViewRendersFailureState() async {
        let viewModel = AppViewModel(runtimeDetector: FailingPreviewRuntimeDetector())
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker]),
            oracleInstanceViewModel: OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("Unable to detect runtimes"))
    }

    @Test func rootViewRendersMissingRuntimeState() async {
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.noSupportedRuntimeInstalled)))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker]),
            oracleInstanceViewModel: OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("No supported container runtime found"))
    }

    @Test func rootViewRendersRuntimeSelectionState() async {
        let runtimeSelectionViewModel = RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker])
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.multipleRuntimesAvailable([.podman, .docker]))))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: runtimeSelectionViewModel,
            oracleInstanceViewModel: OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("RuntimeSelectionView"))
    }

    @Test func rootViewRoutesSingleRuntimeToOracleLifecycle() async {
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.oneRuntimeAvailable(.podman))))
        let oracleViewModel = OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.podman]),
            oracleInstanceViewModel: oracleViewModel
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("OracleInstanceView"))
    }

    @Test func oracleInstanceViewRendersMissingState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .missing))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free container has not been created yet"))
        #expect(output.contains("Create Oracle Database Free"))
    }

    @Test func oracleInstanceViewRendersReadyState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .ready(.default)))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free is ready"))
        #expect(output.contains("FREEPDB1"))
    }

    @Test func oracleInstanceViewRendersCreatingState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .creating))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free is being created"))
    }

    @Test func oracleInstanceViewRendersStoppedState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .stopped))

        let output = String(describing: view.body)

        #expect(output.contains("Start Oracle Database Free"))
        #expect(output.contains("Delete Oracle Database Free"))
    }
}

private struct PreviewRuntimeDetector: ContainerRuntimeDetector {
    let result: Result<ContainerRuntimeInstallationStatus, Never>

    func detectInstalledRuntimes() async throws -> ContainerRuntimeInstallationStatus {
        switch result {
        case let .success(status):
            return status
        }
    }
}

private struct FailingPreviewRuntimeDetector: ContainerRuntimeDetector {
    func detectInstalledRuntimes() async throws -> ContainerRuntimeInstallationStatus {
        throw PreviewError()
    }
}

private struct PreviewError: LocalizedError {
    var errorDescription: String? {
        "Unable to detect runtimes"
    }
}

private struct PreviewOracleInstanceService: OracleInstanceServicing {
    let status: OracleInstanceStatus

    func inspectInstance() async throws -> OracleInstanceStatus {
        status
    }

    func createInstance() async throws {}
    func startInstance() async throws {}
    func stopInstance() async throws {}
    func deleteInstance() async throws {}
}

@MainActor
@Observable
private final class PreviewOracleInstanceViewModel: OracleInstanceViewing {
    let status: OracleInstanceStatus

    init(status: OracleInstanceStatus) {
        self.status = status
    }

    func createInstance() async {}
    func startInstance() async {}
    func stopInstance() async {}
    func deleteInstance() async {}
}
