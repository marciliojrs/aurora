import CoreGraphics
import Foundation

/// Every knob the effect exposes.
///
/// Optional properties mean "use the preset's tuned value" rather than a single global default. That
/// distinction matters: unset brightness resolves to 1.9 for `.pulseOutward` on a dark appearance and
/// 1.3 for `.regular`, so a plain default in the initializer would flatten five separately tuned presets
/// into one.
public struct AuroraConfiguration: Hashable, Sendable {
    /// Which preset to draw. See ``AuroraSize``.
    public var size: AuroraSize
    /// Which palette to draw it in.
    public var colorVariant: AuroraColorVariant
    /// Which appearance to tune colors for.
    public var theme: AuroraTheme

    /// Freezes the hue animation for static colors.
    ///
    /// A palette that resolves to a single hue forces this on regardless: drifting a color the caller
    /// named is a surprise, and with every blob sharing it there is nothing to gain. See
    /// ``AuroraColorVariant/isUniform``.
    public var staticColors: Bool

    /// Seconds for one full cycle. `nil` uses the preset's tuned duration.
    public var duration: Double?

    /// Draws the host's own outline underneath the glow, and lets the effect light it.
    ///
    /// White on a dark appearance, black on a light one — the same inversion the rest of the tuning uses,
    /// so it needs no color of its own.
    ///
    /// Worth turning on when the host has no border of its own: it gives the sweep something continuous to
    /// travel along. Without it a swept glow reads as an edge appearing and vanishing; with it, as light
    /// moving over an edge that was always there.
    ///
    /// Swept for ``AuroraSize/compact`` and ``AuroraSize/regular``, which have an angular sweep to follow.
    /// The other presets draw it steady rather than ignoring it, so the flag never silently does nothing.
    public var showsBorder: Bool

    /// The outline the glow traces. See ``AuroraShape``.
    ///
    /// There is no auto-detection: a SwiftUI view has no queryable corner radius, and inferring one from a
    /// rendered snapshot would be slow and unreliable. Name the same shape the host is clipped to and the
    /// radius is worked out once the host has been measured.
    public var shape: AuroraShape

    /// Ring thickness in points. `nil` uses the preset's default.
    public var borderWidth: Double?

    /// Multiplicative brightness for the glow. `nil` uses the preset's tuned value.
    public var brightness: Double?

    /// Saturation for the glow. `nil` uses the preset's tuned value.
    public var saturation: Double?

    /// Degrees of hue drift either side of the base hue. `nil` uses the tuned default.
    public var hueRange: Double?

    /// Overall intensity, `0...1`. Scales the ring, glow and bloom layers only — never the wrapped
    /// content.
    public var strength: Double

    /// - Parameter theme: ``AuroraTheme/auto`` by default. A glow attached to an arbitrary component has
    ///   no business pinning the appearance, so following the surrounding scheme is the only sane default.
    public init(
        size: AuroraSize = .regular,
        colorVariant: AuroraColorVariant = .glow,
        theme: AuroraTheme = .auto,
        shape: AuroraShape = .preset,
        showsBorder: Bool = false,
        staticColors: Bool = false,
        duration: Double? = nil,
        borderWidth: Double? = nil,
        brightness: Double? = nil,
        saturation: Double? = nil,
        hueRange: Double? = nil,
        strength: Double = 1
    ) {
        self.size = size
        self.colorVariant = colorVariant
        self.theme = theme
        self.shape = shape
        self.showsBorder = showsBorder
        self.staticColors = staticColors
        self.duration = duration
        self.borderWidth = borderWidth
        self.brightness = brightness
        self.saturation = saturation
        self.hueRange = hueRange
        self.strength = strength
    }
}

// MARK: - Resolution

extension AuroraConfiguration {
    /// Fills every optional from the shipped tuning and collapses ``AuroraTheme/auto``.
    ///
    /// The environment is read by the renderers and handed in here, which is what keeps
    /// ``AuroraSceneBuilder`` a pure function of its inputs.
    public func resolved(isDarkEnvironment: Bool) -> AuroraResolvedConfiguration {
        resolved(isDarkEnvironment: isDarkEnvironment, tuning: .standard)
    }

    /// The same, against a supplied tuning.
    ///
    /// Package-scoped because `Tuning` is. Its initializers are package-scoped too, so no consumer could
    /// build one to pass — a public parameter here would have advertised a choice nobody outside this
    /// package can make.
    package func resolved(
        isDarkEnvironment: Bool,
        tuning: Tuning
    ) -> AuroraResolvedConfiguration {
        let resolvedTheme = theme.resolved(isDarkEnvironment: isDarkEnvironment)
        let sizePreset = tuning.sizePreset(for: size)
        let themePreset = tuning.themePreset(for: size, theme: resolvedTheme)
        let defaults = tuning.defaults

        // The bottom-edge preset attenuates the achromatic base inside its own bloom table, so applying
        // the global multiplier on top of that would double-dim it.
        let opacityMultiplier = size == .underline
            ? 1
            : colorVariant.opacityMultiplier(tuning, theme: resolvedTheme)
        let requestedHueRange = hueRange ?? defaults.hueRange
        // That preset's drift is capped much tighter: at the default range its fast-moving spikes
        // read as a color flicker rather than a drift.
        let effectiveHueRange = size == .underline
            ? min(requestedHueRange, defaults.lineHueRangeCap)
            : requestedHueRange

        return AuroraResolvedConfiguration(
            size: size,
            variant: colorVariant,
            theme: resolvedTheme,
            duration: duration ?? defaults.duration(for: size),
            shape: shape,
            showsBorder: showsBorder,
            presetCornerRadius: sizePreset.cornerRadius,
            borderWidth: borderWidth ?? sizePreset.borderWidth,
            strokeOpacity: themePreset.strokeOpacity * opacityMultiplier,
            innerOpacity: themePreset.innerOpacity * opacityMultiplier,
            bloomOpacity: themePreset.bloomOpacity * opacityMultiplier,
            hairlineOpacity: themePreset.hairlineOpacity,
            innerShadow: themePreset.innerShadow,
            brightness: brightness ?? themePreset.brightness ?? defaults.brightnessFallback,
            saturation: saturation ?? themePreset.saturation,
            hueRange: effectiveHueRange,
            strength: min(max(strength, 0), 1),
            staticColors: staticColors || colorVariant.forcesStaticColors(tuning)
        )
    }
}

/// A ``AuroraConfiguration`` with every optional filled from the tuning and
/// ``AuroraTheme/auto`` collapsed. This is what ``AuroraSceneBuilder`` consumes.
public struct AuroraResolvedConfiguration: Hashable, Sendable {
    public let size: AuroraSize
    public let variant: AuroraColorVariant
    public let theme: AuroraResolvedTheme
    public let duration: Double
    /// The outline to trace. Resolved to a radius per frame, once the host has been measured.
    public let shape: AuroraShape
    /// Whether to draw the host's outline under the glow. See ``AuroraConfiguration/showsBorder``.
    public let showsBorder: Bool
    /// What ``AuroraShape/preset`` resolves to for this preset.
    public let presetCornerRadius: Double
    public let borderWidth: Double
    /// Opacity of the crisp ring. May exceed 1 before clamping — see ``clampedOpacity``.
    public let strokeOpacity: Double
    /// Opacity of the soft glow inside the element.
    public let innerOpacity: Double
    /// Opacity of the blurred bloom.
    public let bloomOpacity: Double
    /// Opacity of the constant hairline. Only ``AuroraSize/pulseOutward`` uses it.
    public let hairlineOpacity: Double
    public let innerShadow: AuroraColor
    public let brightness: Double
    public let saturation: Double
    public let hueRange: Double
    public let strength: Double
    public let staticColors: Bool

    /// The radius to trace for a host of this size.
    ///
    /// Deliberately a function of the size rather than a stored value: a capsule's radius is half its
    /// height, and a host that grows with Dynamic Type has no single radius to store. Resolving here, in
    /// the one place that knows the measured size, is what makes ``AuroraShape/capsule`` possible at all.
    public func cornerRadius(for contentSize: CGSize) -> Double {
        shape.cornerRadius(for: contentSize, presetCornerRadius: presetCornerRadius)
    }

    /// Combines a preset opacity with `strength` and the activation fade, clamped to a compositable
    /// range.
    ///
    /// The clamp is load-bearing, not defensive. Four presets store an opacity above 1
    /// (`pulseOutward` light stroke 1.96 and inner 1.04, `pulseInward` dark stroke 1.54, `underline` dark
    /// stroke 1.14). Left unclamped, premultiplied alpha climbs past 1 and compositing falls apart —
    /// the `pulseOutward` light hairline blows out and stops tracing the corners at all.
    public func clampedOpacity(_ presetOpacity: Double, activation: Double) -> Double {
        min(max(presetOpacity * strength * activation, 0), 1)
    }

    /// The color adjustment every layer of this configuration carries.
    ///
    /// `hueOffsetDegrees` is supplied per frame by the preset's own clock, since the sweeping and
    /// bottom-edge presets drift within a range while the breathing ones sweep a full circle.
    public func colorAdjustment(hueOffsetDegrees: Double) -> AuroraColorMatrix {
        AuroraColorMatrix.adjustment(
            hueRotationDegrees: staticColors ? 0 : hueOffsetDegrees,
            brightness: brightness,
            saturation: saturation
        )
    }
}
