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
        #expect(script.contains("DMG_SETTINGS_FILE=\"$ROOT_DIR/script/dmg_settings.py\""))
        #expect(script.contains("DMG_BACKGROUND_IMAGE=\"$DIST_DIR/dmg-background.png\""))
        #expect(script.contains("LEGACY_PACKAGE_ARCHIVE=\"$DIST_DIR/$APP_DISPLAY_NAME-$APP_VERSION-unsigned.zip\""))
        #expect(script.contains("rm -f \"$LEGACY_PACKAGE_ARCHIVE\""))
        #expect(script.contains("python3 -m dmgbuild"))
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
        let backgroundCommand = "/usr/bin/swift \"$ROOT_DIR/script/generate_dmg_background.swift\" \"$DMG_BACKGROUND_IMAGE\""
        let packageCommand = "python3 -m dmgbuild"

        let appCopyIndex = try #require(script.range(of: appCopyCommand)?.lowerBound)
        let backgroundCommandIndex = try #require(script.range(of: backgroundCommand)?.lowerBound)
        let packageCommandIndex = try #require(script.range(of: packageCommand)?.lowerBound)

        #expect(appCopyIndex < backgroundCommandIndex)
        #expect(backgroundCommandIndex < packageCommandIndex)
        #expect(script.contains("-D \"background=$DMG_BACKGROUND_IMAGE\""))
        #expect(!script.contains("ln -s /Applications \"$DMG_STAGING_DIR/Applications\""))
    }

    @Test func dmgbuildSettingsDefineDragInstallLayout() throws {
        let settings = try String(
            contentsOfFile: "script/dmg_settings.py",
            encoding: .utf8
        )

        #expect(settings.contains("format = \"UDZO\""))
        #expect(settings.contains("filesystem = \"HFS+\""))
        #expect(settings.contains("background = defines[\"background\"]"))
        #expect(!settings.contains("background = \"builtin-arrow\""))
        #expect(settings.contains("\"Applications\": \"/Applications\""))
        #expect(settings.contains("\"Oracle Free App.app\""))
        #expect(settings.contains("\"Applications\""))
        #expect(settings.contains("icon_locations"))
        #expect(settings.contains("window_rect"))
    }

    @Test func dmgBackgroundGeneratorDrawsCenteredTransparentCurvedArrow() throws {
        let generator = try String(
            contentsOfFile: "script/generate_dmg_background.swift",
            encoding: .utf8
        )

        #expect(generator.contains("width: 640"))
        #expect(generator.contains("height: 360"))
        #expect(generator.contains("withAlphaComponent(0.42)"))
        #expect(generator.contains("let start = NSPoint(x: 252, y: 194)"))
        #expect(generator.contains("let control1 = NSPoint(x: 286, y: 272)"))
        #expect(generator.contains("let control2 = NSPoint(x: 354, y: 272)"))
        #expect(generator.contains("let end = NSPoint(x: 388, y: 194)"))
        #expect(generator.contains("curve(to:"))
        #expect(generator.contains("drawArrowHead"))
    }
}
