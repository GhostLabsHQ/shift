// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Shift",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "Shift", targets: ["Shift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    ],
    targets: [
        // All app logic lives here so tests can @testable import it.
        .target(
            name: "ShiftKit",
            dependencies: [.product(name: "TOMLKit", package: "TOMLKit")]
        ),
        // Thin entry point.
        .executableTarget(
            name: "Shift",
            dependencies: ["ShiftKit"]
        ),
        // Self-contained test runner — no XCTest/swift-testing, so it runs under
        // the Command Line Tools toolchain with a plain `swift run ShiftTests`.
        .executableTarget(
            name: "ShiftTests",
            dependencies: ["ShiftKit"]
        ),
    ]
)
