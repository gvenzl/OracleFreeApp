import Observation

@MainActor
@Observable
public final class RuntimeSelectionViewModel {
    public private(set) var availableRuntimes: [ContainerRuntimeKind]
    public private(set) var selectedRuntime: ContainerRuntimeKind?

    public var selection: ContainerRuntimeSelection? {
        guard let selectedRuntime else {
            return nil
        }

        return ContainerRuntimeSelection(runtime: selectedRuntime)
    }

    public init(
        availableRuntimes: [ContainerRuntimeKind],
        selectedRuntime: ContainerRuntimeKind? = nil
    ) {
        self.availableRuntimes = availableRuntimes
        self.selectedRuntime = selectedRuntime
    }

    public func select(_ runtime: ContainerRuntimeKind) {
        guard availableRuntimes.contains(runtime) else {
            return
        }

        selectedRuntime = runtime
    }

    public func clearSelection() {
        selectedRuntime = nil
    }

    public func updateAvailableRuntimes(_ availableRuntimes: [ContainerRuntimeKind]) {
        self.availableRuntimes = availableRuntimes

        if let selectedRuntime, !availableRuntimes.contains(selectedRuntime) {
            self.selectedRuntime = nil
        }
    }
}
