import SwiftUI

@MainActor
public protocol RuntimeSelectionViewing: AnyObject {
    var availableRuntimes: [ContainerRuntimeKind] { get }
    var selection: ContainerRuntimeSelection? { get }
    func select(_ runtime: ContainerRuntimeKind)
}

public struct RuntimeSelectionView<ViewModel: RuntimeSelectionViewing>: View {
    @State private var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a container runtime")
            ForEach(viewModel.availableRuntimes, id: \.self) { runtime in
                Button(runtime.displayName) {
                    viewModel.select(runtime)
                }
            }
        }
    }
}

extension RuntimeSelectionViewModel: RuntimeSelectionViewing {}
