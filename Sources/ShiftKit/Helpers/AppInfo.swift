import Foundation

enum AppInfo {
    /// A short version label for display, e.g. "v0.1.0" from the packaged app
    /// bundle's CFBundleShortVersionString. Falls back to "dev" when there is no
    /// versioned bundle (e.g. running via `swift run`).
    static var versionLabel: String {
        if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !v.trimmingCharacters(in: .whitespaces).isEmpty {
            return "v\(v)"
        }
        return "dev"
    }
}
