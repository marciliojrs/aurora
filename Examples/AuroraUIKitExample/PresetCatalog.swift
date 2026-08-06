import Aurora
import UIKit

/// The knobs shared between the preset list and each preset's detail screen.
///
/// A reference type held by the list and handed to each pushed screen, so a palette picked on one
/// preset is still selected when you open another. That is what you want when comparing presets.
final class DemoSettings {
    var paletteKind: PaletteKind = .glow
    var tint: Tint = .none
    var combination: Combination = .cool
    var appearance: Appearance = .system
    var strength: Double = 1

    /// The variant the segmented controls currently add up to.
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

    /// What the segmented controls add up to.
    ///
    /// Note what is *not* here: the preset and the outline, which belong to whichever view is being
    /// decorated. UIKit has no environment to carry a style down a hierarchy, so this is held in one place
    /// and handed to each `addAurora` call — the same split, moved by hand.
    var style: AuroraStyle {
        AuroraStyle(
            colorVariant: palette,
            theme: appearance.auroraTheme,
            strength: strength
        )
    }

    /// The three shapes `AuroraColorVariant` comes in.
    ///
    /// `Int`-backed so a `UISegmentedControl` index maps straight onto a case.
    enum PaletteKind: Int, CaseIterable {
        case glow
        case tinted
        case multiColor

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
    enum Tint: Int, CaseIterable {
        case none
        case iris
        case moss
        case amber
        case rose

        var label: String {
            switch self {
            case .none: "None"
            case .iris: "Iris"
            case .moss: "Moss"
            case .amber: "Amber"
            case .rose: "Rose"
            }
        }

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
    enum Combination: Int, CaseIterable {
        case cool
        case warm
        case duo

        var label: String {
            switch self {
            case .cool: "Cool"
            case .warm: "Warm"
            case .duo: "Duo"
            }
        }

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

    enum Appearance: Int, CaseIterable {
        case system
        case dark
        case light

        var label: String {
            switch self {
            case .system: "System"
            case .dark: "Dark"
            case .light: "Light"
            }
        }

        /// `.unspecified` is how UIKit is told to inherit, which is what "follow the device" means.
        var interfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .system: .unspecified
            case .dark: .dark
            case .light: .light
            }
        }

        /// ``AuroraTheme/auto`` reads the view's own traits, so it keeps working when the device changes
        /// underneath.
        var auroraTheme: AuroraTheme {
            switch self {
            case .system: .auto
            case .dark: .dark
            case .light: .light
            }
        }

        var note: String {
            switch self {
            case .system: "theme: .auto — change the device appearance and the glow re-tunes live."
            case .dark: "theme: .dark — pinned, ignoring the device."
            case .light: "theme: .light — pinned, ignoring the device."
            }
        }
    }
}

/// One row in the preset list, and the subject its detail screen builds.
struct Preset {
    let size: AuroraSize
    /// The outline this preset's subject is clipped to.
    ///
    /// Paired with the preset here because the two travel together in this demo, but they are separate
    /// choices: the shape belongs to the host. `compact` uses ``AuroraShape/capsule`` and needs no radius.
    let shape: AuroraShape
    /// Whether this subject asks the library to trace its outline.
    let showsBorder: Bool
    let name: String
    let blurb: String
    let symbol: String

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
