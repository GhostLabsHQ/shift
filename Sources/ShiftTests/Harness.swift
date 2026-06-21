import Foundation

/// A tiny dependency-free assertion harness. Runs under the Command Line Tools
/// toolchain (no XCTest / swift-testing needed). `swift run ShiftTests` exits
/// non-zero if any check fails.
final class TestReport {
    static let shared = TestReport()
    private(set) var passed = 0
    private(set) var failed = 0
    private var current = ""

    func suite(_ name: String) {
        current = name
        print("• \(name)")
    }

    func ok(_ condition: Bool, _ message: String, line: Int = #line) {
        if condition {
            passed += 1
        } else {
            failed += 1
            print("  ✗ [\(current)] \(message)  (line \(line))")
        }
    }

    func equal<T: Equatable>(_ got: T, _ want: T, _ message: String, line: Int = #line) {
        ok(got == want, "\(message) — got \(got), want \(want)", line: line)
    }

    func throwsError(_ message: String, line: Int = #line, _ body: () throws -> Void) {
        do {
            try body()
            ok(false, "\(message) — expected an error but none was thrown", line: line)
        } catch {
            passed += 1
        }
    }

    /// Catch-and-fail wrapper for blocks that should succeed.
    func noThrow(_ message: String, line: Int = #line, _ body: () throws -> Void) {
        do { try body() } catch { ok(false, "\(message) — unexpected error: \(error)", line: line) }
    }

    func finish() -> Never {
        print("\n\(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}

let R = TestReport.shared
