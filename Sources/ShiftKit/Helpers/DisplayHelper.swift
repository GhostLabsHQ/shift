import Cocoa

final class DisplayHelper {
    static let shared = DisplayHelper()

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged() {
        NotificationCenter.default.post(name: .displaysChanged, object: nil)
    }

    /// Screen whose frame overlaps `windowFrame` the most.
    func currentScreen(for windowFrame: CGRect) -> NSScreen {
        var maxArea: CGFloat = 0
        var best = NSScreen.main ?? NSScreen.screens.first!
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(windowFrame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                best = screen
            }
        }
        return best
    }

    private var sortedScreens: [NSScreen] {
        NSScreen.screens.sorted { $0.frame.origin.x < $1.frame.origin.x }
    }

    func nextScreen(from current: NSScreen) -> NSScreen? {
        let screens = sortedScreens
        guard screens.count > 1, let idx = screens.firstIndex(of: current) else { return nil }
        return screens[(idx + 1) % screens.count]                 // wraps last → first
    }

    func previousScreen(from current: NSScreen) -> NSScreen? {
        let screens = sortedScreens
        guard screens.count > 1, let idx = screens.firstIndex(of: current) else { return nil }
        return screens[(idx - 1 + screens.count) % screens.count] // wraps first → last
    }
}
