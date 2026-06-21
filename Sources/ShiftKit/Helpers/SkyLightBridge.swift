import Foundation
import CoreGraphics

// MARK: - SkyLight Private API Bridge (runtime loaded)
// Loaded at runtime via dlopen/dlsym to avoid a linker dependency on a private
// framework. Used to move AX-less windows (Electron/Catalyst apps that don't
// expose Accessibility window attributes).

private let skylight: UnsafeMutableRawPointer? = {
    dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)
}()

private func sym<T>(_ name: String, _ type: T.Type) -> T? {
    guard let handle = skylight, let s = dlsym(handle, name) else { return nil }
    return unsafeBitCast(s, to: T.self)
}

private typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
private typealias SLSMoveWindowFunc = @convention(c) (Int32, UInt32, UnsafePointer<CGPoint>) -> CGError
private typealias SLSGetWindowBoundsFunc = @convention(c) (Int32, UInt32, UnsafeMutablePointer<CGRect>) -> CGError

private let _SLSMainConnectionID = sym("SLSMainConnectionID", SLSMainConnectionIDFunc.self)
private let _SLSMoveWindow = sym("SLSMoveWindow", SLSMoveWindowFunc.self)
private let _SLSGetWindowBounds = sym("SLSGetWindowBounds", SLSGetWindowBoundsFunc.self)

enum SkyLight {
    private static let cid: Int32 = _SLSMainConnectionID?() ?? 0

    static var isAvailable: Bool { skylight != nil && cid != 0 }

    static func getBounds(windowID: UInt32) -> CGRect? {
        guard let fn = _SLSGetWindowBounds else { return nil }
        var bounds = CGRect.zero
        return fn(cid, windowID, &bounds) == .success ? bounds : nil
    }

    static func moveWindow(windowID: UInt32, to point: CGPoint) -> Bool {
        guard let fn = _SLSMoveWindow else { return false }
        var p = point
        return fn(cid, windowID, &p) == .success
    }

    /// Largest standard window for a PID, with its CGWindow id and bounds (CG coords).
    static func findMainWindowWithBounds(pid: pid_t) -> (wid: UInt32, bounds: CGRect)? {
        let windows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []
        var best: (wid: UInt32, bounds: CGRect)?
        var bestArea: CGFloat = 0
        for info in windows {
            guard let wPid = info[kCGWindowOwnerPID as String] as? pid_t, wPid == pid,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let widNum = info[kCGWindowNumber as String] as? Int,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            let w = bounds["Width"] ?? 0, h = bounds["Height"] ?? 0
            let area = w * h
            if w > 50 && h > 50 && area > bestArea {
                bestArea = area
                best = (UInt32(widNum), CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0, width: w, height: h))
            }
        }
        return best
    }
}
