import Testing
@testable import OracleFreeKit

@MainActor
struct RuntimeSelectionViewModelTests {
    @Test func runtimeSelectionViewModelStartsWithoutSelection() {
        let viewModel = RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker])

        #expect(viewModel.selectedRuntime == nil)
        #expect(viewModel.selection == nil)
    }

    @Test func runtimeSelectionViewModelSelectsRuntime() {
        let viewModel = RuntimeSelectionViewModel(availableRuntimes: [.podman, .docker])

        viewModel.select(.docker)

        #expect(viewModel.selectedRuntime == .docker)
        #expect(viewModel.selection == ContainerRuntimeSelection(runtime: .docker))
    }

    @Test func runtimeSelectionViewModelClearsRuntimeSelection() {
        let viewModel = RuntimeSelectionViewModel(
            availableRuntimes: [.podman, .docker],
            selectedRuntime: .docker
        )

        viewModel.clearSelection()

        #expect(viewModel.selectedRuntime == nil)
        #expect(viewModel.selection == nil)
    }

    @Test func runtimeSelectionViewModelUpdatesAvailableRuntimes() {
        let viewModel = RuntimeSelectionViewModel(
            availableRuntimes: [.docker, .podman, .rancherDesktop]
        )

        viewModel.updateAvailableRuntimes([.docker, .podman])

        #expect(viewModel.availableRuntimes == [.docker, .podman])
    }

    @Test func runtimeSelectionViewModelClearsSelectionWhenUpdatedRuntimesDoNotContainIt() {
        let viewModel = RuntimeSelectionViewModel(
            availableRuntimes: [.docker, .podman, .rancherDesktop],
            selectedRuntime: .rancherDesktop
        )

        viewModel.updateAvailableRuntimes([.docker, .podman])

        #expect(viewModel.availableRuntimes == [.docker, .podman])
        #expect(viewModel.selectedRuntime == nil)
        #expect(viewModel.selection == nil)
    }
}
