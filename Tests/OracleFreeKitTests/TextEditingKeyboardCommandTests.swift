import AppKit
import Testing
@testable import OracleFreeKit

struct TextEditingKeyboardCommandTests {
    @Test func textEditingCommandsMatchCommonKeyboardShortcuts() {
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "a",
            modifierFlags: [.command]
        ) == .selectAll)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "c",
            modifierFlags: [.command]
        ) == .copy)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "x",
            modifierFlags: [.command]
        ) == .cut)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "v",
            modifierFlags: [.command]
        ) == .paste)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "z",
            modifierFlags: [.command]
        ) == .undo)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "z",
            modifierFlags: [.command, .shift]
        ) == .redo)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "y",
            modifierFlags: [.command]
        ) == .redo)
    }

    @Test func textEditingCommandsIgnoreCapsLock() {
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "A",
            modifierFlags: [.command, .capsLock]
        ) == .selectAll)
    }

    @Test func textEditingCommandsIgnoreUnsupportedKeyboardShortcuts() {
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "a",
            modifierFlags: [.command, .shift]
        ) == nil)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "a",
            modifierFlags: []
        ) == nil)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: "b",
            modifierFlags: [.command]
        ) == nil)
        #expect(TextEditingKeyboardCommand.action(
            charactersIgnoringModifiers: nil,
            modifierFlags: [.command]
        ) == nil)
    }
}
