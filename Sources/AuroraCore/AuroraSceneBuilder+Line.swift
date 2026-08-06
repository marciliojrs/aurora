import CoreGraphics
import Foundation

// The ``AuroraSize/underline`` preset: a bright head travelling along the bottom edge, trailing a fan
// of colored spikes.
//
// This is the most intricate of the three families because it runs **five independent clocks** off one
// time base, each on its own duration multiple:
//
// | Track            | ×duration | Drives                                   |
// |------------------|-----------|------------------------------------------|
// | `travel`         | 1.00      | head position and width                  |
// | `edgeFade`       | 1.00      | overall opacity, so the wrap is not a pop |
// | `breathe`        | 1.30      | height of every blob                     |
// | `spike`          | 1.33      | width of spikes 1, 3, 5, 7               |
// | `alternateSpike` | 1.70      | width of spikes 2, 4, 6                  |
//
// The multiples are deliberately non-integer, so the tracks drift in and out of alignment rather than
// visibly repeating once per cycle.

extension AuroraSceneBuilder {
    func lineScene(contentSize: CGSize, time: Double, activation: Double) -> AuroraScene {
        let line = tuning.line
        let bounds = contentRect(contentSize)
        let radius = configuration.cornerRadius(for: contentSize)
        let thickness = configuration.borderWidth
        let tracks = LineTracks(tuning: line, time: time, duration: configuration.duration)

        // `edgeFade` gates every layer, so once it bottoms out there is nothing to draw.
        guard tracks.edgeFade > 0.001 else {
            return .empty(contentSize: contentSize, cornerRadius: radius)
        }

        let adjustment = configuration.colorAdjustment(
            hueOffsetDegrees: driftingHueOffset(
                at: time,
                range: configuration.hueRange,
                period: tuning.defaults.rotateHuePeriod
            )
        )
        // The spike fan drifts over a wider range on a shorter period than the crisp layers. Letting
        // it lead slightly is what stops the halo and the head reading as one flat shape.
        let bloomAdjustment = configuration.colorAdjustment(
            hueOffsetDegrees: driftingHueOffset(
                at: time,
                range: configuration.hueRange + tuning.defaults.lineBloomHueRangeBonus,
                period: tuning.defaults.lineBloomHuePeriod
            )
        )

        let headCenter = AuroraPoint(x: .init(fraction: tracks.headPosition), y: .percent(100))
        let headMask = AuroraLayer.Mask.ellipse(
            center: headCenter,
            radii: AuroraSizeSpec.points(
                width: line.headMask.width * tracks.headWidth,
                height: line.headMask.height * tracks.breathe
            ),
            stops: softFalloff(line.headMask.softStop)
        )

        var layers: [AuroraLayer] = []

        // The host's outline, steady: neither of these families has an angular head for it to follow.
        if let border = borderLayer(contentSize: contentSize, activation: activation) {
            layers.append(border)
        }

        // 1. Colored glow bleeding up from the bottom edge, clipped to the content and revealed only
        //    around the head.
        layers.append(
            AuroraLayer(
                gradients: lineInnerGradients(tracks: tracks, adjustment: adjustment),
                clip: .roundedRectangle(cornerRadius: radius),
                mask: .intersection([headMask, .edgeBand(inset: tuning.rotate.innerEdgeInset)]),
                opacity: lineOpacity(configuration.innerOpacity, tracks: tracks, activation: activation),
                innerShadow: innerShadow(
                    adjustment: adjustment,
                    blurRadius: tuning.rotate.standardInnerShadowBlur
                ),
                frame: bounds
            )
        )

        // 2. The crisp head on the ring, with a bright highlight centered on it.
        layers.append(
            AuroraLayer(
                gradients: lineStrokeGradients(tracks: tracks, adjustment: adjustment),
                clip: .ring(cornerRadius: radius, thickness: thickness),
                mask: headMask,
                opacity: lineOpacity(configuration.strokeOpacity, tracks: tracks, activation: activation),
                frame: bounds
            )
        )

        // 3. The spike fan: nine tall, narrow blobs at fixed positions across the width, each
        //    breathing on one of the two spike tracks. Its reveal ellipse is much taller than the head
        //    mask so the spikes can reach up past it.
        layers.append(
            AuroraLayer(
                gradients: lineBloomGradients(tracks: tracks, adjustment: bloomAdjustment),
                clip: .roundedRectangle(cornerRadius: radius),
                mask: .ellipse(
                    center: headCenter,
                    radii: AuroraSizeSpec.points(
                        width: line.bloomMask.width * tracks.headWidth,
                        height: line.bloomMask.height * tracks.breathe
                    ),
                    stops: softFalloff(line.bloomMask.softStop)
                ),
                blurRadius: lineBloomBlurRadius,
                opacity: lineOpacity(configuration.bloomOpacity, tracks: tracks, activation: activation),
                frame: bounds
            )
        )

        return AuroraScene(
            contentSize: contentSize,
            cornerRadius: radius,
            layers: layers.filter { $0.isVisible }
        )
    }

    // MARK: Opacity

    /// Every layer of this preset is gated by `edgeFade` on top of its own preset opacity.
    private func lineOpacity(
        _ presetOpacity: Double,
        tracks: LineTracks,
        activation: Double
    ) -> Double {
        configuration.clampedOpacity(presetOpacity * tracks.edgeFade, activation: activation)
    }

    // MARK: Layers

    /// The colored blobs riding on the ring, positioned relative to the travelling head.
    private func lineStrokeGradients(
        tracks: LineTracks,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        var gradients = tuning.linePalette(configuration.variant, theme: configuration.theme)
            .enumerated()
            .map { index, entry in
                blob(
                    color: entry.color,
                    at: index,
                    center: AuroraPoint(
                        x: AuroraLength(fraction: tracks.headPosition, points: entry.horizontalOffset),
                        y: AuroraLength(fraction: 1, points: entry.verticalOffset)
                    ),
                    radii: AuroraSizeSpec.points(
                        width: entry.width * tracks.headWidth,
                        height: entry.height * tracks.breathe
                    ),
                    adjustment: adjustment
                )
            }

        // The bright core of the head, drawn last so it sits above the colors.
        if let highlight = tuning.line.highlight[configuration.theme] {
            gradients.append(
                .ellipse(
                    AuroraEllipseGradient(
                        center: AuroraPoint(
                            x: AuroraLength(fraction: tracks.headPosition),
                            y: AuroraLength(fraction: 1, points: highlight.verticalOffset)
                        ),
                        radii: AuroraSizeSpec.points(
                            width: highlight.width * tracks.headWidth,
                            height: highlight.height * tracks.breathe
                        ),
                        stops: gradientStops(
                            highlight.stops,
                            tint: highlight.tint,
                            adjustment: adjustment
                        )
                    )
                )
            )
        }
        return gradients
    }

    /// The softer, translucent version of the same blobs, glowing up into the content.
    ///
    /// Their vertical offsets are always subtracted: this palette sits *inside* the content looking up
    /// from the edge, where the stroke palette straddles the edge itself.
    private func lineInnerGradients(
        tracks: LineTracks,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let palette = tuning.lineInnerPalette(configuration.variant, theme: configuration.theme)
        return palette.enumerated().map { index, entry in
            blob(
                color: entry.color,
                at: index,
                center: AuroraPoint(
                    x: AuroraLength(fraction: tracks.headPosition, points: entry.horizontalOffset),
                    y: AuroraLength(fraction: 1, points: -abs(entry.verticalOffset))
                ),
                radii: AuroraSizeSpec.points(
                    width: entry.width * tracks.headWidth,
                    height: entry.height * tracks.breathe
                ),
                adjustment: adjustment
            )
        }
    }

    /// The spike fan.
    private func lineBloomGradients(
        tracks: LineTracks,
        adjustment: AuroraColorMatrix
    ) -> [AuroraGradient] {
        let blobs = tuning.lineBloomBlobs(configuration.variant, theme: configuration.theme)
        return blobs.enumerated().map { index, entry in
            // A `nil` horizontal position means "follow the head" — that is how the bright core dot
            // tracks the travel while the spikes stay pinned across the width.
            let fraction = entry.horizontalFraction ?? tracks.headPosition
            return .ellipse(
                AuroraEllipseGradient(
                    center: AuroraPoint(
                        x: AuroraLength(fraction: fraction),
                        y: AuroraLength(fraction: 1, points: entry.verticalOffset)
                    ),
                    radii: AuroraSizeSpec.points(
                        width: entry.width.base * tracks.multiplier(entry.width.multiplier),
                        height: entry.height.base * tracks.multiplier(entry.height.multiplier)
                    ),
                    // Indexed by the *spike*, not by the stop: every stop within one spike has to
                    // share a hue, or its own gradient would run through the caller's whole
                    // combination and the spike would read as a rainbow smear.
                    stops: entry.stops.map {
                        AuroraGradientStop(
                            location: $0.location,
                            color: adjustment.applied(to: recolored($0.color, at: index))
                        )
                    }
                )
            )
        }
    }

    /// How much the spike fan is blurred.
    ///
    /// Spikes built on the achromatic base read as hard bars rather than glow at their tuned width, and
    /// need noticeably more blur to soften. That holds however the caller recolored them, because the
    /// hue is multiplied through and the shape is unchanged. Freezing the colors of the authored
    /// spectrum gives no blur, matching how the tuning treats a static palette as already soft.
    private var lineBloomBlurRadius: Double {
        if configuration.variant.base == .neutral { return tuning.line.neutralBloomBlurRadius }
        return configuration.staticColors ? 0 : tuning.line.bloomBlurRadius
    }
}

// MARK: - Track sampling

extension AuroraSceneBuilder {
    /// All five tracks sampled at one instant.
    ///
    /// Bundling them keeps sampling in one place and makes it obvious that every layer in a frame sees
    /// the *same* head position. Sampling per layer would let rounding drift them apart by a fraction
    /// of a point, which shows up as a seam between the crisp head and its glow.
    struct LineTracks: Hashable, Sendable {
        /// Head position as a fraction of the width.
        var headPosition: Double
        /// Head width multiplier.
        var headWidth: Double
        /// Global height multiplier.
        var breathe: Double
        var spike: Double
        var alternateSpike: Double
        /// Overall gate, `0...1`.
        var edgeFade: Double

        init(tuning: LineTuning, time: Double, duration: Double) {
            let scale = tuning.durationScale
            let easing = tuning.easing
            let travelPeriod = duration * scale.travel

            headPosition = AuroraTimeline.sample(
                tuning.travelPosition, at: time, period: travelPeriod, easing: easing.travel
            )
            headWidth = AuroraTimeline.sample(
                tuning.travelWidth, at: time, period: travelPeriod, easing: easing.travel
            )
            edgeFade = AuroraTimeline.sample(
                tuning.edgeFade, at: time,
                period: duration * scale.edgeFade, easing: easing.edgeFade
            )
            breathe = AuroraTimeline.sample(
                tuning.breathe, at: time,
                period: duration * scale.breathe, easing: easing.breathe
            )
            spike = AuroraTimeline.sample(
                tuning.spike, at: time,
                period: duration * scale.spike, easing: easing.spike
            )
            alternateSpike = AuroraTimeline.sample(
                tuning.alternateSpike, at: time,
                period: duration * scale.alternateSpike, easing: easing.alternateSpike
            )
        }

        /// Resolves one of the named multipliers a bloom blob's axis can reference.
        ///
        /// The inverse forms are `2 - value`, which counter-phases a spike against its neighbours: as
        /// one widens the next narrows, so the fan shimmers instead of pumping in unison.
        func multiplier(_ multiplier: LineMultiplier) -> Double {
            switch multiplier {
            case .headWidth: headWidth
            case .breathe: breathe
            case .spike: spike
            case .alternateSpike: alternateSpike
            case .inverseSpike: 2 - spike
            case .inverseAlternateSpike: 2 - alternateSpike
            }
        }
    }
}
