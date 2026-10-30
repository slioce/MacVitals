// swift-tools-version: 6.0
import PackageDescription

// The system readings and their formatting, kept apart from the app so they can be tested with `swift test` alone.
let package = Package(
    name: "MacVitalsCore",
    platforms: [.macOS(.v15)],
    products: [.library(name: "MacVitalsCore", targets: ["MacVitalsCore"])],
    targets: [
        .target(name: "MacVitalsCore"),
        .testTarget(name: "MacVitalsCoreTests", dependencies: ["MacVitalsCore"]),
    ]
)
