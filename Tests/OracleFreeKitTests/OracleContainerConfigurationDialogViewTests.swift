import SwiftUI
import Testing
@testable import OracleFreeKit

@MainActor
struct OracleContainerConfigurationDialogViewTests {
    @Test func configurationDialogRendersDefaultSettingsFields() {
        let view = OracleContainerConfigurationDialogView(settings: .constant(.default))

        let output = String(describing: view.body)

        #expect(output.contains("Container Configuration"))
        #expect(output.contains("Image"))
        #expect(output.contains("Container Name"))
        #expect(output.contains("Host Port"))
        #expect(output.contains("Volume Name"))
        #expect(output.contains("Password"))
        #expect(output.contains("Extra Environment Variables"))
        #expect(output.contains("Key"))
        #expect(output.contains("Value"))
        #expect(output.contains("Add Variable"))
        #expect(output.contains("Done"))
    }
}
