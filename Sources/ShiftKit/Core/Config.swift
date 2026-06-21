import Foundation
import CoreGraphics
import TOMLKit

/// Owns the on-disk config: seeding, loading/parsing, and live reload.
final class Config {
    static let shared = Config()
    private init() {}

    private(set) var current = ShiftConfig(settings: GridSettings(), positions: [])
    private var watcher: FileWatcher?

    static var directoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/shift", isDirectory: true)
    }

    static var fileURL: URL {
        directoryURL.appendingPathComponent("config.toml")
    }

    // MARK: - Load / seed

    func loadOrSeed() {
        if !FileManager.default.fileExists(atPath: Self.fileURL.path) {
            seed()
        }
        reload()
    }

    private func seed() {
        do {
            try FileManager.default.createDirectory(at: Self.directoryURL, withIntermediateDirectories: true)
            try DefaultConfig.toml.write(to: Self.fileURL, atomically: true, encoding: .utf8)
            FileLog.write("seeded default config at \(Self.fileURL.path)")
        } catch {
            FileLog.write("failed to seed config: \(error)")
        }
    }

    func reload() {
        do {
            let text = try String(contentsOf: Self.fileURL, encoding: .utf8)
            current = try ConfigLoader.parse(text)
            FileLog.write("config loaded: \(current.positions.count) positions, \(current.positions.filter { $0.key != nil }.count) bound")
            NotificationCenter.default.post(name: .configReloaded, object: nil)
        } catch {
            FileLog.write("config load FAILED: \(error) — keeping previous config")
        }
    }

    // MARK: - Watch

    func startWatching(_ onChange: @escaping () -> Void) {
        // Watch the directory (not the file) so atomic saves by editors are seen.
        watcher = FileWatcher(url: Self.directoryURL, onChange: onChange)
        watcher?.start()
    }

    func stopWatching() {
        watcher?.stop()
        watcher = nil
    }
}

/// Stateless TOML → ShiftConfig parsing. Unit-testable.
enum ConfigLoader {
    static func parse(_ toml: String) throws -> ShiftConfig {
        let root = try TOMLTable(string: toml)

        var settings = GridSettings()
        if let s = root["settings"]?.table {
            if s["columns"] != nil || s["rows"] != nil {
                FileLog.write("config: the grid is fixed at 24×12 — ignoring columns/rows in [settings]")
            }
            settings.gap = number(s["gap"]) ?? settings.gap
            settings.screenGap = number(s["screen_gap"]) ?? settings.screenGap
            if let v = s["menu_icon"]?.string, !v.isEmpty { settings.menuIcon = v }
        }

        // Built-in positions are baked in; the config only rebinds their keys.
        var overrides: [String: String] = [:]
        if let kb = root["keybindings"]?.table {
            for code in kb.keys {
                if let v = kb[code]?.string { overrides[code] = v }
            }
        }
        let builtins = BuiltinPositions.resolved(overrides: overrides)

        // Custom positions: fully user-defined via [[position]].
        var customs: [Position] = []
        if let arr = root["position"]?.array {
            for i in 0..<arr.count {
                guard let table = arr[i].table else { continue }

                // Identity: a position needs at least a `code` or a `name`.
                // `code` is the stable id; `name` is the friendly display name.
                // Either can be derived from the other for backward compatibility.
                let rawCode = table["code"]?.string.flatMap { $0.isEmpty ? nil : $0 }
                let rawName = table["name"]?.string.flatMap { $0.isEmpty ? nil : $0 }
                guard rawCode != nil || rawName != nil else {
                    FileLog.write("config: skipping position #\(i) with no name or code")
                    continue
                }
                let code = rawCode ?? slug(rawName!)
                let name = rawName ?? humanize(rawCode!)

                guard !BuiltinPositions.codes.contains(code) else {
                    FileLog.write("config: '\(code)' is a built-in — rebind it via [keybindings], skipping this [[position]]")
                    continue
                }
                guard let kind = parseKind(name: code, table: table) else {
                    FileLog.write("config: skipping '\(code)' — needs a `cell` or a valid `action`")
                    continue
                }
                let category = table["category"]?.string.flatMap { $0.isEmpty ? nil : $0 }
                var key: Keybinding?
                if let keyStr = table["key"]?.string {
                    if let kb = KeyParser.keybinding(from: keyStr) {
                        key = kb
                    } else {
                        FileLog.write("config: '\(code)' has unparseable key '\(keyStr)' — leaving unbound")
                    }
                }
                customs.append(Position(code: code, name: name, category: category, kind: kind, key: key))
            }
        }

        // Menu order: Basic Layout, then the user's custom categories, then Displays.
        let leading = builtins.filter { $0.category != BuiltinPositions.displaysCategory }
        let trailing = builtins.filter { $0.category == BuiltinPositions.displaysCategory }
        return ShiftConfig(settings: settings, positions: leading + customs + trailing)
    }

    /// "Left Half" → "left-half"  (lowercased, runs of non-alphanumerics → single dash).
    static func slug(_ s: String) -> String {
        let lowered = s.lowercased()
        var out = ""
        var lastWasDash = false
        for ch in lowered {
            if ch.isLetter || ch.isNumber {
                out.append(ch)
                lastWasDash = false
            } else if !lastWasDash {
                out.append("-")
                lastWasDash = true
            }
        }
        return out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    /// "left-half" → "Left Half"  (separators → spaces, each word capitalized).
    static func humanize(_ s: String) -> String {
        s.split(whereSeparator: { $0 == "-" || $0 == "_" || $0 == " " })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private static func parseKind(name: String, table: TOMLTable) -> PositionKind? {
        if let action = table["action"]?.string {
            return kind(forAction: action)
        }
        if let cellArr = table["cell"]?.array, cellArr.count == 4 {
            let nums = (0..<4).map { cellArr[$0].int }
            if let x = nums[0], let y = nums[1], let w = nums[2], let h = nums[3] {
                return .cell(CellRect(x: x, y: y, w: w, h: h))
            }
        }
        return nil
    }

    static func kind(forAction action: String) -> PositionKind? {
        switch action.lowercased().replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "_", with: "") {
        case "maximize", "max", "fullscreen": return .maximize
        case "center", "centre":              return .center
        case "restore":                       return .restore
        case "nextdisplay":                   return .nextDisplay
        case "previousdisplay", "prevdisplay": return .previousDisplay
        default:                              return nil
        }
    }

    private static func number(_ value: TOMLValueConvertible?) -> CGFloat? {
        if let d = value?.double { return CGFloat(d) }
        if let i = value?.int { return CGFloat(i) }
        return nil
    }
}
