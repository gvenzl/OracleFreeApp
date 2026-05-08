import Foundation
import Testing

struct BuildScriptPackagingTests {
    @Test func buildScriptDefinesUnsignedPackageModeAndVersionMetadata() throws {
        let script = try String(
            contentsOfFile: "script/build_and_run.sh",
            encoding: .utf8
        )

        #expect(script.contains("APP_VERSION=\"1.0.0\""))
        #expect(script.contains("CFBundleShortVersionString"))
        #expect(script.contains("CFBundleVersion"))
        #expect(script.contains("--package|package"))
        #expect(script.contains("ditto -c -k --norsrc --keepParent"))
    }

    @Test func buildScriptSignsCompletedAppBundleBeforePackaging() throws {
        let script = try String(
            contentsOfFile: "script/build_and_run.sh",
            encoding: .utf8
        )

        let signCommand = "/usr/bin/codesign --force --deep --sign - \"$APP_BUNDLE\""
        let signCommandIndex = try #require(script.range(of: signCommand)?.lowerBound)
        let packageFunctionIndex = try #require(script.range(of: "package_app()")?.lowerBound)

        #expect(signCommandIndex < packageFunctionIndex)
    }
}
