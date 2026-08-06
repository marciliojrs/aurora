import CoreGraphics
import Foundation

/// The tuned constants behind the effect: palettes, opacities, keyframe tracks and oscillators.
///
/// Held as Swift literals in the generated `Tuning+*` files rather than as a bundled payload.
/// That buys three things: the values are type-checked at build time, the package needs no resource
/// bundle and keeps working when its sources are vendored directly, and there is no load step that
/// can fail at runtime.
///
/// Every table is keyed by the enums the package API exposes, so an incomplete table is a
/// compile-time shape mismatch rather than a lookup that quietly returns nothing.
package struct Tuning: Sendable {
    package let defaults: Defaults

    let sizePresets: [AuroraSize: SizePreset]
    let themePresets: [AuroraSize: [AuroraResolvedTheme: ThemePreset]]
    let perimeterPalettes: [PaletteBase: [PaletteBlob]]
    let compactPalettes: [PaletteBase: CompactPalette]
    let linePalettes: [PaletteBase: [AuroraResolvedTheme: [LineBlob]]]
    let lineInnerPalettes: [PaletteBase: [LineBlob]]
    let rotate: RotateTuning
    let line: LineTuning
    let pulse: PulseTuning

    /// The shipped tuning.
    package static let standard = Tuning(
        defaults: standardDefaults,
        sizePresets: standardSizePresets,
        themePresets: standardThemePresets,
        perimeterPalettes: standardPerimeterPalettes,
        compactPalettes: standardCompactPalettes,
        linePalettes: standardLinePalettes,
        lineInnerPalettes: standardLineInnerPalettes,
        rotate: standardRotate,
        line: standardLine,
        pulse: standardPulse
    )
}

// MARK: - Accessors

extension Tuning {
    /// Geometry defaults for a size preset.
    package func sizePreset(for size: AuroraSize) -> SizePreset {
        guard let preset = sizePresets[size] else {
            preconditionFailure("The tuning is missing a size preset for \(size)")
        }
        return preset
    }

    /// Opacity and color defaults for a size preset in a resolved appearance.
    package func themePreset(for size: AuroraSize, theme: AuroraResolvedTheme) -> ThemePreset {
        guard let preset = themePresets[size]?[theme] else {
            preconditionFailure("The tuning is missing a preset for \(size)/\(theme)")
        }
        return preset
    }

    /// The nine-blob perimeter palette shared by the standard sweep and both breathing presets.
    ///
    /// Takes the variant rather than its ``PaletteBase`` because the appearance adaptation below depends
    /// on which base was chosen, and callers already hold the variant.
    func perimeterPalette(
        _ variant: AuroraColorVariant,
        theme: AuroraResolvedTheme
    ) -> [PaletteBlob] {
        guard let palette = perimeterPalettes[variant.base] else {
            preconditionFailure("The tuning is missing a perimeter palette for \(variant.base)")
        }
        return palette.map { adapted($0, variant: variant, theme: theme) }
    }

    func compactPalette(
        _ variant: AuroraColorVariant,
        theme: AuroraResolvedTheme
    ) -> CompactPalette {
        guard let palette = compactPalettes[variant.base] else {
            preconditionFailure("The tuning is missing a compact palette for \(variant.base)")
        }
        return CompactPalette(
            perimeter: palette.perimeter.map { adapted($0, variant: variant, theme: theme) },
            inner: palette.inner.map { adapted($0, variant: variant, theme: theme) }
        )
    }

    func linePalette(_ variant: AuroraColorVariant, theme: AuroraResolvedTheme) -> [LineBlob] {
        guard let palette = linePalettes[variant.base]?[theme] else {
            preconditionFailure("The tuning is missing a line palette for \(variant.base)/\(theme)")
        }
        return palette
    }

    func lineInnerPalette(
        _ variant: AuroraColorVariant,
        theme: AuroraResolvedTheme
    ) -> [LineBlob] {
        guard let palette = lineInnerPalettes[variant.base] else {
            preconditionFailure("The tuning is missing a line inner palette for \(variant.base)")
        }
        return palette.map { blob in
            var blob = blob
            blob.color = adapted(blob.color, variant: variant, theme: theme)
            return blob
        }
    }

    func lineBloomBlobs(
        _ variant: AuroraColorVariant,
        theme: AuroraResolvedTheme
    ) -> [LineBloomBlob] {
        guard let blobs = line.bloomBlobs[variant.base]?[theme] else {
            preconditionFailure("The tuning is missing line bloom blobs for \(variant.base)/\(theme)")
        }
        return blobs
    }

    // MARK: Appearance adaptation

    /// How much darker the achromatic structure is on a light appearance.
    ///
    /// It is authored once, as a *light* glow. That is right on a dark surface and nearly invisible on a
    /// light one, where the effect has to deepen rather than brighten — every other part of the light
    /// tuning does exactly that, which is why the masks tint with black.
    ///
    /// The value is not a guess. Two tables already ship per-appearance greys — `linePalettes` and the
    /// line bloom blobs — and they encode the intended relationship: their light greys sit at 0.487 and
    /// 0.488 of their dark counterparts on average, across sixteen pairs. Half is what the design says.
    static let neutralLightBrightnessScale = 0.5

    /// Adapts a palette colour to the appearance.
    ///
    /// Only the achromatic base on a light appearance is affected, which covers every ``tinted`` and
    /// ``multiColor`` variant: the darkening happens before the caller's hue is multiplied in, so the hue
    /// arrives unchanged and only its brightness moves. ``AuroraColorVariant/glow`` carries its own
    /// hues and reads correctly against either surface, and the tables that already ship per-appearance
    /// greys never reach here — they would be darkened twice.
    private func adapted(
        _ color: AuroraColor,
        variant: AuroraColorVariant,
        theme: AuroraResolvedTheme
    ) -> AuroraColor {
        guard variant.base == .neutral, theme == .light else { return color }
        return color.scalingBrightness(by: Self.neutralLightBrightnessScale)
    }

    private func adapted(
        _ blob: PaletteBlob,
        variant: AuroraColorVariant,
        theme: AuroraResolvedTheme
    ) -> PaletteBlob {
        var blob = blob
        blob.color = adapted(blob.color, variant: variant, theme: theme)
        return blob
    }

    /// The cycle the pulse oscillator tables were authored against.
    ///
    /// Every period and phase offset in those tables is an absolute number of seconds, so the only way
    /// `pulseDuration` can act as a speed control is to divide by a reference that stays put:
    /// `duration / pulseReferenceDuration` shrinks every period uniformly, which changes the tempo and
    /// leaves the shape of the motion alone.
    ///
    /// A fixed constant rather than `defaults.pulseDuration`, and that distinction is load-bearing. Fold the
    /// two together and the scale is *always* exactly 1 — retuning `pulseDuration` then moves both sides of
    /// the division and silently changes nothing at all.
    package var pulseReferenceDuration: Double { Self.pulseOscillatorReference }

    /// Do not retune this to chase a speed change: it records what the tables were authored at, so moving it
    /// re-interprets every period in them. `defaults.pulseDuration` is the speed control.
    static let pulseOscillatorReference = 2.3
}
