import CoreGraphics
import Foundation

// The shape of the tuned constants. Values live in the generated `Tuning+*` files; the meaning
// of each one lives with the scene builder that consumes it.

// MARK: - Stops and keyframes

/// A stop carrying coverage but no color, for the angular sweeps and reveal masks. The color comes
/// from the layer — white on dark appearances, black on light.
package struct AlphaStop: Hashable, Sendable {
    /// `0...1` along the gradient axis.
    package var location: Double
    package var alpha: Double

    package init(location: Double, alpha: Double) {
        self.location = location
        self.alpha = alpha
    }

    /// Resolves to a concrete stop by tinting with the appearance's color.
    func stop(tintedWith color: AuroraColor) -> AuroraGradientStop {
        AuroraGradientStop(location: location, color: color.withAlpha(alpha))
    }
}

/// One stop of a keyframe track.
package struct Keyframe: Hashable, Sendable {
    /// `0...1` through the animation cycle.
    package var position: Double
    package var value: Double

    package init(position: Double, value: Double) {
        self.position = position
        self.value = value
    }
}

// MARK: - Palettes

/// One soft elliptical blob in a perimeter palette.
package struct PaletteBlob: Hashable, Sendable {
    package var color: AuroraColor
    /// Center, as a fraction of the layer's box on each axis.
    package var position: AuroraPoint
    /// Horizontal and vertical radii.
    package var radii: AuroraSizeSpec

    package init(color: AuroraColor, position: AuroraPoint, radii: AuroraSizeSpec) {
        self.color = color
        self.position = position
        self.radii = radii
    }
}

/// One blob in a line palette. Positioned relative to the travelling head rather than to the layer,
/// so it carries offsets in points instead of a center.
package struct LineBlob: Hashable, Sendable {
    package var color: AuroraColor
    /// Horizontal radius in points.
    package var width: Double
    /// Vertical radius in points.
    package var height: Double
    /// Offset from the head, in points.
    package var horizontalOffset: Double
    /// Offset from the bottom edge, in points.
    package var verticalOffset: Double

    package init(
        color: AuroraColor,
        width: Double,
        height: Double,
        horizontalOffset: Double,
        verticalOffset: Double
    ) {
        self.color = color
        self.width = width
        self.height = height
        self.horizontalOffset = horizontalOffset
        self.verticalOffset = verticalOffset
    }
}

/// The compact preset's palette. Unlike the standard one it ships a separate inner set rather than
/// deriving one, because its box is small enough that a derived glow lands wrong.
package struct CompactPalette: Hashable, Sendable {
    package var perimeter: [PaletteBlob]
    package var inner: [PaletteBlob]

    package init(perimeter: [PaletteBlob], inner: [PaletteBlob]) {
        self.perimeter = perimeter
        self.inner = inner
    }
}

// MARK: - Presets

/// Geometry defaults for a size preset.
package struct SizePreset: Hashable, Sendable {
    package var cornerRadius: Double
    package var borderWidth: Double
    /// The box this preset's palette was tuned against. Only the compact preset has one.
    package var referenceSize: CGSize?

    package init(cornerRadius: Double, borderWidth: Double, referenceSize: CGSize? = nil) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.referenceSize = referenceSize
    }
}

/// Per-appearance opacity and color-adjustment defaults for a size preset.
package struct ThemePreset: Hashable, Sendable {
    /// Opacity of the crisp ring. Several presets exceed 1 and rely on the caller clamping.
    package var strokeOpacity: Double
    package var innerOpacity: Double
    package var bloomOpacity: Double
    /// Color of the inner shadow. ``AuroraColor/clear`` where a preset draws none.
    package var innerShadow: AuroraColor
    package var saturation: Double
    /// `nil` falls back to ``Defaults/brightnessFallback``.
    package var brightness: Double?
    /// Opacity of the constant hairline. Only the outward halo uses it.
    package var hairlineOpacity: Double

    package init(
        strokeOpacity: Double,
        innerOpacity: Double,
        bloomOpacity: Double,
        innerShadow: AuroraColor,
        saturation: Double,
        brightness: Double?,
        hairlineOpacity: Double
    ) {
        self.strokeOpacity = strokeOpacity
        self.innerOpacity = innerOpacity
        self.bloomOpacity = bloomOpacity
        self.innerShadow = innerShadow
        self.saturation = saturation
        self.brightness = brightness
        self.hairlineOpacity = hairlineOpacity
    }
}

/// Library-wide defaults.
package struct Defaults: Hashable, Sendable {
    package var rotateDuration: Double
    package var lineDuration: Double
    package var pulseDuration: Double
    package var hueRange: Double
    /// The underline preset drifts over a much smaller range; wider reads as a color flicker.
    package var lineHueRangeCap: Double
    package var brightnessFallback: Double
    package var fadeInSeconds: Double
    package var fadeOutSeconds: Double
    package var rotateHuePeriod: Double
    package var lineBloomHuePeriod: Double
    package var lineBloomHueRangeBonus: Double
    package var uniformOpacityMultiplier: Double
    package var uniformPaletteHoldsHue: Bool
    /// The pulse oscillators are slow enough that sampling faster than this is wasted work.
    package var pulseSampleRate: Double

    package init(
        rotateDuration: Double,
        lineDuration: Double,
        pulseDuration: Double,
        hueRange: Double,
        lineHueRangeCap: Double,
        brightnessFallback: Double,
        fadeInSeconds: Double,
        fadeOutSeconds: Double,
        rotateHuePeriod: Double,
        lineBloomHuePeriod: Double,
        lineBloomHueRangeBonus: Double,
        uniformOpacityMultiplier: Double,
        uniformPaletteHoldsHue: Bool,
        pulseSampleRate: Double
    ) {
        self.rotateDuration = rotateDuration
        self.lineDuration = lineDuration
        self.pulseDuration = pulseDuration
        self.hueRange = hueRange
        self.lineHueRangeCap = lineHueRangeCap
        self.brightnessFallback = brightnessFallback
        self.fadeInSeconds = fadeInSeconds
        self.fadeOutSeconds = fadeOutSeconds
        self.rotateHuePeriod = rotateHuePeriod
        self.lineBloomHuePeriod = lineBloomHuePeriod
        self.lineBloomHueRangeBonus = lineBloomHueRangeBonus
        self.uniformOpacityMultiplier = uniformOpacityMultiplier
        self.uniformPaletteHoldsHue = uniformPaletteHoldsHue
        self.pulseSampleRate = pulseSampleRate
    }

    /// The default duration for a size preset.
    package func duration(for size: AuroraSize) -> Double {
        switch size.family {
        case .rotate: rotateDuration
        case .underline: lineDuration
        case .pulse: pulseDuration
        }
    }
}

// MARK: - Sweeping presets

/// Tuning for the sweeping presets.
package struct RotateTuning: Sendable {
    /// How the inward glow is derived from the perimeter palette.
    package struct InnerGlow: Hashable, Sendable {
        package var radiiScale: Double
        package var alpha: Double
        /// `neutral` halves it, as everywhere else.
        package var uniformAlpha: Double

        package init(radiiScale: Double, alpha: Double, uniformAlpha: Double) {
            self.radiiScale = radiiScale
            self.alpha = alpha
            self.uniformAlpha = uniformAlpha
        }
    }

    /// The bright highlight riding the ring.
    package var highlightStops: [AuroraResolvedTheme: [AlphaStop]]
    /// The blurred bloom trailing the head.
    package var bloomStops: [AuroraResolvedTheme: [AlphaStop]]
    /// The angular mask that turns a static ring into a travelling glow.
    package var sweepMaskStops: [AlphaStop]
    /// A tighter mask for the compact preset, whose perimeter is much shorter.
    package var compactMaskStops: [AlphaStop]
    package var innerGlow: InnerGlow
    /// How far the inward glow fades in from each edge, in points.
    package var innerEdgeInset: Double
    package var standardInnerShadowBlur: Double
    package var compactInnerShadowBlur: Double
    package var bloomBlurRadius: Double

    package init(
        highlightStops: [AuroraResolvedTheme: [AlphaStop]],
        bloomStops: [AuroraResolvedTheme: [AlphaStop]],
        sweepMaskStops: [AlphaStop],
        compactMaskStops: [AlphaStop],
        innerGlow: InnerGlow,
        innerEdgeInset: Double,
        standardInnerShadowBlur: Double,
        compactInnerShadowBlur: Double,
        bloomBlurRadius: Double
    ) {
        self.highlightStops = highlightStops
        self.bloomStops = bloomStops
        self.sweepMaskStops = sweepMaskStops
        self.compactMaskStops = compactMaskStops
        self.innerGlow = innerGlow
        self.innerEdgeInset = innerEdgeInset
        self.standardInnerShadowBlur = standardInnerShadowBlur
        self.compactInnerShadowBlur = compactInnerShadowBlur
        self.bloomBlurRadius = bloomBlurRadius
    }

    /// The mask stops for a preset. The compact one uses a tighter set.
    func maskStops(for size: AuroraSize) -> [AlphaStop] {
        size == .compact ? compactMaskStops : sweepMaskStops
    }

    func innerShadowBlurRadius(for size: AuroraSize) -> Double {
        size == .compact ? compactInnerShadowBlur : standardInnerShadowBlur
    }
}

// MARK: - Bottom-edge preset

/// Which track scales a bloom blob's axis.
package enum LineMultiplier: Hashable, Sendable {
    case spike
    case alternateSpike
    /// The head's own width multiplier.
    case headWidth
    /// The global height track.
    case breathe
    /// `2 - spike`, which counter-phases a spike against its neighbours.
    case inverseSpike
    /// `2 - alternateSpike`.
    case inverseAlternateSpike
}

/// One of the tall, narrow blobs fanning out below the head.
package struct LineBloomBlob: Sendable {
    package struct Axis: Hashable, Sendable {
        package var base: Double
        package var multiplier: LineMultiplier

        package init(base: Double, multiplier: LineMultiplier) {
            self.base = base
            self.multiplier = multiplier
        }
    }

    /// Fixed horizontal position as a fraction of the width. `nil` means "track the head", which is
    /// how the bright core dot follows the travel while the spikes stay pinned.
    package var horizontalFraction: Double?
    /// Offset from the bottom edge, in points.
    package var verticalOffset: Double
    package var width: Axis
    package var height: Axis
    package var stops: [AuroraGradientStop]

    package init(
        horizontalFraction: Double?,
        verticalOffset: Double,
        width: Axis,
        height: Axis,
        stops: [AuroraGradientStop]
    ) {
        self.horizontalFraction = horizontalFraction
        self.verticalOffset = verticalOffset
        self.width = width
        self.height = height
        self.stops = stops
    }
}

/// Tuning for the bottom-edge preset.
package struct LineTuning: Sendable {
    /// Each track runs at `duration × scale`, which is what desyncs them.
    package struct DurationScale: Hashable, Sendable {
        package var travel: Double
        package var edgeFade: Double
        package var breathe: Double
        package var spike: Double
        package var alternateSpike: Double

        package init(
            travel: Double,
            edgeFade: Double,
            breathe: Double,
            spike: Double,
            alternateSpike: Double
        ) {
            self.travel = travel
            self.edgeFade = edgeFade
            self.breathe = breathe
            self.spike = spike
            self.alternateSpike = alternateSpike
        }
    }

    package struct Easings: Hashable, Sendable {
        package var travel: AuroraTimeline.Easing
        package var edgeFade: AuroraTimeline.Easing
        package var breathe: AuroraTimeline.Easing
        package var spike: AuroraTimeline.Easing
        package var alternateSpike: AuroraTimeline.Easing

        package init(
            travel: AuroraTimeline.Easing,
            edgeFade: AuroraTimeline.Easing,
            breathe: AuroraTimeline.Easing,
            spike: AuroraTimeline.Easing,
            alternateSpike: AuroraTimeline.Easing
        ) {
            self.travel = travel
            self.edgeFade = edgeFade
            self.breathe = breathe
            self.spike = spike
            self.alternateSpike = alternateSpike
        }
    }

    /// A soft ellipse revealing only the neighbourhood of the head.
    package struct MaskEllipse: Hashable, Sendable {
        package var width: Double
        package var height: Double
        /// The mid stop that softens the falloff.
        package var softStop: AlphaStop

        package init(width: Double, height: Double, softStop: AlphaStop) {
            self.width = width
            self.height = height
            self.softStop = softStop
        }
    }

    /// The bright core of the head.
    package struct Highlight: Sendable {
        package var width: Double
        package var height: Double
        package var verticalOffset: Double
        /// White on dark appearances, black on light.
        package var tint: AuroraColor
        package var stops: [AlphaStop]

        package init(
            width: Double,
            height: Double,
            verticalOffset: Double,
            tint: AuroraColor,
            stops: [AlphaStop]
        ) {
            self.width = width
            self.height = height
            self.verticalOffset = verticalOffset
            self.tint = tint
            self.stops = stops
        }
    }

    /// Head position as a fraction of the width.
    package var travelPosition: [Keyframe]
    /// Head width multiplier.
    package var travelWidth: [Keyframe]
    /// Gates the whole effect, so the glow does not pop when it wraps.
    package var edgeFade: [Keyframe]
    package var breathe: [Keyframe]
    package var spike: [Keyframe]
    package var alternateSpike: [Keyframe]
    package var durationScale: DurationScale
    package var easing: Easings
    package var headMask: MaskEllipse
    package var bloomMask: MaskEllipse
    package var highlight: [AuroraResolvedTheme: Highlight]
    /// Spikes on the achromatic base read as hard bars without extra blur.
    package var neutralBloomBlurRadius: Double
    package var bloomBlurRadius: Double
    /// Internal, like every other palette table. Its key names which authored table a blob came from,
    /// which is a detail of the tuning rather than something a caller picks — see `PaletteBase`. The
    /// memberwise initializer follows it down for the same reason.
    var bloomBlobs: [PaletteBase: [AuroraResolvedTheme: [LineBloomBlob]]]

    init(
        travelPosition: [Keyframe],
        travelWidth: [Keyframe],
        edgeFade: [Keyframe],
        breathe: [Keyframe],
        spike: [Keyframe],
        alternateSpike: [Keyframe],
        durationScale: DurationScale,
        easing: Easings,
        headMask: MaskEllipse,
        bloomMask: MaskEllipse,
        highlight: [AuroraResolvedTheme: Highlight],
        neutralBloomBlurRadius: Double,
        bloomBlurRadius: Double,
        bloomBlobs: [PaletteBase: [AuroraResolvedTheme: [LineBloomBlob]]]
    ) {
        self.travelPosition = travelPosition
        self.travelWidth = travelWidth
        self.edgeFade = edgeFade
        self.breathe = breathe
        self.spike = spike
        self.alternateSpike = alternateSpike
        self.durationScale = durationScale
        self.easing = easing
        self.headMask = headMask
        self.bloomMask = bloomMask
        self.highlight = highlight
        self.neutralBloomBlurRadius = neutralBloomBlurRadius
        self.bloomBlurRadius = bloomBlurRadius
        self.bloomBlobs = bloomBlobs
    }
}

// MARK: - Breathing presets

/// Which of the three independent size and drift regions a blob belongs to. Regions breathe on
/// desynced periods, which is what stops the glow reading as one object scaling.
package enum PulseRegion: Int, Hashable, Sendable, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
}

/// Which per-quadrant opacity oscillator modulates a blob.
package enum PulseQuadrant: Hashable, Sendable, CaseIterable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

/// What an oscillator drives.
///
/// A typed target rather than a name: the compiler checks that every case is handled, so there is no
/// string routing that can silently miss a value and leave the breathing partly absent.
package enum PulseTarget: Hashable, Sendable {
    case width(PulseRegion)
    case height(PulseRegion)
    case driftX(PulseRegion)
    case driftY(PulseRegion)
    case globalHeight
    case quadrantOpacity(PulseQuadrant)
}

/// One oscillator, ping-ponging a value between two bounds with cosine easing.
package struct PulseOscillator: Hashable, Sendable {
    package var target: PulseTarget
    package var from: Double
    package var to: Double
    package var period: Double
    /// Seconds to delay the start, desyncing this oscillator from its siblings.
    package var phaseOffset: Double

    package init(
        target: PulseTarget,
        from: Double,
        to: Double,
        period: Double,
        phaseOffset: Double
    ) {
        self.target = target
        self.from = from
        self.to = to
        self.period = period
        self.phaseOffset = phaseOffset
    }
}

/// Breathing amplitudes and periods for one preset and appearance.
///
/// The periods are stored at the reference duration; see ``Tuning/pulseReferenceDuration``.
package struct PulseParameters: Hashable, Sendable {
    package var sizeAmplitude: Double
    /// Drift range in points.
    package var driftRange: Double
    package var opacityAmplitude: Double
    package var heightAmplitude: Double
    /// Base period for the drift and opacity oscillators.
    package var driftPeriod: Double
    /// Base period for the size oscillators.
    package var sizePeriod: Double
    package var heightPeriod: Double
    /// Seconds for a full hue revolution. Unlike the others this does not scale with duration.
    package var huePeriod: Double

    package init(
        sizeAmplitude: Double,
        driftRange: Double,
        opacityAmplitude: Double,
        heightAmplitude: Double,
        driftPeriod: Double,
        sizePeriod: Double,
        heightPeriod: Double,
        huePeriod: Double
    ) {
        self.sizeAmplitude = sizeAmplitude
        self.driftRange = driftRange
        self.opacityAmplitude = opacityAmplitude
        self.heightAmplitude = heightAmplitude
        self.driftPeriod = driftPeriod
        self.sizePeriod = sizePeriod
        self.heightPeriod = heightPeriod
        self.huePeriod = huePeriod
    }
}

package struct PulseThemeTuning: Sendable {
    package var parameters: PulseParameters
    package var oscillators: [PulseOscillator]
    /// The bloom's blobs are frozen at the time-average of their breathing range, so the heavily
    /// blurred layer can be rasterized once rather than every frame.
    package var frozenBloomAlpha: Double

    package init(
        parameters: PulseParameters,
        oscillators: [PulseOscillator],
        frozenBloomAlpha: Double
    ) {
        self.parameters = parameters
        self.oscillators = oscillators
        self.frozenBloomAlpha = frozenBloomAlpha
    }
}

/// Which region and quadrant each perimeter palette entry belongs to.
package struct PulseRingEntry: Hashable, Sendable {
    package var region: PulseRegion
    package var quadrant: PulseQuadrant

    package init(region: PulseRegion, quadrant: PulseQuadrant) {
        self.region = region
        self.quadrant = quadrant
    }
}

/// A blob in one of the fixed pulse tables.
package struct PulseBlob: Hashable, Sendable {
    /// Index into the perimeter palette, so every color variant works.
    package var paletteIndex: Int
    package var region: PulseRegion
    package var quadrant: PulseQuadrant
    package var width: Double
    package var height: Double
    /// Overrides the palette entry's own position when present.
    package var position: AuroraPoint?

    package init(
        paletteIndex: Int,
        region: PulseRegion,
        quadrant: PulseQuadrant,
        width: Double,
        height: Double,
        position: AuroraPoint?
    ) {
        self.paletteIndex = paletteIndex
        self.region = region
        self.quadrant = quadrant
        self.width = width
        self.height = height
        self.position = position
    }
}

/// Tuning for the breathing presets.
package struct PulseTuning: Sendable {
    package struct CornerAccent: Hashable, Sendable {
        /// Radius in points.
        package var size: Double
        package var alpha: [AuroraResolvedTheme: Double]
        /// Where the accent has fully faded, `0...1`.
        package var fadeLocation: Double

        package init(size: Double, alpha: [AuroraResolvedTheme: Double], fadeLocation: Double) {
            self.size = size
            self.alpha = alpha
            self.fadeLocation = fadeLocation
        }
    }

    package var ringMap: [PulseRingEntry]
    /// Reduced radii for the inward glow, one per palette entry.
    package var innerGlowSizes: [CGSize]
    package var innerBloom: [PulseBlob]
    package var outerCore: [PulseBlob]
    package var outerBloom: [PulseBlob]
    package var cornerAccent: CornerAccent
    package var contained: [AuroraResolvedTheme: PulseThemeTuning]
    package var outward: [AuroraResolvedTheme: PulseThemeTuning]

    package init(
        ringMap: [PulseRingEntry],
        innerGlowSizes: [CGSize],
        innerBloom: [PulseBlob],
        outerCore: [PulseBlob],
        outerBloom: [PulseBlob],
        cornerAccent: CornerAccent,
        contained: [AuroraResolvedTheme: PulseThemeTuning],
        outward: [AuroraResolvedTheme: PulseThemeTuning]
    ) {
        self.ringMap = ringMap
        self.innerGlowSizes = innerGlowSizes
        self.innerBloom = innerBloom
        self.outerCore = outerCore
        self.outerBloom = outerBloom
        self.cornerAccent = cornerAccent
        self.contained = contained
        self.outward = outward
    }

    /// The tuning for a pulse preset in a resolved appearance.
    func themeTuning(for size: AuroraSize, theme: AuroraResolvedTheme) -> PulseThemeTuning? {
        (size == .pulseInward ? contained : outward)[theme]
    }
}
