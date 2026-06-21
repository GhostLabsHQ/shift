import Cocoa
import ApplicationServices

final class AccessibilityHelper {
    static let shared = AccessibilityHelper()
    private var pollTimer: Timer?

    var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    /// Trigger the system Accessibility prompt, then poll until granted.
    func requestAccessAndPoll(completion: @escaping (Bool) -> Void) {
        if isAccessibilityGranted { completion(true); return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            completion(true)
        } else {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self?.pollTimer = nil
                    completion(true)
                }
            }
        }
    }
}
