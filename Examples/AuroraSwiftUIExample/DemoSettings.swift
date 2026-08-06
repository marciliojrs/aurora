import Aurora
import SwiftUI

/// The knobs shared between the preset list and each preset's detail screen.
///
/// One `@Observable` owned at the app root rather than `@State` duplicated per screen: pick a palette
/// on one preset's screen, go back, open another, and the choice is still there. That is what you want
/// when comparing presets, and it is the reason this is a reference type at all.
@Observable
final class DemoSettings {
    var paletteKind: PaletteKind = .glow
    var tint: Tint = .none
    var combination: Combination = .cool
    var appearance: Appearance = .system
    var strength: Double = 1

    /// The variant the pickers currently add up to.
    ///
    /// Assembled rather than stored, because the three cases each need different extra input and only
    /// one of them is on screen at a time.
    var palette: AuroraColorVariant {
        switch paletteKind {
        case .glow: .glow
        case .tinted: .tinted(tint.color)
        case .multiColor: combination.variant
        }
    }

    /// What the pickers add up to, ready to hand to `auroraStyle(_:)`.
    ///
    /// Note what is *not* here: the preset and the outline. Those belong to whichever view is being
    /// decorated, which is exactly the split ``AuroraStyle`` exists to make. One `.auroraStyle(...)` at the
    /// top of the screen restyles every glow inside it, and no subject view mentions a colour.
    var style: AuroraStyle {
        AuroraStyle(
            colorVariant: palette,
            theme: appearance.auroraTheme,
            strength: strength
        )
    }

    /// The three shapes `AuroraColorVariant` comes in.
    enum PaletteKind: String, CaseIterable, Identifiable {
        case glow
        case tinted
        case multiColor

        var id: Self { self }

        var label: String {
            switch self {
            case .glow: "Glow"
            case .tinted: "Tinted"
            case .multiColor: "Multi"
            }
        }

        var note: String {
            switch self {
            case .glow:
                ".glow — the authored spectrum. Its hue drifts as the light travels."
            case .tinted:
                ".tinted(_:) — one hue through the palette. Held still rather than drifted."
            case .multiColor:
                ".multiColor(_:) — hues dealt across the blobs, and free to drift."
            }
        }
    }

    /// Hues for ``AuroraColorVariant/tinted(_:)``.
    ///
    /// `None` is white, which multiplied through grey leaves grey — the same thing
    /// ``AuroraColorVariant/neutral`` names.
    enum Tint: String, CaseIterable, Identifiable {
        case none
        case iris
        case moss
        case amber
        case rose

        var id: Self { self }
        var label: String { self == .none ? "None" : rawValue.capitalized }

        var color: AuroraColor {
            switch self {
            case .none: .white
            case .iris: AuroraColor(r: 70, g: 140, b: 255)
            case .moss: AuroraColor(r: 80, g: 200, b: 140)
            case .amber: AuroraColor(r: 255, g: 170, b: 60)
            case .rose: AuroraColor(r: 255, g: 90, b: 150)
            }
        }
    }

    /// Combinations for ``AuroraColorVariant/multiColor(_:)``.
    ///
    /// `Cool` and `Warm` are the values Aurora ships. `Duo` is only two colors, which makes the dealing
    /// plain to see: the ring alternates between them blob by blob.
    enum Combination: String, CaseIterable, Identifiable {
        case cool
        case warm
        case duo

        var id: Self { self }
        var label: String { rawValue.capitalized }

        var variant: AuroraColorVariant {
            switch self {
            case .cool: .cool
            case .warm: .warm
            case .duo: .multiColor([
                AuroraColor(r: 80, g: 200, b: 140),
                AuroraColor(r: 255, g: 90, b: 150),
            ])
            }
        }
    }

    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case dark
        case light

        var id: Self { self }
        var label: String { rawValue.capitalized }

        /// `nil` means "no preference", which is how SwiftUI is told to follow the device.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .dark: .dark
            case .light: .light
            }
        }

        /// ``AuroraTheme/auto`` reads the surrounding scheme, so it keeps working when the device
        /// changes underneath. Pinning is the exception, and it is here only because comparing the two
        /// tunings side by side is genuinely useful.
        var auroraTheme: AuroraTheme {
            switch self {
            case .system: .auto
            case .dark: .dark
            case .light: .light
            }
        }
    }
}

/// One row in the preset list, and the subject its detail screen builds.
struct Preset: Identifiable, Hashable {
    let size: AuroraSize
    /// The outline this preset's subject is clipped to.
    ///
    /// Paired with the preset here because the two travel together in this demo, but they are separate
    /// choices: the shape belongs to the host, not the preset. `compact` uses ``AuroraShape/capsule`` and
    /// so needs no radius at all.
    let shape: AuroraShape
    /// Whether this subject asks the library to trace its outline.
    let showsBorder: Bool
    let name: String
    let blurb: String
    let symbol: String

    var id: AuroraSize { size }

    static let all: [Preset] = [
        Preset(
            size: .regular,
            shape: .rounded(cornerRadius: 20),
            showsBorder: true,
            name: "regular",
            blurb: "A band of light sweeps the whole border. The default.",
            symbol: "rectangle.dashed"
        ),
        Preset(
            size: .compact,
            shape: .capsule,
            showsBorder: false,
            name: "compact",
            blurb: "The same sweep, retuned for something button-sized.",
            symbol: "capsule"
        ),
        Preset(
            size: .underline,
            shape: .rounded(cornerRadius: 14),
            showsBorder: false,
            name: "underline",
            blurb: "Bottom edge only. Pairs with a focused text field.",
            symbol: "text.cursor"
        ),
        Preset(
            size: .pulseOutward,
            shape: .rounded(cornerRadius: 28),
            showsBorder: false,
            name: "pulseOutward",
            blurb: "Breathes past the bounds as an uncropped halo.",
            symbol: "smallcircle.filled.circle"
        ),
        Preset(
            size: .pulseInward,
            shape: .rounded(cornerRadius: 20),
            showsBorder: false,
            name: "pulseInward",
            blurb: "Breathes inside the border. Nothing travels.",
            symbol: "square.inset.filled"
        ),
    ]
}
