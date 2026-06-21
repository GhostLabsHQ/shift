import Foundation
import CoreGraphics

/// A rectangle expressed in grid-cell units. Origin is TOP-LEFT:
/// `x` columns from the left edge, `y` rows from the top edge.
struct CellRect: Equatable {
    var x: Int   // column offset from left  (0 ..< columns)
    var y: Int   // row offset from top      (0 ..< rows)
    var w: Int   // width in columns         (>= 1)
    var h: Int   // height in rows           (>= 1)
}

/// What a registered position does when triggered.
enum PositionKind: Equatable {
    case cell(CellRect)        // snap to a grid rectangle
    case maximize              // fill the screen's visible frame
    case center                // center the window keeping its current size
    case restore               // restore the window's pre-move frame
    case nextDisplay           // throw to the next monitor
    case previousDisplay       // throw to the previous monitor
}

/// A parsed keyboard shortcut (Carbon modifier mask + virtual key code).
struct Keybinding: Equatable {
    let modifiers: UInt32
    let keyCode: UInt32
    let raw: String            // original config string, e.g. "cmd+ctrl+left"
}

/// A named position in the registry. `key` is optional — keyless positions are
/// still listed in the menu and triggerable from there.
struct Position {
    let name: String
    let kind: PositionKind
    let key: Keybinding?
}

/// Grid + behavior settings from the `[settings]` table.
struct GridSettings: Equatable {
    var columns: Int = 24
    var rows: Int = 12
    var gap: CGFloat = 0               // px between adjacent window edges
    var screenGap: CGFloat = 0         // px outer margin from screen edges
    var menuIcon: String = "rectangle.3.group"   // SF Symbol name, image path, or literal text
}

struct ShiftConfig {
    var settings: GridSettings
    var positions: [Position]
}

extension Notification.Name {
    static let configReloaded = Notification.Name("ShiftConfigReloaded")
    static let displaysChanged = Notification.Name("ShiftDisplaysChanged")
}
