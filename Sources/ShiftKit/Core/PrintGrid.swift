import Cocoa

/// `--print-grid`: load the config and print each position's computed frame for
/// the main screen, without moving a single window. Lets you verify geometry
/// numerically before trusting the live moves.
public enum PrintGrid {
    public static func run() {
        Config.shared.loadOrSeed()
        let config = Config.shared.current
        guard let screen = NSScreen.main else {
            print("No screen available.")
            return
        }
        let vf = screen.visibleFrame
        let s = config.settings

        print("Shift — grid preview")
        print("Visible frame: \(fmt(vf))")
        print("Grid: \(s.columns) x \(s.rows)   gap: \(s.gap)   screen_gap: \(s.screenGap)")
        print(String(repeating: "─", count: 72))
        print(pad("position", 20) + pad("cell / action", 22) + "frame (AppKit, x y w h)")
        print(String(repeating: "─", count: 72))

        for p in config.positions {
            let detail: String
            let frame: CGRect?
            switch p.kind {
            case .cell(let c):
                detail = "[\(c.x), \(c.y), \(c.w), \(c.h)]"
                frame = GridGeometry.frame(for: c, on: screen, settings: s)
            case .maximize:
                detail = "maximize"
                frame = s.screenGap > 0 ? vf.insetBy(dx: s.screenGap, dy: s.screenGap) : vf
            default:
                detail = String(describing: p.kind)
                frame = nil
            }
            let key = p.key.map { " (\(KeyParser.display($0)))" } ?? ""
            print(pad(p.name + key, 20) + pad(detail, 22) + (frame.map(fmt) ?? "—"))
        }
    }

    private static func fmt(_ r: CGRect) -> String {
        "\(Int(r.origin.x)) \(Int(r.origin.y)) \(Int(r.width)) \(Int(r.height))"
    }

    private static func pad(_ s: String, _ n: Int) -> String {
        s.count >= n ? s + " " : s + String(repeating: " ", count: n - s.count)
    }
}
