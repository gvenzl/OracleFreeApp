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

    @Test func buildAppWorkflowInstallsDmgbuildBeforePackaging() throws {
        let workflow = try String(
            contentsOfFile: ".github/workflows/build-app.yml",
            encoding: .utf8
        )

        let venvIndex = try #require(workflow.range(of: "python3 -m venv .venv-dmgbuild")?.lowerBound)
        let pathIndex = try #require(workflow.range(of: "echo \"$PWD/.venv-dmgbuild/bin\" >> \"$GITHUB_PATH\"")?.lowerBound)
        let installIndex = try #require(workflow.range(of: "python -m pip install dmgbuild")?.lowerBound)
        let packageIndex = try #require(workflow.range(of: "./script/build_and_run.sh --package")?.lowerBound)

        #expect(workflow.range(of: "pip install --user") == nil)
        #expect(venvIndex < installIndex)
        #expect(pathIndex < packageIndex)
        #expect(installIndex < packageIndex)
    }
}
