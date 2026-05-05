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
}
