import Foundation
import Testing

struct BuildScriptPackagingTests {
    @Test func buildScriptDefinesDMGPackageModeAndVersionMetadata() throws {
        let script = try String(
            contentsOfFile: "script/build_and_run.sh",
            encoding: .utf8
        )

        #expect(script.contains("APP_VERSION=\"1.0.0\""))
        #expect(script.contains("CFBundleShortVersionString"))
        #expect(script.contains("CFBundleVersion"))
        #expect(script.contains("--package|package"))
        #expect(script.contains("PACKAGE_IMAGE=\"$DIST_DIR/$APP_DISPLAY_NAME-$APP_VERSION.dmg\""))
        #expect(script.contains("LEGACY_PACKAGE_ARCHIVE=\"$DIST_DIR/$APP_DISPLAY_NAME-$APP_VERSION-unsigned.zip\""))
        #expect(script.contains("rm -f \"$LEGACY_PACKAGE_ARCHIVE\""))
        #expect(script.contains("/usr/bin/hdiutil create"))
        #expect(!script.contains("ditto -c -k --norsrc --keepParent"))
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

    @Test func buildScriptCopiesMenuBarIconPNGBeforeSigning() throws {
        let script = try String(
            contentsOfFile: "script/build_and_run.sh",
            encoding: .utf8
        )
        let copyCommand = "cp \"$APP_ICON_PNG_SOURCE\" \"$APP_RESOURCES/OracleFreeAppIcon.png\""
        let signCommand = "/usr/bin/codesign --force --deep --sign - \"$APP_BUNDLE\""
        let copyCommandIndex = try #require(script.range(of: copyCommand)?.lowerBound)
        let signCommandIndex = try #require(script.range(of: signCommand)?.lowerBound)

        #expect(script.contains("APP_ICON_PNG_SOURCE="))
        #expect(copyCommandIndex < signCommandIndex)
    }
}
