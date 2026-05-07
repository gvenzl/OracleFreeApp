import Testing
@testable import OracleFreeKit

struct OracleContainerTrafficLightTests {
    @Test func startingTrafficLightUsesMacOSYellow() {
        #expect(OracleContainerTrafficLight.starting.rgb == OracleContainerTrafficLightRGB(
            red: 1.0,
            green: 189.0 / 255.0,
            blue: 46.0 / 255.0
        ))
    }
}
