import Carbon
@testable import ShiftKit

func runKeyParserTests() {
    R.suite("KeyParser")

    R.noThrow("parse cmd+ctrl+left") {
        let (mods, code) = try KeyParser.parse("cmd+ctrl+left")
        R.equal(mods, UInt32(cmdKey | controlKey), "cmd+ctrl modifiers")
        R.equal(code, UInt32(kVK_LeftArrow), "left arrow keycode")
    }

    R.noThrow("parse bare letter") {
        let (mods, code) = try KeyParser.parse("a")
        R.equal(mods, UInt32(0), "no modifiers")
        R.equal(code, UInt32(kVK_ANSI_A), "letter a keycode")
    }

    R.noThrow("parse all four modifiers") {
        let (mods, code) = try KeyParser.parse("cmd+ctrl+alt+shift+f3")
        R.equal(mods, UInt32(cmdKey | controlKey | optionKey | shiftKey), "all modifiers")
        R.equal(code, UInt32(kVK_F3), "f3 keycode")
    }

    R.noThrow("modifier aliases") {
        let a = try KeyParser.parse("opt+x").modifiers
        let b = try KeyParser.parse("option+x").modifiers
        let c = try KeyParser.parse("alt+x").modifiers
        R.ok(a == b && b == c && a == UInt32(optionKey), "opt == option == alt")
    }

    R.noThrow("case-insensitive + whitespace") {
        let (mods, code) = try KeyParser.parse("  CMD + Ctrl + RIGHT ")
        R.equal(mods, UInt32(cmdKey | controlKey), "uppercase modifiers")
        R.equal(code, UInt32(kVK_RightArrow), "right arrow keycode")
    }

    R.throwsError("only modifiers (cmd+ctrl) rejected") { _ = try KeyParser.parse("cmd+ctrl") }
    R.throwsError("trailing plus (cmd+) rejected") { _ = try KeyParser.parse("cmd+") }
    R.throwsError("unknown key rejected") { _ = try KeyParser.parse("cmd+nope") }
    R.throwsError("multiple keys rejected") { _ = try KeyParser.parse("a+b") }
    R.throwsError("empty rejected") { _ = try KeyParser.parse("") }
    R.throwsError("whitespace-only rejected") { _ = try KeyParser.parse("   ") }

    if let kb = KeyParser.keybinding(from: "cmd+ctrl+left") {
        R.equal(KeyParser.display(kb), "⌃⌘←", "display order ⌃⌥⇧⌘ + symbol")
    } else {
        R.ok(false, "keybinding(from:) returned nil for valid string")
    }

    if let kb = KeyParser.keybinding(from: "cmd+ctrl+x") {
        R.equal(KeyParser.display(kb), "⌃⌘X", "display uppercases letters")
    } else {
        R.ok(false, "keybinding(from:) returned nil for valid string")
    }

    R.ok(KeyParser.keybinding(from: "cmd+garbage") == nil, "keybinding(from:) nil on garbage")
}
