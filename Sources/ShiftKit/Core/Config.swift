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
            if let v = s["columns"]?.int { settings.columns = v }
            if let v = s["rows"]?.int { settings.rows = v }
            settings.gap = number(s["gap"]) ?? settings.gap
            settings.screenGap = number(s["screen_gap"]) ?? settings.screenGap
            if let v = s["menu_icon"]?.string, !v.isEmpty { settings.menuIcon = v }
        }

        var positions: [Position] = []
        if let arr = root["position"]?.array {
            for i in 0..<arr.count {
                guard let table = arr[i].table else { continue }
                guard let name = table["name"]?.string, !name.isEmpty else {
                    FileLog.write("config: skipping position #\(i) with no name")
                    continue
                }
                guard let kind = parseKind(name: name, table: table) else {
                    FileLog.write("config: skipping '\(name)' — needs a `cell` or a valid `action`")
                    continue
                }
                var key: Keybinding?
                if let keyStr = table["key"]?.string {
                    if let kb = KeyParser.keybinding(from: keyStr) {
                        key = kb
                    } else {
                        FileLog.write("config: '\(name)' has unparseable key '\(keyStr)' — leaving unbound")
                    }
                }
                positions.append(Position(name: name, kind: kind, key: key))
            }
        }

        return ShiftConfig(settings: settings, positions: positions)
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
