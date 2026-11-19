import UIKit

/// Translates a Flutter `LogicalKeyboardKey` id into a `UIKeyCommand` input.
///
/// Tab is deliberately not supported: Flutter handles it itself (focus
/// traversal), so a Tab shortcut would show but never fire.
enum KeyInput {
    /// UIKit has no constant for forward delete and draws no glyph for the real
    /// key input (`"\u{7F}"`), so the visible command uses a literal ⌦. A literal
    /// ⌦ never matches the hardware key, so a hidden twin command with this
    /// input does the triggering. `nil` for keys that need no twin.
    static func hiddenTrigger(_ keyId: Int) -> String? {
        keyId == 0x0010000007f ? "\u{7F}" : nil
    }

    /// Whether `keyId` is a non-printable key. The system handles several of
    /// these itself (arrows and tab move focus, for example), so their key
    /// commands need `wantsPriorityOverSystemBehavior` to fire.
    static func isSpecial(_ keyId: Int) -> Bool {
        !(0x20...0x7E).contains(keyId)
    }

    /// The input for the logical key, or `nil` if UIKit has none.
    static func forTrigger(_ keyId: Int) -> String? {
        if (0x20...0x7E).contains(keyId), let scalar = UnicodeScalar(keyId) {
            return String(Character(scalar)).lowercased()
        }
        switch keyId {
        case 0x00100000008: return "\u{8}"   // backspace → ⌫ (same value as UIKeyCommand.inputDelete)
        case 0x0010000007f: return "\u{2326}" // forward delete: literal ⌦ so UIKit draws the glyph; see `hiddenTrigger`
        case 0x0010000000d: return "\r"
        case 0x0010000001b: return UIKeyCommand.inputEscape
        case 0x00100000301: return UIKeyCommand.inputDownArrow
        case 0x00100000302: return UIKeyCommand.inputLeftArrow
        case 0x00100000303: return UIKeyCommand.inputRightArrow
        case 0x00100000304: return UIKeyCommand.inputUpArrow
        case 0x00100000307: return UIKeyCommand.inputPageDown
        case 0x00100000308: return UIKeyCommand.inputPageUp
        default: break
        }
        if #available(iOS 13.4, *) {
            switch keyId {
            case 0x00100000305: return UIKeyCommand.inputEnd
            case 0x00100000306: return UIKeyCommand.inputHome
            case 0x00100000801: return UIKeyCommand.f1
            case 0x00100000802: return UIKeyCommand.f2
            case 0x00100000803: return UIKeyCommand.f3
            case 0x00100000804: return UIKeyCommand.f4
            case 0x00100000805: return UIKeyCommand.f5
            case 0x00100000806: return UIKeyCommand.f6
            case 0x00100000807: return UIKeyCommand.f7
            case 0x00100000808: return UIKeyCommand.f8
            case 0x00100000809: return UIKeyCommand.f9
            case 0x0010000080a: return UIKeyCommand.f10
            case 0x0010000080b: return UIKeyCommand.f11
            case 0x0010000080c: return UIKeyCommand.f12
            default: break
            }
        }
        return nil
    }
}
