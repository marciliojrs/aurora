import CoreGraphics
import Foundation

// The breathing presets, ``AuroraSize/pulseInward`` and ``AuroraSize/pulseOutward``.
//
// Nothing travels here. The same nine perimeter blobs the sweeping presets use are instead *breathed*
// in place by the oscillators in ``PulseDriver``: three independent size and drift regions, four
// per-quadrant opacities, and one global height, all on desynced periods. The hue sweeps a full circle
// rather than drifting, so no color stays parked on one edge.
//
// The two presets differ in where the glow lands:
//
// - `pulseInward` keeps everything clipped inside the content, so the card glows from within.
// - `pulseOutward` puts the core and halo *behind* the content and lets them spill past the bounds,
//   with only a hairline on top. It therefore needs an opaque wrapped view — a translucent one shows
//   the halo through its middle and the effect reads as a smear.

extension AuroraSceneBuilder {
    func pulseScene(contentSize: CGSize, time: Double, activation: Double) -> AuroraScene {
        guard let themeTuning = tuning.pulse.themeTuning(
            for: configuration.size,
            theme: configuration.theme
        ) else {
            return .empty(contentSize: contentSize, cornerRadius: configuration.cornerRadius(for: contentSize))
        }

        // Snapping to the tuned sample rate rebuilds the gradient stack 30× a second instead of once
        // per display refresh — invisible at these periods, and a quarter of the work on a 120 Hz
        // display.
        let sampledTime = PulseDriver.quantize(
            time: time,
            sampleRate: tuning.defaults.pulseSampleRate
        )
        let driver = PulseDriver(
            tuning: themeTuning,
            durationScale: configuration.duration / tuning.pulseReferenceDuration,
            staticColors: configuration.staticColors
        )
        let oscillators = driver.frame(at: sampledTime)
        let adjustment = configuration.colorAdjustment(
            hueOffsetDegrees: oscillators.hueRotationDegrees
        )

        if configuration.size == .pulseInward {
            return containedScene(
                contentSize: contentSize, oscillators: oscillators, themeTuning: themeTuning,
                adjustment: adjustment, activation: activation
            )
        }
        return outwardScene(
            contentSize: contentSize, oscillators: oscillators, themeTuning: themeTuning,
            adjustment: adjustment, activation: activation
        )
    }

    // MARK: - Contained glow

    private func containedScene(
        contentSize: CGSize,
        oscillators: PulseDriver.Frame,
        themeTuning: PulseThemeTuning,
        adjustment: AuroraColorMatrix,
        activation: Double
    ) -> AuroraScene {
        let pulse = tuning.pulse
        let bounds = contentRect(contentSize)
        let radius = configuration.cornerRadius(for: contentSize)
        let thickness = configuration.borderWidth
        let unitScale = CGSize(width: 1, height: 1)

        var layers: [AuroraLayer] = []

        // The host's outline, steady: neither of these families has an angular head for it to follow.
        if let border = borderLayer(contentSize: contentSize, activation: activation) {
            layers.append(border)
        }

        // 1. Inward glow: the perimeter blobs at reduced sizes, plus a bright accent in each corner.
        //    The corners matter more than they look — without them the four quadrant oscillators have
        //    nothing to anchor to, and the breathing reads as a vague wobble rather than light moving
        //    around the frame.
        var innerGradients = perimeterBlobs(
            radii: pulse.innerGlowSizes,
            oscillators: oscillators,
            adjustment: adjustment
        )
        innerGradients.append(
            contentsOf: cornerAccents(oscillators: oscillators, adjustment: adjustment)
        )
        layers.append(
            AuroraLayer(
                gradients: innerGradients,
                clip: .roundedRectangle(cornerRadius: radius),
                mask: .edgeBand(inset: tuning.rotate.innerEdgeInset),
                opacity: configuration.clampedOpacity(configuration.innerOpacity, activation: activation),
                frame: bounds
            )
        )

        // 2. The ring: the same blobs at full size, isolated to the border band.
        layers.append(
            AuroraLayer(
                gradients: perimeterBlobs(
                    radii: nil, oscillators: oscillators, adjustment: adjustment
                ),
                clip: .ring(cornerRadius: radius, thickness: thickness),
                opacity: configuration.clampedOpacity(configuration.strokeOpacity, activation: activation),
                frame: bounds
            )
        )

        // 3. The bloom, painted into the same thin ring and then blurred outward.
        layers.append(
            AuroraLayer(
                gradients: frozenBlobs(
                    pulse.innerBloom,
                    alpha: themeTuning.frozenBloomAlpha,
                    glowScale: unitScale,
                    adjustment: adjustment
                ),
                clip: .ring(cornerRadius: radius, thickness: thickness),
                blurRadius: tuning.rotate.bloomBlurRadius,
                opacity: configuration.clampedOpacity(configuration.bloomOpacity, activation: activation),
                frame: bounds
            )
        )

        return AuroraScene(
            contentSize: contentSize,
            cornerRadius: radius,
            layers: layers.filter { $0.isVisible }
        )
    }

    // MARK: - Outward halo

    private func outwardScene(
        contentSize: CGSize,
        oscillators: PulseDriver.Frame,
        themeTuning: PulseThemeTuning,
        adjustment: AuroraColorMatrix,
        activation: Double
    ) -> AuroraScene {
        let pulse = tuning.pulse
        let bounds = contentRect(contentSize)
        let radius = configuration.cornerRadius(for: contentSize)
        let isDark = configuration.theme.isDark
        let glowScale = outwardGlowScale(for: contentSize)
        let coreBlur = isDark ? Self.outwardCoreBlurDark : Self.outwardCoreBlurLight
        let bloomBlur = isDark ? Self.outwardBloomBlurDark : Self.outwardBloomBlurLight

        var layers: [AuroraLayer] = []

        // The host's outline, steady: neither of these families has an angular head for it to follow.
        if let border = borderLayer(contentSize: contentSize, activation: activation) {
            layers.append(border)
        }

        // 1. The wide halo, furthest back. Its blobs are frozen at the time-average of their breathing
        //    range so this heavily blurred layer can be rasterized once and reused — it is by far the
        //    most expensive layer to redraw, and under 22pt of blur nobody can see it breathe anyway.
        layers.append(
            AuroraLayer(
                gradients: frozenBlobs(
                    pulse.outerBloom,
                    alpha: themeTuning.frozenBloomAlpha,
                    glowScale: glowScale,
                    adjustment: adjustment
                ),
                clip: .roundedRectangle(cornerRadius: radius + Self.outwardBloomInset),
                blurRadius: bloomBlur,
                opacity: configuration.clampedOpacity(configuration.bloomOpacity, activation: activation),
                frame: bounds.insetBy(dx: -Self.outwardBloomInset, dy: -Self.outwardBloomInset),
                scale: Self.outwardGlowSquash,
                placement: .behindContent
            )
        )

        // 2. The tighter, live core just outside the edge.
        layers.append(
            AuroraLayer(
                gradients: liveBlobs(
                    pulse.outerCore,
                    oscillators: oscillators,
                    glowScale: glowScale,
                    adjustment: adjustment
                ),
                clip: .roundedRectangle(cornerRadius: radius + Self.outwardCoreInset),
                blurRadius: coreBlur,
                opacity: configuration.clampedOpacity(configuration.innerOpacity, activation: activation),
                frame: bounds.insetBy(dx: -Self.outwardCoreInset, dy: -Self.outwardCoreInset),
                scale: Self.outwardGlowSquash,
                placement: .behindContent
            )
        )

        // 3. The hairline on top. It rides the *inner* edge band rather than just outside it, so it
        //    lands exactly where a view's own 1pt border sits and the two read as one line instead of a
        //    double stroke.
        var strokeGradients = liveBlobs(
            pulse.outerCore,
            oscillators: oscillators,
            glowScale: glowScale,
            adjustment: adjustment
        )
        if configuration.hairlineOpacity > 0 {
            let tint: AuroraColor = isDark ? Self.hairlineTintDark : .black
            strokeGradients.append(.fill(tint.withAlpha(configuration.hairlineOpacity)))
        }
        layers.append(
            AuroraLayer(
                gradients: strokeGradients,
                clip: .ring(cornerRadius: radius, thickness: Self.outwardHairlineThickness),
                opacity: configuration.clampedOpacity(configuration.strokeOpacity, activation: activation),
                frame: bounds,
                placement: .aboveContent
            )
        )

        // The halo must be allowed to escape the bounds, and a Gaussian blur reaches well past the box
        // it was drawn in. Three sigma covers effectively all of it.
        return AuroraScene(
            contentSize: contentSize,
            cornerRadius: radius,
            outset: AuroraOutset(Self.outwardBloomInset + 3 * bloomBlur),
            layers: layers.filter { $0.isVisible }
        )
    }

    /// How far the outward glow's blobs are scaled to fit the wrapped view.
    ///
    /// The blob geometry was tuned against a reference card. Positions stay proportional so they keep
    /// hugging the edges, but the *sizes* scale by how far the real view departs from that reference —
    /// otherwise a wide banner gets the same stubby glow as a small card. The clamp stops a very large
    /// or very small host from producing a halo so far off-scale that it stops looking attached to
    /// anything.
    private func outwardGlowScale(for contentSize: CGSize) -> CGSize {
        func scale(_ measured: Double, reference: Double) -> Double {
            guard reference > 0 else { return 1 }
            let bounds = Self.glowScaleBounds
            return min(max(measured / reference, bounds.lowerBound), bounds.upperBound)
        }
        return CGSize(
            width: scale(contentSize.width, reference: Self.outwardReferenceSize.width),
            height: scale(contentSize.height, reference: Self.outwardReferenceSize.height)
        )
    }

    // MARK: - Blob construction

    /// The nine perimeter blobs, breathing.
    ///
    /// - Parameter radii: Per-blob radius overrides. `nil` uses each palette entry's own radii, which
    ///   is what the ring layer wants; the inward glow passes the smaller tuned set.
    private func perimeterBlobs(
        radii: [CGSize]?,
        oscillators: PulseDriver.Frame,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let palette = tuning.perimeterPalette(configuration.variant, theme: configuration.theme)
        let ringMap = tuning.pulse.ringMap

        return palette.indices.map { index in
            let entry = palette[index]
            let mapping = ringMap[index]
            var width = entry.radii.width.points
            var height = entry.radii.height.points
            if let radii, index < radii.count {
                width = radii[index].width
                height = radii[index].height
            }

            return breathingBlob(
                color: entry.color,
                paletteIndex: index,
                position: entry.position,
                baseWidth: width,
                baseHeight: height,
                region: mapping.region,
                quadrant: mapping.quadrant,
                oscillators: oscillators,
                glowScale: CGSize(width: 1, height: 1),
                adjustment: adjustment
            )
        }
    }

    /// One of the fixed blob tables, breathing.
    private func liveBlobs(
        _ table: [PulseBlob],
        oscillators: PulseDriver.Frame,
        glowScale: CGSize,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let palette = tuning.perimeterPalette(configuration.variant, theme: configuration.theme)
        return table.map { entry in
            let source = palette[entry.paletteIndex]
            return breathingBlob(
                color: source.color,
                paletteIndex: entry.paletteIndex,
                position: entry.position ?? source.position,
                baseWidth: entry.width,
                baseHeight: entry.height,
                region: entry.region,
                quadrant: entry.quadrant,
                oscillators: oscillators,
                glowScale: glowScale,
                adjustment: adjustment
            )
        }
    }

    /// One of the fixed blob tables, frozen at the time-average of its breathing range.
    private func frozenBlobs(
        _ table: [PulseBlob],
        alpha: Double,
        glowScale: CGSize,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let palette = tuning.perimeterPalette(configuration.variant, theme: configuration.theme)
        return table.map { entry in
            let source = palette[entry.paletteIndex]
            return blob(
                color: source.color.withAlpha(alpha),
                at: entry.paletteIndex,
                center: entry.position ?? source.position,
                radii: AuroraSizeSpec.points(
                    width: entry.width * glowScale.width,
                    height: entry.height * glowScale.height
                ),
                adjustment: adjustment
            )
        }
    }

    /// Applies a region's size and drift oscillators plus its quadrant's opacity to one blob.
    ///
    /// - Parameter paletteIndex: Which perimeter blob this is. Carried rather than derived from position
    ///   in the output, so a ``AuroraColorVariant/multiColor(_:)`` hue follows one blob consistently
    ///   across the ring, the inward glow and the corner accents — all three index the same palette.
    private func breathingBlob(
        color: AuroraColor,
        paletteIndex: Int,
        position: AuroraPoint,
        baseWidth: Double,
        baseHeight: Double,
        region: PulseRegion,
        quadrant: PulseQuadrant,
        oscillators: PulseDriver.Frame,
        glowScale: CGSize,
        adjustment: AuroraColorMatrix
    ) -> AuroraGradient {
        let width = baseWidth * oscillators.width(region) * glowScale.width
        let height = baseHeight
            * oscillators.height(region)
            * oscillators.globalHeight
            * glowScale.height

        return blob(
            color: color.withAlpha(color.alpha * oscillators.opacity(quadrant)),
            at: paletteIndex,
            center: AuroraPoint(
                x: position.x.offset(byPoints: oscillators.driftX(region)),
                y: position.y.offset(byPoints: oscillators.driftY(region))
            ),
            radii: AuroraSizeSpec.points(width: width, height: height),
            adjustment: adjustment
        )
    }

    /// The four bright corner accents on the contained glow.
    private func cornerAccents(
        oscillators: PulseDriver.Frame,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let accent = tuning.pulse.cornerAccent
        let baseAlpha = accent.alpha[configuration.theme] ?? 0
        guard baseAlpha > 0 else { return [] }

        let tint = appearanceTint
        let radii = AuroraSizeSpec.points(width: accent.size, height: accent.size)
        let corners: [(x: AuroraLength, y: AuroraLength, quadrant: PulseQuadrant)] = [
            (.percent(0), .percent(0), .topLeading),
            (.percent(100), .percent(0), .topTrailing),
            (.percent(0), .percent(100), .bottomLeading),
            (.percent(100), .percent(100), .bottomTrailing),
        ]

        return corners.map { corner in
            let alpha = baseAlpha * oscillators.opacity(corner.quadrant)
            let color = adjustment.applied(to: tint.withAlpha(alpha))
            return .ellipse(
                AuroraEllipseGradient(
                    center: AuroraPoint(x: corner.x, y: corner.y),
                    radii: radii,
                    stops: [
                        AuroraGradientStop(location: 0, color: color),
                        AuroraGradientStop(location: accent.fadeLocation, color: color.withAlpha(0)),
                        AuroraGradientStop(location: 1, color: color.withAlpha(0)),
                    ]
                )
            )
        }
    }
}

// MARK: - Tuned constants for the outward halo

extension AuroraSceneBuilder {
    /// How far outside the bounds the halo layer is drawn, before blur.
    static let outwardBloomInset: Double = 30
    /// How far outside the bounds the core layer is drawn, before blur.
    static let outwardCoreInset: Double = 10
    static let outwardCoreBlurDark: Double = 3
    static let outwardCoreBlurLight: Double = 6
    static let outwardBloomBlurDark: Double = 22.5
    static let outwardBloomBlurLight: Double = 15
    /// The halo is squashed slightly so it hugs the card rather than ringing it evenly — light pooling
    /// along the edges instead of a uniform outline.
    static let outwardGlowSquash = CGSize(width: 0.95, height: 0.9)
    /// The card the outward blob geometry was tuned against, in points.
    static let outwardReferenceSize = CGSize(width: 350, height: 140)
    static let glowScaleBounds: ClosedRange<Double> = 0.35...4
    static let outwardHairlineThickness: Double = 1
    /// Dark appearances frame with a lifted gray rather than pure white, which would out-shout the glow
    /// it is meant to support.
    static let hairlineTintDark = AuroraColor(r: 70, g: 70, b: 70)
}
