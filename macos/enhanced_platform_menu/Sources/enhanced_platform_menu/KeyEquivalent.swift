import Cocoa

/// Translates a Flutter `LogicalKeyboardKey` id into an `NSMenuItem` key equivalent.
///
/// Tab is deliberately not supported: Flutter's view handles it before the
/// menu does, so a Tab shortcut would show but never fire.
enum KeyEquivalent {
    /// AppKit's characters for keys that have no printable character, keyed by
    /// the Flutter logical key id. The values match SwiftUI's `KeyEquivalent`.
    static let specialKeys: [Int: Int] = {
        var keys: [Int: Int] = [
            0x00100000008: NSBackspaceCharacter,         // backspace → ⌫
            0x0010000000d: NSCarriageReturnCharacter,    // enter → ↩
            0x0010000001b: 0x1B,                         // escape → ⎋
            0x0010000007f: NSDeleteFunctionKey,          // delete → ⌦
            0x00100000301: NSDownArrowFunctionKey,
            0x00100000302: NSLeftArrowFunctionKey,
            0x00100000303: NSRightArrowFunctionKey,
            0x00100000304: NSUpArrowFunctionKey,
            0x00100000305: NSEndFunctionKey,
            0x00100000306: NSHomeFunctionKey,
            0x00100000307: NSPageDownFunctionKey,
            0x00100000308: NSPageUpFunctionKey,
        ]
        // F1 … F20 are consecutive on both sides.
        for offset in 0..<20 {
            keys[0x00100000801 + offset] = NSF1FunctionKey + offset
        }
        return keys
    }()

    /// The key equivalent for the logical key `keyId`, or `nil` if AppKit has none.
    static func forTrigger(_ keyId: Int) -> String? {
        if (0x20...0x7E).contains(keyId), let scalar = UnicodeScalar(keyId) {
            return String(Character(scalar)).lowercased()
        }
        if let code = specialKeys[keyId], let scalar = UnicodeScalar(code) {
            return String(Character(scalar))
        }
        return nil
    }
}
