import CoreGraphics
import Testing
@testable import OracleFreeKit

struct OracleFreeWindowConfigurationTests {
    @Test func mainWindowDefaultsToSizeThatFitsStatusAndDetails() {
        #expect(OracleFreeWindowConfiguration.defaultWidth == 500)
        #expect(OracleFreeWindowConfiguration.defaultHeight == 570)
    }

    @Test func dynamicWindowSizeUsesMeasuredContentWhenItIsLargerThanMinimum() {
        let size = OracleFreeWindowConfiguration.targetContentSize(
            forMeasuredContentSize: CGSize(width: 420.2, height: 318.6)
        )

        #expect(size == CGSize(width: 421, height: 319))
    }

    @Test func dynamicWindowSizeClampsVerySmallContentToMinimumUsableSize() {
        let size = OracleFreeWindowConfiguration.targetContentSize(
            forMeasuredContentSize: CGSize(width: 120, height: 80)
        )

        #expect(size == CGSize(width: 360, height: 180))
    }

    @Test func dynamicWindowSizeClampsVeryLargeContentToVisibleScreenSize() {
        let size = OracleFreeWindowConfiguration.targetContentSize(
            forMeasuredContentSize: CGSize(width: 1400, height: 1000),
            maximumContentSize: CGSize(width: 900, height: 700)
        )

        #expect(size == CGSize(width: 900, height: 700))
    }
}
