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
        #expect(output.contains("Install Docker, Podman, or Rancher Desktop, then try again."))
    }

    @Test func rootViewRendersRuntimeSelectionState() async {
        let runtimeSelectionViewModel = RuntimeSelectionViewModel(availableRuntimes: [.docker, .podman, .rancherDesktop])
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.multipleRuntimesAvailable([.docker, .podman, .rancherDesktop]))))
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

    @Test func rootViewRoutesDockerRuntimeToOracleLifecycle() async {
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.oneRuntimeAvailable(.docker))))
        let oracleViewModel = OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.docker]),
            oracleInstanceViewModel: oracleViewModel
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("OracleInstanceView"))
    }

    @Test func rootViewRoutesRancherDesktopRuntimeToOracleLifecycle() async {
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.oneRuntimeAvailable(.rancherDesktop))))
        let oracleViewModel = OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.rancherDesktop]),
            oracleInstanceViewModel: oracleViewModel
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("OracleInstanceView"))
    }

    @Test func rootViewRoutesPodmanRuntimeToMachineReadinessBeforeLifecycle() async {
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.oneRuntimeAvailable(.podman))))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.podman]),
            oracleInstanceViewModel: OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("PodmanMachineReadinessView"))
    }

    @Test func rootViewRoutesSelectedPodmanMachineToOracleLifecycle() async {
        let machine = PodmanMachine(
            id: "machine-default",
            name: "podman-machine-default",
            isRunning: true,
            isDefault: true,
            connectionName: "podman-machine-default-root"
        )
        let viewModel = AppViewModel(runtimeDetector: PreviewRuntimeDetector(result: .success(.oneRuntimeAvailable(.podman))))
        await viewModel.loadRuntimes()
        let rootView = RootView(
            appViewModel: viewModel,
            selectionViewModel: MachineSelectionViewModel(selectedMachine: machine),
            runtimeSelectionViewModel: RuntimeSelectionViewModel(availableRuntimes: [.podman]),
            oracleInstanceViewModel: OracleInstanceViewModel(service: PreviewOracleInstanceService(status: .missing))
        )

        let output = String(describing: rootView.body)

        #expect(output.contains("OracleInstanceView"))
    }

    @Test func oracleInstanceViewRendersMissingState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .missing))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free container has not been created yet"))
        #expect(output.contains("Create Oracle Database Free"))
        #expect(output.contains("Configuration"))
        #expect(!output.contains("Advanced Container Settings"))
    }

    @Test func oracleInstanceViewRendersReadyState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .ready(.default)))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free is ready"))
        #expect(output.contains("FREEPDB1"))
        #expect(output.contains("Username: system"))
        #expect(output.contains("Password: OracleFree123"))
        #expect(output.contains("Container"))
        #expect(output.contains("OracleFreeAppIcon"))
        #expect(output.contains("Running"))
        #expect(output.contains("oracle-free"))
        #expect(output.contains("1521:1521"))
        #expect(output.contains("oracle-free-data"))
        #expect(output.contains("running"))
    }

    @Test func oracleInstanceViewRendersNoVolumeWhenVolumeNameIsEmpty() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .ready(.noVolumePreview)))

        let output = String(describing: view.body)

        #expect(output.contains("Volume: No volume defined"))
    }

    @Test func oracleInstanceViewRendersCreatingState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .creating))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free is being created"))
    }

    @Test func oracleInstanceViewRendersStoppedState() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .stopped(.stoppedPreview)))

        let output = String(describing: view.body)

        #expect(output.contains("Container"))
        #expect(output.contains("OracleFreeAppIcon"))
        #expect(output.contains("Stopped"))
        #expect(output.contains("oracle-free"))
        #expect(output.contains("Start Oracle Database Free"))
        #expect(output.contains("Delete Oracle Database Free"))
    }

    @Test func oracleInstanceViewRendersRunningStateWithContainerDetails() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(status: .running(.default)))

        let output = String(describing: view.body)

        #expect(output.contains("Oracle Database Free is starting"))
        #expect(output.contains("Container"))
        #expect(output.contains("OracleFreeAppIcon"))
        #expect(output.contains("Starting"))
        #expect(output.contains("oracle-free"))
    }

    @Test func oracleInstanceViewRendersLogsWhenContainerIsStarting() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(
            status: .running(.default),
            containerLogs: "startup log lines"
        ))

        let output = String(describing: view.body)

        #expect(output.contains("Container Logs"))
        #expect(output.contains("startup log lines"))
    }

    @Test func oracleInstanceViewRendersLogsWhenContainerFails() {
        let view = OracleInstanceView(viewModel: PreviewOracleInstanceViewModel(
            status: .failed(message: "Unable to create container"),
            containerLogs: "port is already allocated"
        ))

        let output = String(describing: view.body)

        #expect(output.contains("Container Logs"))
        #expect(output.contains("port is already allocated"))
    }

    @Test func podmanMachineReadinessViewRendersLoadingState() {
        let view = PodmanMachineReadinessView(viewModel: MachineSelectionViewModel())

        let output = String(describing: view.body)

        #expect(output.contains("Loading Podman machines"))
    }

    @Test func podmanMachineReadinessViewRendersNoMachinesState() async {
        let runtime = EmptyMachinePreviewRuntime()
        let viewModel = MachineSelectionViewModel(runtime: runtime)
        await viewModel.loadMachines()
        let view = PodmanMachineReadinessView(viewModel: viewModel)

        let output = String(describing: view.body)

        #expect(output.contains("No Podman machines found"))
    }

    @Test func podmanMachineReadinessViewRendersStoppedMachineState() {
        let machine = PodmanMachine(
            id: "machine-default",
            name: "podman-machine-default",
            isRunning: false,
            isDefault: true,
            connectionName: "podman-machine-default-root"
        )
        let view = PodmanMachineReadinessView(viewModel: MachineSelectionViewModel(selectedMachine: machine))

        let output = String(describing: view.body)

        #expect(output.contains("Podman machine is stopped"))
        #expect(output.contains("podman-machine-default"))
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

private extension OracleContainerDetails {
    static let stoppedPreview = OracleContainerDetails(
        containerName: OracleContainerConfiguration.default.containerName,
        image: OracleContainerConfiguration.default.image,
        hostPort: OracleContainerConfiguration.default.hostPort,
        databasePort: OracleContainerConfiguration.default.databasePort,
        volumeName: OracleContainerConfiguration.default.volumeName,
        state: "exited",
        status: "Exited (0)",
        connectionInfo: .default
    )

    static let noVolumePreview = OracleContainerDetails(
        containerName: OracleContainerConfiguration.default.containerName,
        image: OracleContainerConfiguration.default.image,
        hostPort: OracleContainerConfiguration.default.hostPort,
        databasePort: OracleContainerConfiguration.default.databasePort,
        volumeName: "",
        state: "running",
        status: "healthy",
        connectionInfo: .default
    )
}

private struct PreviewOracleInstanceService: OracleInstanceServicing {
    let status: OracleInstanceStatus

    func inspectInstance(configuration: OracleContainerConfiguration) async throws -> OracleInstanceStatus {
        status
    }

    func createInstance(configuration: OracleContainerConfiguration) async throws {}
    func startInstance(configuration: OracleContainerConfiguration) async throws {}
    func stopInstance(configuration: OracleContainerConfiguration) async throws {}
    func deleteInstance(configuration: OracleContainerConfiguration) async throws {}
    func containerLogs(configuration: OracleContainerConfiguration) async throws -> String { "" }
}

private struct EmptyMachinePreviewRuntime: PodmanRuntime {
    func discoverMachines() async throws -> [PodmanMachine] {
        []
    }

    func startMachine(named name: String) async throws {}
    func listContainers() async throws -> [ContainerSummary] { [] }
    func createContainer(configuration: OracleContainerConfiguration) async throws {}
    func startContainer(named name: String) async throws {}
    func stopContainer(named name: String) async throws {}
    func deleteContainer(named name: String) async throws {}
    func deleteVolume(named name: String) async throws {}
    func containerLogs(named name: String) async throws -> String { "" }
}

@MainActor
@Observable
private final class PreviewOracleInstanceViewModel: OracleInstanceViewing {
    let status: OracleInstanceStatus
    let containerLogs: String?
    var containerSettings: OracleContainerSettings = .default

    init(status: OracleInstanceStatus, containerLogs: String? = nil) {
        self.status = status
        self.containerLogs = containerLogs
    }

    func createInstance() async {}
    func startInstance() async {}
    func stopInstance() async {}
    func deleteInstance() async {}
}
