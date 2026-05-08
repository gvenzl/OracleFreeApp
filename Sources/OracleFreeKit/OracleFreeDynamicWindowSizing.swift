import AppKit
import SwiftUI

public extension View {
    func oracleFreeDynamicWindowSizing() -> some View {
        modifier(OracleFreeDynamicWindowSizingModifier())
    }
}

private struct OracleFreeDynamicWindowSizingModifier: ViewModifier {
    @State private var measuredContentSize: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .fixedSize()
            .background(contentSizeReader)
            .background(OracleFreeWindowSizeApplier(measuredContentSize: measuredContentSize))
            .onPreferenceChange(OracleFreeWindowContentSizePreferenceKey.self) { size in
                guard size.width > 0, size.height > 0 else {
                    return
                }

                measuredContentSize = size
            }
    }

    private var contentSizeReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: OracleFreeWindowContentSizePreferenceKey.self,
                value: proxy.size
            )
        }
    }
}

private struct OracleFreeWindowContentSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct OracleFreeWindowSizeApplier: NSViewRepresentable {
    let measuredContentSize: CGSize

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard measuredContentSize.width > 0, measuredContentSize.height > 0 else {
            return
        }

        DispatchQueue.main.async {
            guard let window = nsView.window else {
                return
            }

            let maximumContentSize = window.screen.map {
                OracleFreeWindowConfiguration.maximumContentSize(
                    forScreenVisibleSize: $0.visibleFrame.size
                )
            }
            let targetContentSize = OracleFreeWindowConfiguration.targetContentSize(
                forMeasuredContentSize: measuredContentSize,
                maximumContentSize: maximumContentSize
            )

            window.contentMinSize = CGSize(
                width: OracleFreeWindowConfiguration.minimumWidth,
                height: OracleFreeWindowConfiguration.minimumHeight
            )

            guard window.contentLayoutRect.size.isMeaningfullyDifferent(from: targetContentSize) else {
                return
            }

            window.setContentSize(targetContentSize)
        }
    }
}

private extension CGSize {
    func isMeaningfullyDifferent(from other: CGSize) -> Bool {
        abs(width - other.width) > 1 || abs(height - other.height) > 1
    }
}
