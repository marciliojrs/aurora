// swift-tools-version: 6.0
import PackageDescription

// Only the component ships. The showcase screens live in Examples/ and are compiled into the demo apps,
// so nobody depending on this package inherits demo code in their graph or their API surface. Previews
// of the component itself live in Sources/Aurora/Previews.swift and Sources/Aurora/UIKitPreviews.swift,
// both inside shipping targets, so they work from this manifest.
let package = Package(
    name: "Aurora",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        // Palettes, oscillators and the renderer-agnostic scene builder. CoreGraphics only — no
        // SwiftUI, no UIKit.
        .library(name: "AuroraCore", targets: ["AuroraCore"]),
        // Both UI surfaces in one module: `Aurora { … }` and `.aurora(…)` for SwiftUI, `AuroraView` and
        // `UIView.addAurora(…)` for UIKit. One product to add, one module to import. The UIKit files are
        // `canImport(UIKit)`-guarded, so they compile away on macOS.
        .library(name: "Aurora", targets: ["Aurora"]),
    ],
    targets: [
        .target(
            name: "AuroraCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "Aurora",
            dependencies: ["AuroraCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "AuroraCoreTests",
            dependencies: ["AuroraCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Rasterizes real frames. The core tests assert what the builder *decides*; these assert that
        // the decisions reach pixels, which is a distinct failure mode — a glow can be perfectly
        // specified and still draw nothing.
        .testTarget(
            name: "AuroraTests",
            dependencies: ["Aurora", "AuroraCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
