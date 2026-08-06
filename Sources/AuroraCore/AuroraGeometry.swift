import CoreGraphics
import Foundation

/// A length that is part fraction of its container and part absolute points.
///
/// The palettes mix the two freely — a blob sits at 100% / 27.1% of the layer but
/// measures `26pt × 42pt` — so resolution has to be deferred until the host's size is
/// known. Keeping both terms in one value means a single `resolved(in:)` call at draw
/// time instead of two parallel code paths.
public struct AuroraLength: Hashable, Sendable {
    /// Fraction of the containing box along the relevant axis (`0.5` is half).
    public var fraction: Double
    /// Absolute offset in points, added after the fractional part.
    public var points: Double

    public init(fraction: Double = 0, points: Double = 0) {
        self.fraction = fraction
        self.points = points
    }

    public static func percent(_ value: Double) -> AuroraLength { AuroraLength(fraction: value / 100) }
    public static func points(_ value: Double) -> AuroraLength { AuroraLength(points: value) }
    public static let zero = AuroraLength()

    public func resolved(in extent: Double) -> Double { fraction * extent + points }

    public func offset(byPoints delta: Double) -> AuroraLength {
        AuroraLength(fraction: fraction, points: points + delta)
    }
}

/// A point expressed in ``AuroraLength`` on both axes.
public struct AuroraPoint: Hashable, Sendable {
    public var x: AuroraLength
    public var y: AuroraLength

    public init(x: AuroraLength, y: AuroraLength) {
        self.x = x
        self.y = y
    }

    public func resolved(in size: CGSize) -> CGPoint {
        CGPoint(x: x.resolved(in: size.width), y: y.resolved(in: size.height))
    }
}

/// A size expressed in ``AuroraLength`` on both axes.
public struct AuroraSizeSpec: Hashable, Sendable {
    public var width: AuroraLength
    public var height: AuroraLength

    public init(width: AuroraLength, height: AuroraLength) {
        self.width = width
        self.height = height
    }

    public static func points(width: Double, height: Double) -> AuroraSizeSpec {
        AuroraSizeSpec(width: .points(width), height: .points(height))
    }

    public func resolved(in size: CGSize) -> CGSize {
        CGSize(width: width.resolved(in: size.width), height: height.resolved(in: size.height))
    }

    /// Scales both terms, which is how the breathing oscillators grow and shrink a blob.
    public func scaled(x: Double, y: Double) -> AuroraSizeSpec {
        AuroraSizeSpec(
            width: AuroraLength(fraction: width.fraction * x, points: width.points * x),
            height: AuroraLength(fraction: height.fraction * y, points: height.points * y)
        )
    }
}

// MARK: - Outset

/// Symmetric outset in points, used by ``AuroraSize/pulseOutward`` whose halo is
/// drawn beyond the host's bounds.
public struct AuroraOutset: Hashable, Sendable {
    public var value: Double

    public init(_ value: Double) { self.value = value }
    public static let zero = AuroraOutset(0)

    /// Expands a rect on all sides. Negative values shrink it.
    public func applied(to rect: CGRect) -> CGRect {
        rect.insetBy(dx: -value, dy: -value)
    }
}
