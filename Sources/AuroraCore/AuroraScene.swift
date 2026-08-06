import CoreGraphics
import Foundation

/// One frame of the effect, described without reference to any UI framework.
///
/// This is the seam between the tuned math and the two renderers. ``AuroraSceneBuilder``
/// produces a scene from a configuration and a timestamp; the SwiftUI and UIKit surfaces
/// only know how to *draw* one. Everything subtle — palettes, oscillators, masks, the
/// color adjustment — is decided here, once, where it can be tested without a view
/// hierarchy or a snapshot.
public struct AuroraScene: Hashable, Sendable {
    /// Size of the wrapped content, in points.
    public var contentSize: CGSize
    /// Corner radius of the wrapped content, in points.
    public var cornerRadius: Double
    /// How far beyond ``contentSize`` this scene paints. Non-zero only for
    /// ``AuroraSize/pulseOutward``, whose halo is meant to escape the bounds.
    public var outset: AuroraOutset
    /// Layers in paint order, back to front.
    public var layers: [AuroraLayer]

    public init(
        contentSize: CGSize,
        cornerRadius: Double,
        outset: AuroraOutset = .zero,
        layers: [AuroraLayer]
    ) {
        self.contentSize = contentSize
        self.cornerRadius = cornerRadius
        self.outset = outset
        self.layers = layers
    }

    /// Layers that belong behind the wrapped content.
    public var layersBehindContent: [AuroraLayer] {
        layers.filter { $0.placement == .behindContent }
    }

    /// Layers that belong in front of the wrapped content.
    public var layersAboveContent: [AuroraLayer] {
        layers.filter { $0.placement == .aboveContent }
    }

    /// An empty scene, for when the host has no size yet or the effect is fully faded
    /// out. Drawing nothing beats drawing a zero-opacity stack.
    public static func empty(contentSize: CGSize, cornerRadius: Double) -> AuroraScene {
        AuroraScene(contentSize: contentSize, cornerRadius: cornerRadius, layers: [])
    }

    public var isEmpty: Bool { layers.isEmpty }
}

// MARK: - Gradient stops

/// One stop of a gradient: a position along the gradient's axis plus a color.
public struct AuroraGradientStop: Hashable, Sendable {
    /// `0...1` along the gradient axis.
    public var location: Double
    public var color: AuroraColor

    public init(location: Double, color: AuroraColor) {
        self.location = location
        self.color = color
    }
}

// MARK: - Layers

/// One composited layer of the effect.
public struct AuroraLayer: Hashable, Sendable {
    /// Whether a layer draws behind or in front of the wrapped content.
    ///
    /// ``AuroraSize/pulseOutward`` needs both: its halo sits behind an opaque card so
    /// only the outward spill shows, while its hairline rides on top so it lines up with
    /// the card's own edge.
    public enum Placement: Hashable, Sendable {
        case behindContent
        case aboveContent
    }

    /// How a layer's drawing is bounded.
    public enum Clip: Hashable, Sendable {
        /// Unbounded within the layer's frame.
        case none
        /// A rounded rectangle.
        case roundedRectangle(cornerRadius: Double)
        /// A rounded-rectangle ring: the outer rounded rect minus an inset one, filled
        /// even-odd. This is how the crisp `borderWidth`-thick stroke is isolated.
        case ring(cornerRadius: Double, thickness: Double)
    }

    /// A soft alpha mask. Composed masks intersect, so each one can only remove coverage.
    public indirect enum Mask: Hashable, Sendable {
        case none
        /// An angular sweep from `startAngleDegrees`, clockwise from the top. Rotating the
        /// start angle is what makes the travel.
        case angularSweep(stops: [AuroraGradientStop], startAngleDegrees: Double)
        /// Reveals a band `inset` points wide along all four edges and hides the middle.
        case edgeBand(inset: Double)
        /// An elliptical falloff, used to reveal only the neighbourhood of the line
        /// preset's traveling head.
        case ellipse(center: AuroraPoint, radii: AuroraSizeSpec, stops: [AuroraGradientStop])
        /// The intersection of several masks.
        case intersection([Mask])
    }

    /// Gradients in paint order, back to front.
    public var gradients: [AuroraGradient]
    public var clip: Clip
    public var mask: Mask
    /// Gaussian blur radius in points, applied to the composited layer.
    public var blurRadius: Double
    /// Final opacity, already clamped and already multiplied by `strength` and the
    /// activation fade.
    public var opacity: Double
    /// An inner shadow drawn inside the clip, if the preset calls for one.
    public var innerShadow: AuroraInnerShadow?
    /// The layer's frame in scene coordinates, where the wrapped content occupies
    /// `CGRect(origin: .zero, size: contentSize)`. Pulse layers extend past it.
    public var frame: CGRect
    /// Non-uniform scale about the frame's center.
    public var scale: CGSize
    public var placement: Placement

    public init(
        gradients: [AuroraGradient],
        clip: Clip = .none,
        mask: Mask = .none,
        blurRadius: Double = 0,
        opacity: Double,
        innerShadow: AuroraInnerShadow? = nil,
        frame: CGRect,
        scale: CGSize = CGSize(width: 1, height: 1),
        placement: Placement = .aboveContent
    ) {
        self.gradients = gradients
        self.clip = clip
        self.mask = mask
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.innerShadow = innerShadow
        self.frame = frame
        self.scale = scale
        self.placement = placement
    }

    /// Whether the layer would contribute anything. Skipping the ones that would not
    /// keeps a faded-out or zero-strength glow from costing a full gradient stack per
    /// frame.
    public var isVisible: Bool {
        opacity > 0.001 && (gradients.isEmpty == false || innerShadow != nil)
    }
}

/// An inner shadow: a soft darkening or lightening hugging the inside of the clip.
public struct AuroraInnerShadow: Hashable, Sendable {
    public var color: AuroraColor
    public var blurRadius: Double
    /// How far the shadow is pushed inward before blurring, in points.
    public var spread: Double

    public init(color: AuroraColor, blurRadius: Double, spread: Double = 1) {
        self.color = color
        self.blurRadius = blurRadius
        self.spread = spread
    }
}

// MARK: - Gradients

/// One gradient in a layer's stack.
public enum AuroraGradient: Hashable, Sendable {
    /// A soft elliptical blob — the effect's fundamental building block. Every palette is
    /// a stack of eight or nine of them placed around the perimeter.
    case ellipse(AuroraEllipseGradient)
    /// An angular sweep from `startAngleDegrees`, clockwise from the top.
    case angularSweep(stops: [AuroraGradientStop], startAngleDegrees: Double)
    /// A flat fill. Used for the constant hairline.
    case fill(AuroraColor)
}

/// A soft elliptical gradient.
public struct AuroraEllipseGradient: Hashable, Sendable {
    /// Center of the ellipse.
    public var center: AuroraPoint
    /// Horizontal and vertical **radii** — not diameters. Reading these as a full extent
    /// halves every blob, which looks nearly right and is entirely wrong.
    public var radii: AuroraSizeSpec
    /// Stops from the center outward.
    public var stops: [AuroraGradientStop]

    public init(center: AuroraPoint, radii: AuroraSizeSpec, stops: [AuroraGradientStop]) {
        self.center = center
        self.radii = radii
        self.stops = stops
    }

    /// A blob fading from `color` at its center to nothing at its edge.
    ///
    /// The trailing stop keeps the color and drops only alpha rather than fading to a
    /// generic clear. Fading to a zeroed color lets the interpolator walk through dark
    /// gray on the way out, leaving a visible dirty halo around every blob.
    public static func blob(
        color: AuroraColor,
        center: AuroraPoint,
        radii: AuroraSizeSpec,
        midStop: AuroraGradientStop? = nil,
        fadeEnd: Double = 1
    ) -> AuroraEllipseGradient {
        var stops = [AuroraGradientStop(location: 0, color: color)]
        if let midStop {
            stops.append(midStop)
        }
        stops.append(AuroraGradientStop(location: fadeEnd, color: color.withAlpha(0)))
        if fadeEnd < 1 {
            stops.append(AuroraGradientStop(location: 1, color: color.withAlpha(0)))
        }
        return AuroraEllipseGradient(center: center, radii: radii, stops: stops)
    }
}
