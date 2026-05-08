import CoreGraphics

public enum OracleFreeWindowConfiguration {
    public static let defaultWidth: CGFloat = 500
    public static let defaultHeight: CGFloat = 570
    public static let minimumWidth: CGFloat = 360
    public static let minimumHeight: CGFloat = 180
    public static let screenMargin: CGFloat = 48

    public static func targetContentSize(
        forMeasuredContentSize measuredContentSize: CGSize,
        maximumContentSize: CGSize? = nil
    ) -> CGSize {
        let roundedContentSize = CGSize(
            width: ceil(measuredContentSize.width),
            height: ceil(measuredContentSize.height)
        )
        let minimumSize = CGSize(width: minimumWidth, height: minimumHeight)
        let minimumClampedSize = CGSize(
            width: max(roundedContentSize.width, minimumSize.width),
            height: max(roundedContentSize.height, minimumSize.height)
        )

        guard let maximumContentSize else {
            return minimumClampedSize
        }

        return CGSize(
            width: min(minimumClampedSize.width, maximumContentSize.width),
            height: min(minimumClampedSize.height, maximumContentSize.height)
        )
    }

    public static func maximumContentSize(forScreenVisibleSize screenVisibleSize: CGSize) -> CGSize {
        CGSize(
            width: max(minimumWidth, screenVisibleSize.width - screenMargin),
            height: max(minimumHeight, screenVisibleSize.height - screenMargin)
        )
    }
}
