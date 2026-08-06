import AuroraCore
import SwiftUI

// Draws a ``AuroraScene`` into a `GraphicsContext`.
//
// Kept as an extension on `GraphicsContext` rather than as a type, because there is no
// state to hold: a scene is already a finished description of a frame, so drawing it is a
// pure traversal. Everything that needed a decision was decided in `AuroraCore`.

extension GraphicsContext {
    /// Draws one layer.
    ///
    /// `sceneOffset` shifts scene coordinates into canvas coordinates, which is non-zero
    /// whenever the scene is allowed to paint outside the content's bounds.
    func render(_ layer: AuroraLayer, sceneOffset: CGSize) {
        let frame = layer.frame.offsetBy(dx: sceneOffset.width, dy: sceneOffset.height)
        guard frame.width > 0, frame.height > 0 else { return }

        drawLayer { context in
            context.applyScale(layer.scale, about: frame)
            context.applyMask(layer.mask, in: frame)
            context.applyClip(layer.clip, in: frame)

            for gradient in layer.gradients {
                context.drawGradient(gradient, in: frame)
            }
            if let shadow = layer.innerShadow {
                context.drawInnerShadow(shadow, clip: layer.clip, in: frame)
            }
        }
    }
}

// MARK: - Transform

extension GraphicsContext {
    /// Scales about a rect's center, which is where the pulse halo's slight squash comes
    /// from.
    fileprivate mutating func applyScale(_ scale: CGSize, about rect: CGRect) {
        guard scale != CGSize(width: 1, height: 1) else { return }
        translateBy(x: rect.midX, y: rect.midY)
        scaleBy(x: scale.width, y: scale.height)
        translateBy(x: -rect.midX, y: -rect.midY)
    }
}

// MARK: - Clipping

extension GraphicsContext {
    fileprivate mutating func applyClip(_ clip: AuroraLayer.Clip, in rect: CGRect) {
        switch clip {
        case .none:
            break
        case .roundedRectangle(let cornerRadius):
            self.clip(to: Path.continuousRoundedRectangle(rect, cornerRadius: cornerRadius))
        case .ring(let cornerRadius, let thickness):
            // An even-odd fill of two nested rounded rectangles leaves exactly the band
            // between them. That is what isolates the crisp `thickness`-thick stroke; a
            // stroked path would work at wider widths but its joins do not follow a
            // continuous corner curve cleanly at 1pt.
            self.clip(
                to: Path.ring(rect, cornerRadius: cornerRadius, thickness: thickness),
                style: FillStyle(eoFill: true)
            )
        }
    }
}

extension Path {
    /// A rounded rectangle using the continuous corner curve, so the glow's corners match a
    /// `RoundedRectangle(cornerRadius:style: .continuous)` the caller has most likely used
    /// on the content itself.
    static func continuousRoundedRectangle(_ rect: CGRect, cornerRadius: Double) -> Path {
        let limit = min(rect.width, rect.height) / 2
        let radius = min(max(cornerRadius, 0), limit)
        return Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
    }

    /// The band between a rounded rectangle and an inset copy of it. Fill even-odd.
    static func ring(_ rect: CGRect, cornerRadius: Double, thickness: Double) -> Path {
        var path = continuousRoundedRectangle(rect, cornerRadius: cornerRadius)
        let inner = rect.insetBy(dx: thickness, dy: thickness)
        guard inner.width > 0, inner.height > 0 else { return path }
        path.addPath(continuousRoundedRectangle(inner, cornerRadius: cornerRadius - thickness))
        return path
    }
}

// MARK: - Masking

extension GraphicsContext {
    /// Applies a mask by clipping to the alpha of a drawn layer.
    ///
    /// Composed masks are applied as successive clips rather than being merged into one
    /// image, because clipping intersects — exactly the semantics
    /// ``AuroraLayer/Mask/intersection(_:)`` describes — and it avoids allocating an
    /// intermediate mask every frame.
    fileprivate mutating func applyMask(_ mask: AuroraLayer.Mask, in rect: CGRect) {
        switch mask {
        case .none:
            break
        case .intersection(let masks):
            for nested in masks {
                applyMask(nested, in: rect)
            }
        case .angularSweep(let stops, let startAngleDegrees):
            clipToLayer { context in
                context.drawAngularSweep(
                    stops: stops,
                    startAngleDegrees: startAngleDegrees,
                    in: rect
                )
            }
        case .ellipse(let center, let radii, let stops):
            clipToLayer { context in
                context.drawEllipse(center: center, radii: radii, stops: stops, in: rect)
            }
        case .edgeBand(let inset):
            clipToLayer { context in
                context.drawEdgeBand(inset: inset, in: rect)
            }
        }
    }

    /// Reveals a band along all four edges and hides the middle.
    ///
    /// Built from two opposing linear gradients combined with `.plusLighter`, so coverage is
    /// the *union* of the vertical and horizontal bands. Intersecting them instead would
    /// leave only the corners lit.
    fileprivate func drawEdgeBand(inset: Double, in rect: CGRect) {
        guard rect.width > 0, rect.height > 0 else { return }
        let path = Path(rect)

        fill(
            path,
            with: .linearGradient(
                Gradient(stops: Self.edgeBandStops(edgeStop: min(inset / rect.height, 0.5))),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            )
        )

        var additive = self
        additive.blendMode = .plusLighter
        additive.fill(
            path,
            with: .linearGradient(
                Gradient(stops: Self.edgeBandStops(edgeStop: min(inset / rect.width, 0.5))),
                startPoint: CGPoint(x: rect.minX, y: rect.midY),
                endPoint: CGPoint(x: rect.maxX, y: rect.midY)
            )
        )
    }

    private static func edgeBandStops(edgeStop: Double) -> [Gradient.Stop] {
        [
            Gradient.Stop(color: .white, location: 0),
            Gradient.Stop(color: .clear, location: edgeStop),
            Gradient.Stop(color: .clear, location: 1 - edgeStop),
            Gradient.Stop(color: .white, location: 1),
        ]
    }
}

// MARK: - Gradients

extension GraphicsContext {
    fileprivate func drawGradient(_ gradient: AuroraGradient, in rect: CGRect) {
        switch gradient {
        case .ellipse(let ellipse):
            drawEllipse(
                center: ellipse.center,
                radii: ellipse.radii,
                stops: ellipse.stops,
                in: rect
            )
        case .angularSweep(let stops, let startAngleDegrees):
            drawAngularSweep(stops: stops, startAngleDegrees: startAngleDegrees, in: rect)
        case .fill(let color):
            fill(Path(rect), with: .color(Color(aurora: color)))
        }
    }

    /// Draws a soft elliptical blob.
    ///
    /// A radial gradient is circular by definition, so the ellipse comes from drawing a
    /// *unit* circle into a context scaled by the two radii. Scaling the geometry rather
    /// than stretching a circular gradient in place keeps the falloff even along both axes.
    fileprivate func drawEllipse(
        center: AuroraPoint,
        radii: AuroraSizeSpec,
        stops: [AuroraGradientStop],
        in rect: CGRect
    ) {
        let resolved = radii.resolved(in: rect.size)
        guard resolved.width > 0.01, resolved.height > 0.01, stops.isEmpty == false else { return }
        let origin = center.resolved(in: rect.size)

        drawLayer { context in
            context.translateBy(x: rect.minX + origin.x, y: rect.minY + origin.y)
            context.scaleBy(x: resolved.width, y: resolved.height)
            context.fill(
                Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                with: .radialGradient(
                    Gradient(auroraStops: stops),
                    center: .zero,
                    startRadius: 0,
                    endRadius: 1
                )
            )
        }
    }

    /// Draws an angular sweep across the rect, measured clockwise from the top.
    fileprivate func drawAngularSweep(
        stops: [AuroraGradientStop],
        startAngleDegrees: Double,
        in rect: CGRect
    ) {
        guard stops.isEmpty == false else { return }
        fill(
            Path(rect),
            with: .conicGradient(
                Gradient(auroraStops: stops),
                center: CGPoint(x: rect.midX, y: rect.midY),
                angle: .degrees(startAngleDegrees)
            )
        )
    }
}

// MARK: - Inner shadow

extension GraphicsContext {
    /// Draws a soft shadow hugging the inside of the clip shape.
    ///
    /// Implemented by stroking the clip path with a wide, blurred line: half the stroke
    /// falls outside the shape and is clipped away, leaving a gradient that fades inward.
    /// Cheaper and sharper at the corners than blurring a filled inverse shape.
    fileprivate func drawInnerShadow(
        _ shadow: AuroraInnerShadow,
        clip: AuroraLayer.Clip,
        in rect: CGRect
    ) {
        guard shadow.color.alpha > 0, shadow.blurRadius > 0 else { return }

        let cornerRadius: Double
        switch clip {
        case .roundedRectangle(let radius): cornerRadius = radius
        case .ring(let radius, _): cornerRadius = radius
        case .none: cornerRadius = 0
        }
        let path = Path.continuousRoundedRectangle(rect, cornerRadius: cornerRadius)

        var context = self
        context.clip(to: path)
        context.addFilter(.blur(radius: shadow.blurRadius))
        context.stroke(
            path,
            with: .color(Color(aurora: shadow.color)),
            lineWidth: shadow.blurRadius * 2 + shadow.spread
        )
    }
}
