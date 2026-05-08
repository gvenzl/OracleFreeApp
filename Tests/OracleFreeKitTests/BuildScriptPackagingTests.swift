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
}
