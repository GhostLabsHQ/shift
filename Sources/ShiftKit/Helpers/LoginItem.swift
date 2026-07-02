import Foundation
import ServiceManagement

/// Launch-at-login backed by SMAppService (macOS 13+). Registers the main app
/// bundle as a login item — works with an ad-hoc signed app, no Developer ID.
enum LoginItem {
    @available(macOS 13.0, *)
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @available(macOS 13.0, *)
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            FileLog.write("login item toggle failed: \(error)")
        }
    }
}
