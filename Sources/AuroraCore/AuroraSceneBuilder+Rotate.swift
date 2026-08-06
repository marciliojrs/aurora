import CoreGraphics
import Foundation

// The sweeping presets, ``AuroraSize/compact`` and ``AuroraSize/regular``.
//
// The trick worth understanding before reading the code: **nothing actually rotates.** The colored
// perimeter is a static stack of eight or nine soft blobs pinned to the edges and corners. What
// sweeps is an *angular mask* whose start angle advances once per `duration`. It reveals a bright arc
// of that static ring and hides the rest, so the glow appears to travel while the palette stays put.
//
// That is why the palette never has to be re-laid-out per frame, and why the same nine blobs can also
// serve the breathing presets — only the mask differs.

extension AuroraSceneBuilder {
    func rotateScene(contentSize: CGSize, time: Double, activation: Double) -> AuroraScene {
        let rotate = tuning.rotate
        let bounds = contentRect(contentSize)
        let radius = configuration.cornerRadius(for: contentSize)
        let thickness = configuration.borderWidth

        let sweepAngle = 360 * AuroraTimeline.phase(at: time, period: configuration.duration)
        let adjustment = configuration.colorAdjustment(
            hueOffsetDegrees: driftingHueOffset(
                at: time,
                range: configuration.hueRange,
                period: tuning.defaults.rotateHuePeriod
            )
        )

        let sweepMask = AuroraLayer.Mask.angularSweep(
            stops: maskStops(rotate.maskStops(for: configuration.size)),
            startAngleDegrees: sweepAngle
        )

        var layers: [AuroraLayer] = []

        // 0. The host's own outline, brightening along the arc the sweep is revealing. Drawn first so the
        //    colored ring lands on top of it rather than under it.
        if let border = borderLayer(
            contentSize: contentSize,
            activation: activation,
            sweepStops: rotate.maskStops(for: configuration.size),
            startAngleDegrees: sweepAngle
        ) {
            layers.append(border)
        }

        // 1. The soft glow bleeding inward from the perimeter. Masked by the sweep *and* an edge band,
        //    so the middle of the content stays clear and legible.
        layers.append(
            AuroraLayer(
                gradients: innerGradients(contentSize: contentSize, adjustment: adjustment),
                clip: .roundedRectangle(cornerRadius: radius),
                mask: .intersection([sweepMask, .edgeBand(inset: rotate.innerEdgeInset)]),
                opacity: configuration.clampedOpacity(configuration.innerOpacity, activation: activation),
                innerShadow: innerShadow(
                    adjustment: adjustment,
                    blurRadius: rotate.innerShadowBlurRadius(for: configuration.size)
                ),
                frame: bounds
            )
        )

        // 2. The crisp ring: the static color palette with a brighter highlight riding on top, both
        //    isolated to a `thickness`-thick band and revealed by the sweep.
        var ringGradients = perimeterGradients(contentSize: contentSize, adjustment: adjustment)
        ringGradients.append(
            .angularSweep(
                stops: gradientStops(
                    rotate.highlightStops[configuration.theme] ?? [],
                    tint: appearanceTint,
                    adjustment: adjustment
                ),
                startAngleDegrees: sweepAngle
            )
        )
        layers.append(
            AuroraLayer(
                gradients: ringGradients,
                clip: .ring(cornerRadius: radius, thickness: thickness),
                mask: sweepMask,
                opacity: configuration.clampedOpacity(configuration.strokeOpacity, activation: activation),
                frame: bounds
            )
        )

        // 3. The bloom trailing the head. Painted into the same thin ring and *then* blurred,
        //    which is what turns a 1pt band into a halo instead of a fuzzy rectangle.
        layers.append(
            AuroraLayer(
                gradients: [
                    .angularSweep(
                        stops: gradientStops(
                            rotate.bloomStops[configuration.theme] ?? [],
                            tint: appearanceTint,
                            adjustment: adjustment
                        ),
                        startAngleDegrees: sweepAngle
                    )
                ],
                clip: .ring(cornerRadius: radius, thickness: thickness),
                blurRadius: rotate.bloomBlurRadius,
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

    // MARK: Palettes

    /// The static perimeter blobs.
    private func perimeterGradients(
        contentSize: CGSize,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let scale = paletteScale(for: contentSize)
        return rotatePalette.enumerated().map { index, entry in
            blob(
                color: entry.color,
                at: index,
                center: entry.position,
                radii: entry.radii.scaled(x: scale.width, y: scale.height),
                adjustment: adjustment
            )
        }
    }

    /// The inward glow.
    ///
    /// The compact preset ships its own tuned inner palette because its box is small enough that a
    /// derived one lands wrong. The standard preset derives its glow from the perimeter blobs — same
    /// positions, scaled down and made translucent — which keeps the glow color-matched to the ring
    /// for free, including when the caller supplied the colors.
    private func innerGradients(
        contentSize: CGSize,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let scale = paletteScale(for: contentSize)

        if configuration.size == .compact {
            let inner = tuning.compactPalette(configuration.variant, theme: configuration.theme).inner
            return inner.enumerated().map { index, entry in
                blob(
                    color: entry.color,
                    at: index,
                    center: entry.position,
                    radii: entry.radii.scaled(x: scale.width, y: scale.height),
                    adjustment: adjustment
                )
            }
        }

        let glow = tuning.rotate.innerGlow
        // Halved for a uniform palette, for the same reason its layer opacities are. See
        // ``AuroraColorVariant/isUniform``.
        let alpha = configuration.variant.isUniform ? glow.uniformAlpha : glow.alpha
        let palette = tuning.perimeterPalette(configuration.variant, theme: configuration.theme)
        return palette.enumerated().map { index, entry in
            blob(
                color: entry.color.withAlpha(alpha),
                at: index,
                center: entry.position,
                radii: entry.radii.scaled(
                    x: glow.radiiScale * scale.width,
                    y: glow.radiiScale * scale.height
                ),
                adjustment: adjustment
            )
        }
    }

    /// How far the host departs from the box this preset's palette was authored around.
    ///
    /// Blob *positions* are fractions of the host and need nothing. Blob *radii* are absolute points, and
    /// only the compact palette is authored small enough for that to matter: its widest blob is 59pt on a
    /// 70pt-wide reference control. Left unscaled that blob covers 84% of a chip and 30% of a wide button,
    /// so the same tuning that sweeps a chip cleanly leaves a wide button looking gapped.
    ///
    /// `.regular` has no reference box — its palette is authored for a card and reads correctly across the
    /// range a card spans — so it scales by 1 and this costs it nothing.
    ///
    /// Clamped, so a host far from the reference cannot produce blobs so large they merge into one band or
    /// so small they detach from the edge.
    private func paletteScale(for contentSize: CGSize) -> CGSize {
        guard let reference = tuning.sizePreset(for: configuration.size).referenceSize,
              reference.width > 0, reference.height > 0
        else {
            return CGSize(width: 1, height: 1)
        }
        let bounds = Self.paletteScaleBounds
        func scaled(_ measured: Double, _ reference: Double) -> Double {
            min(max(measured / reference, bounds.lowerBound), bounds.upperBound)
        }
        return CGSize(
            width: scaled(contentSize.width, reference.width),
            height: scaled(contentSize.height, reference.height)
        )
    }

    /// Bounds on ``paletteScale(for:)``.
    ///
    /// Narrower than the outward halo's `0.35...4`: a control's glow sits *on* a 1pt border, where being
    /// off-scale shows immediately. The halo floats free and tolerates more.
    static let paletteScaleBounds: ClosedRange<Double> = 0.6...2.5

    private var rotatePalette: [PaletteBlob] {
        configuration.size == .compact
            ? tuning.compactPalette(configuration.variant, theme: configuration.theme).perimeter
            : tuning.perimeterPalette(configuration.variant, theme: configuration.theme)
    }
}
