/// Which colors the glow draws in.
///
/// Aurora ships two authored tables, and every variant resolves to one of them. ``glow`` uses the
/// full-spectrum table as it was tuned. ``tinted`` and ``multiColor`` sit on an achromatic table whose
/// value is not its color but its *structure*: nine soft blobs with tuned positions, radii and relative
/// brightness. That relative brightness is what makes the ring read as separate pools of light rather
/// than one flat band, so caller colors are multiplied through it rather than replacing it.
///
/// ```swift
/// .aurora(configuration: AuroraConfiguration(size: .regular, colorVariant: .glow))
/// .aurora(configuration: AuroraConfiguration(size: .regular, colorVariant: .tinted(brandBlue)))
/// .aurora(configuration: AuroraConfiguration(size: .regular, colorVariant: .multiColor([teal, indigo])))
/// ```
///
/// ``neutral``, ``cool`` and ``warm`` are ready-made values built on these three.
public enum AuroraColorVariant: Hashable, Sendable {
    /// The authored full-spectrum palette. The default.
    ///
    /// Its hue drifts within ``AuroraConfiguration/hueRange``, which is what the spectrum was tuned for.
    case glow

    /// One color, multiplied through the achromatic structure.
    ///
    /// Every blob keeps its own brightness, so only the hue changes. The hue is held still rather than
    /// drifting: you named a color, so Aurora does not walk away from it.
    ///
    /// A fully opaque white leaves the structure achromatic, which is what ``neutral`` is.
    case tinted(AuroraColor)

    /// Several colors, dealt across the palette's blobs in order and repeating as needed.
    ///
    /// Two colors alternate; nine land one per blob. Order follows the palette's own order, which runs
    /// roughly clockwise from the top edge.
    ///
    /// Like ``glow``, the hue drifts within ``AuroraConfiguration/hueRange``, since several hues read
    /// as a palette that can move. Pass `hueRange: 0` to hold your colors exactly.
    ///
    /// An empty array means no color at all and leaves the structure achromatic — the same result as
    /// ``neutral``, reached by accident rather than on purpose. It is handled rather than trapped so a
    /// computed color list cannot crash a view.
    case multiColor([AuroraColor])
}

// MARK: - Ready-made values

extension AuroraColorVariant {
    /// Achromatic.
    ///
    /// White multiplied through grey is that grey, so this is the structure with nothing added.
    public static let neutral: Self = .tinted(.white)

    /// Blues and violets.
    ///
    /// A combination rather than a separately authored palette: these are the hues of the old blue-violet
    /// table, each raised to full brightness so the structure's own brightness supplies the shading.
    public static let cool: Self = .multiColor([
        AuroraColor(r: 116, g: 93, b: 255),
        AuroraColor(r: 60, g: 120, b: 255),
        AuroraColor(r: 102, g: 128, b: 255),
        AuroraColor(r: 58, g: 162, b: 255),
        AuroraColor(r: 120, g: 80, b: 255),
        AuroraColor(r: 70, g: 130, b: 255),
        AuroraColor(r: 149, g: 106, b: 255),
        AuroraColor(r: 100, g: 122, b: 255),
        AuroraColor(r: 130, g: 70, b: 255),
    ])

    /// Ambers, oranges and reds.
    public static let warm: Self = .multiColor([
        AuroraColor(r: 255, g: 80, b: 50),
        AuroraColor(r: 255, g: 160, b: 40),
        AuroraColor(r: 255, g: 120, b: 60),
        AuroraColor(r: 255, g: 200, b: 50),
        AuroraColor(r: 255, g: 100, b: 80),
        AuroraColor(r: 255, g: 180, b: 60),
        AuroraColor(r: 255, g: 60, b: 60),
        AuroraColor(r: 255, g: 140, b: 50),
        AuroraColor(r: 255, g: 90, b: 70),
    ])
}

// MARK: - Resolution

extension AuroraColorVariant {
    /// Which authored table this variant takes its structure from.
    var base: PaletteBase {
        switch self {
        case .glow: .spectrum
        case .tinted, .multiColor: .neutral
        }
    }

    /// The hue for one element of the palette, or `nil` to leave it as authored.
    ///
    /// The index is the element's position in its own table, so a combination spreads across the blobs
    /// instead of collapsing onto one of them.
    func hue(at index: Int) -> AuroraColor? {
        switch self {
        case .glow:
            nil
        case .tinted(let color):
            color
        case .multiColor(let colors):
            // A negative index cannot arise from `enumerated()`, but `%` would return one if it did.
            colors.isEmpty ? nil : colors[abs(index) % colors.count]
        }
    }

    /// `true` when the palette resolves to a single hue across every blob.
    ///
    /// Two tuned reductions hang off this, and both exist for the same reason. The achromatic table is
    /// uniformly bright by design; one hue over it keeps that uniformity, and a uniformly bright ring at
    /// full opacity reads as a hard band rather than a glow. So a uniform palette is dimmed on dark
    /// appearances, and its hue is held still — drifting a color the caller named is a surprise, and
    /// there is nothing to gain when every blob shares it.
    ///
    /// Several hues break the uniformity by themselves, so neither reduction applies to them.
    var isUniform: Bool {
        switch self {
        case .glow: false
        case .tinted: true
        case .multiColor(let colors): colors.count <= 1
        }
    }

    /// Halves every layer opacity for a uniform palette on a dark appearance.
    ///
    /// Light appearances are exempt, and the asymmetry is the point. There the structure deepens with a
    /// dark grey instead of brightening with a pale one, so there is no glare to tame; meanwhile the
    /// light opacity presets are already far lower than their dark counterparts (`regular` stroke 0.12
    /// against 0.26). Halving those as well drops the effect to 0.06, where it disappears against
    /// the card.
    func opacityMultiplier(_ tuning: Tuning, theme: AuroraResolvedTheme) -> Double {
        isUniform && theme == .dark ? tuning.defaults.uniformOpacityMultiplier : 1
    }

    /// A uniform palette skips the hue animation. See ``isUniform``.
    func forcesStaticColors(_ tuning: Tuning) -> Bool {
        isUniform && tuning.defaults.uniformPaletteHoldsHue
    }
}

/// Which authored table a variant draws its structure from.
///
/// The tuning is keyed by this rather than by ``AuroraColorVariant``, which carries caller colors and so
/// has no finite set of values to tabulate.
enum PaletteBase: CaseIterable, Hashable, Sendable {
    /// The authored hues, used as they are.
    case spectrum
    /// Position, radii and relative brightness, with no hue of its own. Recolored by the caller.
    case neutral
}
