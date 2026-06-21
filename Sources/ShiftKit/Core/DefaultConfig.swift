import Foundation

/// The TOML written to ~/.config/shift/config.toml on first launch.
/// Layout maps the classic Magnet/Nudge positions onto a 24x12 grid, using
/// ⌘⌃ (cmd+ctrl) as the modifier; display throws use ⌘⌃⌥.
enum DefaultConfig {
    static let toml = """
    # Shift configuration — https://github.com/GhostLabsHQ/shift
    #
    # The screen's usable area (minus menu bar / Dock) is divided into a grid.
    # A position's `cell = [x, y, w, h]` is in grid units with a TOP-LEFT origin:
    #   x = columns from the left,  y = rows from the top,
    #   w = width in columns,       h = height in rows.
    #
    # `key` is optional. Positions without a key still appear in the menu bar.
    # Keys: cmd / ctrl / alt(opt) / shift  +  a-z, 0-9, arrows, return, space,
    #       tab, delete, esc, f1-f12, punctuation.   e.g. "cmd+ctrl+left"
    #
    # Edit this file and save — Shift reloads automatically.

    [settings]
    columns = 24
    rows = 12
    gap = 0                      # px between adjacent windows
    screen_gap = 0              # px outer margin from screen edges
    # menu_icon: an SF Symbol name (e.g. "square.grid.3x3", "macwindow",
    # "rectangle.grid.2x2"), a path to a template PNG/PDF, or literal text/emoji.
    menu_icon = "rectangle.3.group"

    # ── Halves ───────────────────────────────────────────────
    [[position]]
    name = "left-half"
    cell = [0, 0, 12, 12]
    key  = "cmd+ctrl+left"

    [[position]]
    name = "right-half"
    cell = [12, 0, 12, 12]
    key  = "cmd+ctrl+right"

    [[position]]
    name = "top-half"
    cell = [0, 0, 24, 6]
    key  = "cmd+ctrl+up"

    [[position]]
    name = "bottom-half"
    cell = [0, 6, 24, 6]
    key  = "cmd+ctrl+down"

    # ── Quarters ─────────────────────────────────────────────
    [[position]]
    name = "top-left"
    cell = [0, 0, 12, 6]
    key  = "cmd+ctrl+u"

    [[position]]
    name = "top-right"
    cell = [12, 0, 12, 6]
    key  = "cmd+ctrl+i"

    [[position]]
    name = "bottom-left"
    cell = [0, 6, 12, 6]
    key  = "cmd+ctrl+j"

    [[position]]
    name = "bottom-right"
    cell = [12, 6, 12, 6]
    key  = "cmd+ctrl+k"

    # ── Thirds (24 / 3 = 8 columns each) ─────────────────────
    [[position]]
    name = "left-third"
    cell = [0, 0, 8, 12]
    key  = "cmd+ctrl+d"

    [[position]]
    name = "center-third"
    cell = [8, 0, 8, 12]
    key  = "cmd+ctrl+x"        # NB: ⌘⌃F is the macOS "Enter Full Screen" shortcut, so center-third uses X

    [[position]]
    name = "right-third"
    cell = [16, 0, 8, 12]
    key  = "cmd+ctrl+g"

    # ── Two-thirds ───────────────────────────────────────────
    [[position]]
    name = "left-two-thirds"
    cell = [0, 0, 16, 12]
    key  = "cmd+ctrl+e"

    [[position]]
    name = "right-two-thirds"
    cell = [8, 0, 16, 12]
    key  = "cmd+ctrl+t"

    # ── Specials ─────────────────────────────────────────────
    [[position]]
    name = "maximize"
    action = "maximize"
    key  = "cmd+ctrl+return"

    [[position]]
    name = "center"
    action = "center"          # centers, keeping the window's current size
    key  = "cmd+ctrl+c"

    [[position]]
    name = "restore"
    action = "restore"         # restore the pre-move frame
    key  = "cmd+ctrl+delete"

    # ── Move to other monitors ───────────────────────────────
    [[position]]
    name = "next-display"
    action = "next-display"
    key  = "cmd+ctrl+alt+right"

    [[position]]
    name = "prev-display"
    action = "previous-display"
    key  = "cmd+ctrl+alt+left"

    # ── Example: a keyless position (menu-only) ──────────────
    [[position]]
    name = "center-60"
    cell = [5, 2, 14, 8]       # a centered 14x8 block; no key, trigger from the menu

    """
}
