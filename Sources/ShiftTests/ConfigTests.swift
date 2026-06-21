import Carbon
@testable import ShiftKit

func runConfigTests() {
    R.suite("Config")

    R.noThrow("parse settings + position") {
        let config = try ConfigLoader.parse("""
        [settings]
        columns = 16
        rows = 8
        gap = 6
        screen_gap = 12
        menu_icon = "macwindow"

        [[position]]
        name = "left-half"
        cell = [0, 0, 8, 8]
        key = "cmd+ctrl+left"
        """)
        R.equal(config.settings.columns, 16, "columns")
        R.equal(config.settings.rows, 8, "rows")
        R.equal(config.settings.gap, 6, "gap")
        R.equal(config.settings.screenGap, 12, "screen_gap")
        R.equal(config.settings.menuIcon, "macwindow", "menu_icon")
        R.equal(config.positions.count, 1, "one position")
        R.equal(config.positions[0].name, "left-half", "name")
        R.ok(config.positions[0].kind == .cell(CellRect(x: 0, y: 0, w: 8, h: 8)), "cell kind")
        R.equal(config.positions[0].key?.keyCode, UInt32(kVK_LeftArrow), "bound key")
    }

    R.noThrow("defaults when [settings] omitted") {
        let config = try ConfigLoader.parse("""
        [[position]]
        name = "max"
        action = "maximize"
        """)
        R.equal(config.settings.columns, 24, "default columns")
        R.equal(config.settings.rows, 12, "default rows")
        R.equal(config.settings.menuIcon, "rectangle.3.group", "default menu_icon")
        R.ok(config.positions.first?.kind == .maximize, "maximize action")
    }

    R.noThrow("action normalization") {
        let config = try ConfigLoader.parse("""
        [[position]]
        name = "a"
        action = "previous-display"
        [[position]]
        name = "b"
        action = "next_display"
        [[position]]
        name = "c"
        action = "PrevDisplay"
        """)
        R.ok(config.positions[0].kind == .previousDisplay, "hyphen: previous-display")
        R.ok(config.positions[1].kind == .nextDisplay, "underscore: next_display")
        R.ok(config.positions[2].kind == .previousDisplay, "case + alias: PrevDisplay")
    }

    R.noThrow("keyless position kept unbound") {
        let config = try ConfigLoader.parse("""
        [[position]]
        name = "reading"
        cell = [6, 0, 12, 12]
        """)
        R.equal(config.positions.count, 1, "kept")
        R.ok(config.positions[0].key == nil, "unbound")
    }

    R.noThrow("invalid entries skipped, not fatal") {
        let config = try ConfigLoader.parse("""
        [[position]]
        name = "ok"
        cell = [0, 0, 1, 1]
        [[position]]
        cell = [0, 0, 1, 1]
        [[position]]
        name = "bad-action"
        action = "teleport"
        [[position]]
        name = "no-kind"
        """)
        R.equal(config.positions.map(\.name), ["ok"], "only valid entry kept")
    }

    R.noThrow("bad key leaves position unbound") {
        let config = try ConfigLoader.parse("""
        [[position]]
        name = "x"
        cell = [0, 0, 1, 1]
        key = "cmd+totally-not-a-key"
        """)
        R.equal(config.positions.count, 1, "kept")
        R.ok(config.positions[0].key == nil, "unbound on bad key")
    }

    R.throwsError("malformed TOML throws") { _ = try ConfigLoader.parse("this is = = not toml [") }

    R.noThrow("shipped default config parses") {
        let config = try ConfigLoader.parse(DefaultConfig.toml)
        R.ok(config.positions.count >= 17, "has at least 17 positions (got \(config.positions.count))")

        let leftHalf = config.positions.first { $0.name == "left-half" }
        R.ok(leftHalf?.kind == .cell(CellRect(x: 0, y: 0, w: 12, h: 12)), "left-half cell")
        R.ok(leftHalf?.key != nil, "left-half bound")

        // center-third must dodge the ⌘⌃F "Enter Full Screen" system shortcut.
        let centerThird = config.positions.first { $0.name == "center-third" }
        R.equal(centerThird?.key?.keyCode, UInt32(kVK_ANSI_X), "center-third on X not F")

        let center60 = config.positions.first { $0.name == "center-60" }
        R.ok(center60 != nil, "center-60 present")
        R.ok(center60?.key == nil, "center-60 keyless")
    }
}
