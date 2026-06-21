import Cocoa
import ShiftKit

// Headless CLI mode for verifying grid geometry without moving any windows:
//   ./Shift --print-grid
if CommandLine.arguments.contains("--print-grid") {
    PrintGrid.run()
    exit(0)
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
delegate.setup()
NSApplication.shared.run()
