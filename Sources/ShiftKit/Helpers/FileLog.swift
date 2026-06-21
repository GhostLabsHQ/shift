import Foundation

/// Lightweight debug log at ~/shift-debug.log (DEBUG builds only).
enum FileLog {
    private static let logURL = URL(fileURLWithPath: "\(NSHomeDirectory())/shift-debug.log")

    static func write(_ message: String) {
        #if DEBUG
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let fh = try? FileHandle(forWritingTo: logURL) {
            fh.seekToEndOfFile()
            fh.write(data)
            fh.closeFile()
        } else {
            try? data.write(to: logURL)
        }
        #endif
    }
}
