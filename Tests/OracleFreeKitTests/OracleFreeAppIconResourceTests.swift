import Testing
@testable import OracleFreeKit

struct OracleFreeAppIconResourceTests {
    @Test func appIconResourceLoadsImageFromBundle() {
        let image = OracleFreeAppIconResource.image

        #expect(image != nil)
        #expect(image?.size.width == 1024)
        #expect(image?.size.height == 1024)
    }

    @Test func appIconResourceCreatesSmallMenuBarImage() {
        let image = OracleFreeAppIconResource.menuBarImage()

        #expect(image != nil)
        #expect(image?.size.width == 16)
        #expect(image?.size.height == 16)
    }
}
