import Cocoa
import ApplicationServices

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController!
    private var didSetup = false

    public override init() {
        super.init()
    }

    public func setup() {
        guard !didSetup else { return }
        didSetup = true

        // Menu-bar agent: no Dock icon (belt-and-suspenders alongside LSUIElement).
        NSApp.setActivationPolicy(.accessory)

        // Load config (seeding ~/.config/shift/config.toml with defaults on first run).
        Config.shared.loadOrSeed()

        _ = DisplayHelper.shared
        statusBar = StatusBarController()
        statusBar.setup()

        // Auto-reload on config file changes.
        Config.shared.startWatching {
            Config.shared.reload()
            HotkeyManager.shared.reload()
        }

        if AXIsProcessTrusted() {
            HotkeyManager.shared.start()
        } else {
            AccessibilityHelper.shared.requestAccessAndPoll { granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    HotkeyManager.shared.start()
                }
            }
        }
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setup()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
        Config.shared.stopWatching()
    }
}
