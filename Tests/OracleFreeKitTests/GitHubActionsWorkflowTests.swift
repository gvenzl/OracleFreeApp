import Foundation
import Testing

struct GitHubActionsWorkflowTests {
    @Test func buildAppWorkflowDoesNotHardCodeVersionedDMGPath() throws {
        let workflow = try String(
            contentsOfFile: ".github/workflows/build-app.yml",
            encoding: .utf8
        )

        #expect(
            workflow.range(
                of: #"Oracle Free App-[0-9]+\.[0-9]+\.[0-9]+\.dmg"#,
                options: .regularExpression
            ) == nil
        )
        #expect(workflow.contains("dist/Oracle Free App-*.dmg"))
    }
}
