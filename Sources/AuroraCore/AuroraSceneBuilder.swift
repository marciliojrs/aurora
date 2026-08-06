import CoreGraphics
import Foundation

/// Turns a configuration and a timestamp into a ``AuroraScene``.
///
/// Deliberately a pure value type with no stored mutable state: the same inputs always produce the
/// same scene. That buys three things worth the discipline — the renderers need no animation state of
/// their own, a frame can be pinned exactly in a test, and honouring Reduce Motion becomes a matter
/// of passing a fixed timestamp rather than a separate code path.
///
/// Each preset family has its own composition, in `AuroraSceneBuilder+Rotate`, `+Line` and `+Pulse`.
public struct AuroraSceneBuilder: Sendable {
    public let configuration: AuroraResolvedConfiguration
    let tuning: Tuning

    public init(configuration: AuroraResolvedConfiguration) {
        self.init(configuration: configuration, tuning: .standard)
    }

    /// Package-scoped for the same reason as `AuroraConfiguration.resolved(isDarkEnvironment:tuning:)`:
    /// nobody outside this package can construct a `Tuning` to hand over.
    package init(configuration: AuroraResolvedConfiguration, tuning: Tuning) {
        self.configuration = configuration
        self.tuning = tuning
    }

    /// Builds the scene for one frame.
    ///
    /// - Parameters:
    ///   - contentSize: Size of the wrapped content, in points.
    ///   - time: Seconds on the host's timeline. Only the phase matters, so any monotonic clock works.
    ///   - activation: The activation fade, `0...1`. See
    ///     ``AuroraTimeline/fadeOpacity(isActive:secondsSinceChange:fadeInSeconds:fadeOutSeconds:)``.
    public func scene(contentSize: CGSize, time: Double, activation: Double) -> AuroraScene {
        guard contentSize.width > 0, contentSize.height > 0,
              activation > 0.001, configuration.strength > 0
        else {
            return .empty(contentSize: contentSize, cornerRadius: configuration.cornerRadius(for: contentSize))
        }

        switch configuration.size.family {
        case .rotate:
            return rotateScene(contentSize: contentSize, time: time, activation: activation)
        case .underline:
            return lineScene(contentSize: contentSize, time: time, activation: activation)
        case .pulse:
            return pulseScene(contentSize: contentSize, time: time, activation: activation)
        }
    }
}

// MARK: - Shared helpers

extension AuroraSceneBuilder {
    /// The wrapped content's rect in scene coordinates.
    func contentRect(_ contentSize: CGSize) -> CGRect {
        CGRect(origin: .zero, size: contentSize)
    }

    /// The tint a mask or highlight uses for the current appearance.
    ///
    /// Dark appearances brighten with white, light appearances deepen with black. Both read as "more
    /// glow", which is why one table of alphas serves both.
    var appearanceTint: AuroraColor {
        configuration.theme.isDark ? .white : .black
    }

    /// Converts a coverage-only stop table into concrete, adjusted stops.
    func gradientStops(
        _ table: [AlphaStop],
        tint: AuroraColor,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradientStop] {
        let tinted = adjustment.applied(to: tint)
        return table.map { AuroraGradientStop(location: $0.location, color: tinted.withAlpha($0.alpha)) }
    }

    /// The host's own outline, drawn beneath the glow when ``AuroraResolvedConfiguration/showsBorder`` is on.
    ///
    /// Returns `nil` when the border is off, so the caller can append it without a branch.
    ///
    /// - Parameter sweepStops: The angular coverage the glow is revealing this frame, if the preset has a
    ///   sweep. Supplied, the outline appears only along that arc and travels with it. Omitted, it is drawn
    ///   steady — the breathing and bottom-edge presets have no angular head to follow, and a steady
    ///   outline is still the right thing rather than a flag that quietly does nothing.
    ///
    ///   Away from the head the outline is *gone*, not merely dimmer. It belongs to the light rather than
    ///   sitting under it, so there is no resting hairline drawing a box around the host. What stops that
    ///   reading as an edge blinking on and off is the shape of the sweep table itself: it ramps across four
    ///   stops either side of the plateau, so the outline arrives and leaves as a soft comet.
    ///
    ///   ``borderRestingAlpha`` is the knob. Raise it above zero to leave a ghost of the full outline
    ///   visible between passes.
    ///
    /// The layer's angle comes from the same `startAngleDegrees` the colored ring uses, which is what keeps
    /// the two arcs locked together. Drifting apart would put two bright heads on one border.
    ///
    /// The color adjustment is deliberately *not* applied. It carries a brightness of 1.3–1.9, and pushing
    /// white past 1 only clips; hue-rotating white does nothing at all.
    func borderLayer(
        contentSize: CGSize,
        activation: Double,
        sweepStops: [AlphaStop]? = nil,
        startAngleDegrees: Double = 0
    ) -> AuroraLayer? {
        guard configuration.showsBorder else { return nil }

        let radius = configuration.cornerRadius(for: contentSize)
        let tint = borderTint

        let gradients: [AuroraGradient]
        if let sweepStops {
            let resting = Self.borderRestingAlpha
            gradients = [
                .angularSweep(
                    stops: sweepStops.map { stop in
                        AuroraGradientStop(
                            location: stop.location,
                            color: tint.withAlpha(resting + (1 - resting) * stop.alpha)
                        )
                    },
                    startAngleDegrees: startAngleDegrees
                )
            ]
        } else {
            // No head to follow, so "only where the light is" has nothing to mean. A steady outline is the
            // honest reading of the flag here — the alternative is drawing nothing at all.
            gradients = [.fill(tint.withAlpha(Self.borderSteadyAlpha))]
        }

        return AuroraLayer(
            gradients: gradients,
            clip: .ring(cornerRadius: radius, thickness: configuration.borderWidth),
            opacity: configuration.clampedOpacity(borderOpacity, activation: activation),
            frame: contentRect(contentSize)
        )
    }

    /// How strongly the traced outline reads, per appearance.
    ///
    /// Lower on light, where a black hairline on a pale surface carries much further than a white one does
    /// on a dark surface.
    private var borderOpacity: Double {
        configuration.theme.isDark ? Self.borderOpacityDark : Self.borderOpacityLight
    }

    /// The outline's own color.
    ///
    /// White on dark, but a mid grey on light rather than the black ``appearanceTint`` gives the masks.
    /// Black is right for *coverage* — it deepens a light surface the way white brightens a dark one — and
    /// wrong for a hairline, where it reads as an outline someone drew rather than as an edge catching the
    /// light. Grey keeps it an edge.
    private var borderTint: AuroraColor {
        configuration.theme.isDark ? .white : Self.borderTintLight
    }

    static let borderTintLight = AuroraColor(r: 120, g: 120, b: 120)

    /// How visible the outline is away from the head, for the presets that have one.
    ///
    /// Barely: enough to hint that the edge is there the whole way round, not enough to read as a box drawn
    /// around the host. The border belongs to the light, and the light is what makes it legible.
    static let borderRestingAlpha = 0.1

    /// The outline's alpha for presets with no angular head. Steady, because there is no arc to confine it
    /// to — see ``borderLayer(contentSize:activation:sweepStops:startAngleDegrees:)``.
    static let borderSteadyAlpha = 0.3

    static let borderOpacityDark = 0.85
    static let borderOpacityLight = 0.6

    /// Converts a coverage-only stop table into mask stops.
    ///
    /// The color adjustment is deliberately *not* applied: a mask carries coverage, not color, and
    /// running a hue rotation over it would tint the coverage and dim the glow.
    func maskStops(_ table: [AlphaStop]) -> [AuroraGradientStop] {
        table.map { AuroraGradientStop(location: $0.location, color: .white.withAlpha($0.alpha)) }
    }

    /// A palette blob with the caller's hue and the layer's color adjustment baked into its stops.
    ///
    /// Baking rather than filtering at draw time is safe because the adjustment matrices are
    /// bias-free and leave alpha untouched, which makes them commute with source-over compositing —
    /// adjusting each source is identical to adjusting the composited result. See ``AuroraColorMatrix``.
    ///
    /// - Parameter index: The blob's position in its own palette table, which is what lets a
    ///   ``AuroraColorVariant/multiColor(_:)`` combination spread across the ring.
    func blob(
        color: AuroraColor,
        at index: Int,
        center: AuroraPoint,
        radii: AuroraSizeSpec,
        adjustment: AuroraColorMatrix
    ) -> AuroraGradient {
        .ellipse(
            .blob(
                color: adjustment.applied(to: recolored(color, at: index)),
                center: center,
                radii: radii
            )
        )
    }

    /// Applies the variant's hue for one palette entry, preserving that entry's brightness.
    ///
    /// Multiplying rather than replacing is what keeps the palette's tuned structure intact: the nine
    /// perimeter blobs differ in brightness on purpose, and that difference is what makes them read as
    /// separate pools of light instead of one flat ring. Substituting the colors outright would collapse
    /// all nine to the same shade.
    ///
    /// A no-op for ``AuroraColorVariant/glow``, which carries its own authored hues.
    func recolored(_ color: AuroraColor, at index: Int) -> AuroraColor {
        guard let hue = configuration.variant.hue(at: index) else { return color }
        // The base palette is achromatic, so its mean channel *is* its brightness.
        let brightness = (color.red + color.green + color.blue) / 3
        return AuroraColor(
            red: hue.red * brightness,
            green: hue.green * brightness,
            blue: hue.blue * brightness,
            alpha: color.alpha * hue.alpha
        )
    }

    /// The hue offset for the presets that drift within a range rather than sweeping a full circle.
    ///
    /// The drift eases to `-range` at the start of its cycle, `+range` halfway through and back, so
    /// ``AuroraTimeline/pingPong(_:)`` maps straight onto it.
    func driftingHueOffset(at time: Double, range: Double, period: Double) -> Double {
        guard configuration.staticColors == false, range != 0, period > 0 else { return 0 }
        let progress = AuroraTimeline.pingPong(AuroraTimeline.phase(at: time, period: period))
        return -range + 2 * range * progress
    }

    /// A soft falloff for a reveal mask: opaque at the center, `softStop`'s alpha partway out, gone at
    /// the edge.
    func softFalloff(_ softStop: AlphaStop) -> [AuroraGradientStop] {
        [
            AuroraGradientStop(location: 0, color: .white),
            AuroraGradientStop(location: softStop.location, color: .white.withAlpha(softStop.alpha)),
            AuroraGradientStop(location: 1, color: .white.withAlpha(0)),
        ]
    }

    /// The inner shadow that seats a glow against the content's edge.
    ///
    /// Returns `nil` for a fully transparent color rather than a zero-alpha shadow, so the renderer
    /// can skip the draw entirely.
    func innerShadow(adjustment: AuroraColorMatrix, blurRadius: Double) -> AuroraInnerShadow? {
        guard configuration.innerShadow.alpha > 0 else { return nil }
        return AuroraInnerShadow(
            color: adjustment.applied(to: configuration.innerShadow),
            blurRadius: blurRadius
        )
    }
}
