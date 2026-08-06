import Foundation

/// A 5×4 color matrix in the layout `SwiftUI.ColorMatrix` and `CIColorMatrix` share:
/// each output channel is a weighted sum of the four input channels plus a bias.
///
/// This type exists to avoid a fidelity trap. The tuned effect adjusts each layer
/// with a hue rotation, a brightness multiply and a saturation change, applied to the
/// **already-composited layer**. Reaching for the obvious SwiftUI equivalents gets two
/// things wrong:
///
/// - `.brightness(_:)` is an *additive* shift; the tuning needs a multiply.
/// - `.hueRotation(_:)` is a true HSB rotation; the tuning assumes the
///   luminance-preserving matrix below, which moves colors along a different path.
///
/// Chaining view modifiers also filters once per modifier rather than once over the
/// finished layer, so overlapping gradients pick up compounding error.
///
/// So the core composes the exact matrices here and each renderer applies the single
/// result to a composited layer. Both renderers then produce identical color, and the
/// math is testable with no view hierarchy in sight.
public struct AuroraColorMatrix: Hashable, Sendable {
    /// Row-major 4×5: `[r1…r5, g1…g5, b1…b5, a1…a5]`.
    public var values: [Double]

    public init(values: [Double]) {
        precondition(values.count == 20, "A color matrix needs exactly 20 coefficients")
        self.values = values
    }

    public static let identity = AuroraColorMatrix(values: [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
    ])

    public var isIdentity: Bool { self == .identity }

    // MARK: Primitives

    /// A luminance-preserving hue rotation.
    ///
    /// The coefficients weight the channels by their contribution to perceived
    /// luminance (0.213 / 0.715 / 0.072), which is what keeps a rotated palette from
    /// changing apparent brightness as it sweeps. The tuning was authored against this
    /// exact matrix, so substituting an HSB rotation shifts every color.
    public static func hueRotation(degrees: Double) -> AuroraColorMatrix {
        let radians = degrees * .pi / 180
        let c = cos(radians)
        let s = sin(radians)
        return AuroraColorMatrix(values: [
            0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928, 0, 0,
            0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283, 0, 0,
            0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072, 0, 0,
            0, 0, 0, 1, 0,
        ])
    }

    /// A multiplicative brightness adjustment. Alpha is untouched.
    public static func brightness(_ amount: Double) -> AuroraColorMatrix {
        AuroraColorMatrix(values: [
            amount, 0, 0, 0, 0,
            0, amount, 0, 0, 0,
            0, 0, amount, 0, 0,
            0, 0, 0, 1, 0,
        ])
    }

    /// A saturation adjustment. `0` is fully desaturated, `1` is unchanged.
    public static func saturation(_ amount: Double) -> AuroraColorMatrix {
        let a = amount
        return AuroraColorMatrix(values: [
            0.213 + 0.787 * a, 0.715 - 0.715 * a, 0.072 - 0.072 * a, 0, 0,
            0.213 - 0.213 * a, 0.715 + 0.285 * a, 0.072 - 0.072 * a, 0, 0,
            0.213 - 0.213 * a, 0.715 - 0.715 * a, 0.072 + 0.928 * a, 0, 0,
            0, 0, 0, 1, 0,
        ])
    }

    // MARK: Composition

    /// Returns the matrix equivalent to applying `self` first, then `later`.
    public func concatenated(with later: AuroraColorMatrix) -> AuroraColorMatrix {
        var result = [Double](repeating: 0, count: 20)
        for row in 0..<4 {
            for column in 0..<4 {
                var sum = 0.0
                for k in 0..<4 {
                    sum += later.values[row * 5 + k] * values[k * 5 + column]
                }
                result[row * 5 + column] = sum
            }
            // Bias column: `later`'s own bias, plus its weighting of `self`'s biases.
            var bias = later.values[row * 5 + 4]
            for k in 0..<4 {
                bias += later.values[row * 5 + k] * values[k * 5 + 4]
            }
            result[row * 5 + 4] = bias
        }
        return AuroraColorMatrix(values: result)
    }

    /// The full color adjustment a layer carries, composed in the tuned order:
    /// hue rotation, then brightness, then saturation.
    ///
    /// Blur is deliberately absent. It is a spatial effect, not a color one, so each
    /// renderer applies it to the layer instead — `.blur(radius:)` in SwiftUI, a layer
    /// filter in UIKit.
    public static func adjustment(
        hueRotationDegrees: Double,
        brightness brightnessAmount: Double,
        saturation saturationAmount: Double
    ) -> AuroraColorMatrix {
        hueRotation(degrees: hueRotationDegrees)
            .concatenated(with: brightness(brightnessAmount))
            .concatenated(with: saturation(saturationAmount))
    }

    // MARK: Application

    /// Applies the matrix to a single color.
    ///
    /// Renderers apply it to a composited layer instead. This exists so the math can be
    /// asserted directly in tests, and for the occasional flat-colored layer.
    public func applied(to color: AuroraColor) -> AuroraColor {
        AuroraColor(
            red: channel(0, of: color),
            green: channel(1, of: color),
            blue: channel(2, of: color),
            alpha: channel(3, of: color)
        )
    }

    private func channel(_ row: Int, of color: AuroraColor) -> Double {
        let base = row * 5
        var sum = values[base] * color.red
        sum += values[base + 1] * color.green
        sum += values[base + 2] * color.blue
        sum += values[base + 3] * color.alpha
        return sum + values[base + 4]
    }
}
