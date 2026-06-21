import Carbon
import Foundation

/// Parses keybinding strings like `"cmd+ctrl+left"` into Carbon (modifiers, keyCode),
/// and formats them back into display symbols like `⌘⌃←`. Pure / unit-testable.
enum KeyParser {
    struct ParseError: Error, Equatable { let message: String }

    static func parse(_ string: String) throws -> (modifiers: UInt32, keyCode: UInt32) {
        let tokens = string
            .lowercased()
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { throw ParseError(message: "empty keybinding") }

        var modifiers: UInt32 = 0
        var keyToken: String?
        for token in tokens {
            if let mask = modifierMask(for: token) {
                modifiers |= mask
            } else if keyToken == nil {
                keyToken = token
            } else {
                throw ParseError(message: "more than one non-modifier key in '\(string)'")
            }
        }

        guard let key = keyToken else {
            throw ParseError(message: "no key (only modifiers) in '\(string)'")
        }
        guard let code = keyCode(for: key) else {
            throw ParseError(message: "unknown key '\(key)' in '\(string)'")
        }
        return (modifiers, code)
    }

    static func keybinding(from string: String) -> Keybinding? {
        guard let (modifiers, keyCode) = try? parse(string) else { return nil }
        return Keybinding(modifiers: modifiers, keyCode: keyCode, raw: string)
    }

    // MARK: - Display

    static func display(_ kb: Keybinding) -> String {
        display(modifiers: kb.modifiers, keyCode: kb.keyCode)
    }

    static func display(modifiers: UInt32, keyCode: UInt32) -> String {
        var out = ""
        if modifiers & UInt32(controlKey) != 0 { out += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { out += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { out += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { out += "⌘" }
        out += keySymbol(for: keyCode)
        return out
    }

    // MARK: - Tables

    static func modifierMask(for token: String) -> UInt32? {
        switch token {
        case "cmd", "command", "super", "meta": return UInt32(cmdKey)
        case "ctrl", "control":                 return UInt32(controlKey)
        case "alt", "opt", "option":            return UInt32(optionKey)
        case "shift":                           return UInt32(shiftKey)
        default:                                return nil
        }
    }

    static func keyCode(for token: String) -> UInt32? {
        letterAndDigitCodes[token] ?? specialCodes[token]
    }

    private static func keySymbol(for keyCode: UInt32) -> String {
        if let sym = symbolForCode[keyCode] { return sym }
        if let name = letterAndDigitCodes.first(where: { $0.value == keyCode })?.key {
            return name.uppercased()
        }
        return "?"
    }

    private static let letterAndDigitCodes: [String: UInt32] = [
        "a": UInt32(kVK_ANSI_A), "b": UInt32(kVK_ANSI_B), "c": UInt32(kVK_ANSI_C),
        "d": UInt32(kVK_ANSI_D), "e": UInt32(kVK_ANSI_E), "f": UInt32(kVK_ANSI_F),
        "g": UInt32(kVK_ANSI_G), "h": UInt32(kVK_ANSI_H), "i": UInt32(kVK_ANSI_I),
        "j": UInt32(kVK_ANSI_J), "k": UInt32(kVK_ANSI_K), "l": UInt32(kVK_ANSI_L),
        "m": UInt32(kVK_ANSI_M), "n": UInt32(kVK_ANSI_N), "o": UInt32(kVK_ANSI_O),
        "p": UInt32(kVK_ANSI_P), "q": UInt32(kVK_ANSI_Q), "r": UInt32(kVK_ANSI_R),
        "s": UInt32(kVK_ANSI_S), "t": UInt32(kVK_ANSI_T), "u": UInt32(kVK_ANSI_U),
        "v": UInt32(kVK_ANSI_V), "w": UInt32(kVK_ANSI_W), "x": UInt32(kVK_ANSI_X),
        "y": UInt32(kVK_ANSI_Y), "z": UInt32(kVK_ANSI_Z),
        "0": UInt32(kVK_ANSI_0), "1": UInt32(kVK_ANSI_1), "2": UInt32(kVK_ANSI_2),
        "3": UInt32(kVK_ANSI_3), "4": UInt32(kVK_ANSI_4), "5": UInt32(kVK_ANSI_5),
        "6": UInt32(kVK_ANSI_6), "7": UInt32(kVK_ANSI_7), "8": UInt32(kVK_ANSI_8),
        "9": UInt32(kVK_ANSI_9),
    ]

    private static let specialCodes: [String: UInt32] = [
        "left": UInt32(kVK_LeftArrow), "right": UInt32(kVK_RightArrow),
        "up": UInt32(kVK_UpArrow), "down": UInt32(kVK_DownArrow),
        "return": UInt32(kVK_Return), "enter": UInt32(kVK_Return),
        "space": UInt32(kVK_Space), "tab": UInt32(kVK_Tab),
        "delete": UInt32(kVK_Delete), "backspace": UInt32(kVK_Delete),
        "forwarddelete": UInt32(kVK_ForwardDelete),
        "esc": UInt32(kVK_Escape), "escape": UInt32(kVK_Escape),
        "home": UInt32(kVK_Home), "end": UInt32(kVK_End),
        "pageup": UInt32(kVK_PageUp), "pagedown": UInt32(kVK_PageDown),
        "-": UInt32(kVK_ANSI_Minus), "=": UInt32(kVK_ANSI_Equal),
        "[": UInt32(kVK_ANSI_LeftBracket), "]": UInt32(kVK_ANSI_RightBracket),
        ";": UInt32(kVK_ANSI_Semicolon), "'": UInt32(kVK_ANSI_Quote),
        ",": UInt32(kVK_ANSI_Comma), ".": UInt32(kVK_ANSI_Period),
        "/": UInt32(kVK_ANSI_Slash), "\\": UInt32(kVK_ANSI_Backslash),
        "`": UInt32(kVK_ANSI_Grave),
        "f1": UInt32(kVK_F1), "f2": UInt32(kVK_F2), "f3": UInt32(kVK_F3),
        "f4": UInt32(kVK_F4), "f5": UInt32(kVK_F5), "f6": UInt32(kVK_F6),
        "f7": UInt32(kVK_F7), "f8": UInt32(kVK_F8), "f9": UInt32(kVK_F9),
        "f10": UInt32(kVK_F10), "f11": UInt32(kVK_F11), "f12": UInt32(kVK_F12),
    ]

    private static let symbolForCode: [UInt32: String] = [
        UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_Return): "↩", UInt32(kVK_Space): "Space",
        UInt32(kVK_Tab): "⇥", UInt32(kVK_Delete): "⌫",
        UInt32(kVK_ForwardDelete): "⌦", UInt32(kVK_Escape): "⎋",
        UInt32(kVK_Home): "↖", UInt32(kVK_End): "↘",
        UInt32(kVK_PageUp): "⇞", UInt32(kVK_PageDown): "⇟",
    ]
}
