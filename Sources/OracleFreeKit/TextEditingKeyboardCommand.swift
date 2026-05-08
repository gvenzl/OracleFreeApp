import AppKit

public enum TextEditingKeyboardAction: Equatable {
    case selectAll
    case copy
    case cut
    case paste
    case undo
    case redo

    public var selector: Selector {
        switch self {
        case .selectAll:
            return #selector(NSText.selectAll(_:))
        case .copy:
            return #selector(NSText.copy(_:))
        case .cut:
            return #selector(NSText.cut(_:))
        case .paste:
            return #selector(NSText.paste(_:))
        case .undo:
            return Selector(("undo:"))
        case .redo:
            return Selector(("redo:"))
        }
    }
}

public enum TextEditingKeyboardCommand {
    public static func action(
        charactersIgnoringModifiers: String?,
        modifierFlags: NSEvent.ModifierFlags
    ) -> TextEditingKeyboardAction? {
        guard let character = charactersIgnoringModifiers?.lowercased() else {
            return nil
        }

        let relevantFlags = relevantModifierFlags(from: modifierFlags)

        switch (character, relevantFlags) {
        case ("a", .command):
            return .selectAll
        case ("c", .command):
            return .copy
        case ("x", .command):
            return .cut
        case ("v", .command):
            return .paste
        case ("z", .command):
            return .undo
        case ("z", [.command, .shift]), ("y", .command):
            return .redo
        default:
            return nil
        }
    }

    public static func isSelectAll(
        charactersIgnoringModifiers: String?,
        modifierFlags: NSEvent.ModifierFlags
    ) -> Bool {
        action(
            charactersIgnoringModifiers: charactersIgnoringModifiers,
            modifierFlags: modifierFlags
        ) == .selectAll
    }

    private static func relevantModifierFlags(from modifierFlags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting(.capsLock)
    }
}
