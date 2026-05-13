import Foundation
import Testing

struct BuildScriptPackagingTests {
    @Test func buildScriptDefinesDMGPackageModeAndVersionMetadata() throws {
        let script = try String(
            contentsOfFile: "script/build_and_run.sh",
            encoding: .utf8
        )

        #expect(script.contains("VERSION_FILE=\"$ROOT_DIR/VERSION\""))
        #expect(script.contains("APP_VERSION=\"$(tr -d '[:space:]' < \"$VERSION_FILE\")\""))
        #expect(script.range(of: #"APP_VERSION="[0-9]"#, options: .regularExpression) == nil)
        #expect(script.contains("CFBundleShortVersionString"))
        #expect(script.contains("CFBundleVersion"))
        #expect(script.contains("BUNDLE_ID=\"com.gvenzl.OracleFreeApp\""))
        #expect(script.contains("CFBundleIdentifier"))
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

    @Test func buildScriptStagesApplicationsShortcutInDMG() throws {
        let script = try String(
            contentsOfFile: "script/build_and_run.sh",
            encoding: .utf8
        )

        let appCopyCommand = "/usr/bin/ditto \"$APP_BUNDLE\" \"$DMG_STAGING_DIR/$APP_DISPLAY_NAME.app\""
        let applicationsShortcutCommand = "ln -s /Applications \"$DMG_STAGING_DIR/Applications\""
        let createDMGCommand = "/usr/bin/hdiutil create"

        let appCopyIndex = try #require(script.range(of: appCopyCommand)?.lowerBound)
        let applicationsShortcutIndex = try #require(script.range(of: applicationsShortcutCommand)?.lowerBound)
        let createDMGIndex = try #require(script.range(of: createDMGCommand)?.lowerBound)

        #expect(appCopyIndex < applicationsShortcutIndex)
        #expect(applicationsShortcutIndex < createDMGIndex)
    }
}
