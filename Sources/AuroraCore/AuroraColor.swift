import CoreGraphics

/// A straight (non-premultiplied) color with components in `0...1`.
///
/// The palettes are pure data, so the core keeps its own small color type instead of
/// reaching for `SwiftUI.Color` or `UIColor`. That is what allows ``AuroraSceneBuilder``
/// to stay free of any UI framework import — the same builder feeds the SwiftUI and
/// UIKit renderers — and it makes the palette math directly testable.
public struct AuroraColor: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Initializes from 8-bit components, the form every palette entry uses.
    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    public static let clear = AuroraColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let white = AuroraColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = AuroraColor(red: 0, green: 0, blue: 0, alpha: 1)

    /// The same color with a replaced alpha.
    public func withAlpha(_ alpha: Double) -> AuroraColor {
        AuroraColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// The same color with its alpha scaled.
    public func scalingAlpha(by factor: Double) -> AuroraColor {
        withAlpha(alpha * factor)
    }

    /// The same color with its channels scaled, alpha untouched.
    ///
    /// A multiply rather than a subtraction, so a grey stays neutral: halving `rgb(180, 180, 180)`
    /// gives `rgb(90, 90, 90)`. Subtracting a constant happens to be equivalent for greys but would
    /// skew a colored value toward whichever channel was smallest.
    public func scalingBrightness(by factor: Double) -> AuroraColor {
        AuroraColor(red: red * factor, green: green * factor, blue: blue * factor, alpha: alpha)
    }
}

// MARK: - Core Graphics bridging

extension CGColor {
    /// Bridges to Core Graphics in extended sRGB.
    ///
    /// Extended rather than plain sRGB: several presets drive brightness above 1, which
    /// pushes components past 1.0, and clamping them this early visibly dulls the bloom.
    public static func aurora(_ color: AuroraColor) -> CGColor {
        let space = CGColorSpace(name: CGColorSpace.extendedSRGB) ?? CGColorSpaceCreateDeviceRGB()
        let components: [CGFloat] = [
            CGFloat(color.red),
            CGFloat(color.green),
            CGFloat(color.blue),
            CGFloat(color.alpha),
        ]
        return CGColor(colorSpace: space, components: components) ?? CGColor(gray: 0, alpha: 0)
    }
}
