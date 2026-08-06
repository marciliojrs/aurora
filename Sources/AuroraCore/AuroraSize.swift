/// Which preset to draw.
///
/// The five presets fall into three families that animate in completely different
/// ways, which is why ``family`` exists: almost every branch in the scene builder
/// keys off the family rather than the individual case.
///
/// Rotate family — a traveling glow sweeps the whole border:
/// - ``compact``: button-sized glow, tuned for controls.
/// - ``regular``: full border glow, the default.
///
/// Underline family — a glow travels a single edge:
/// - ``underline``: bottom edge only, with breathe and spike motion.
///
/// Pulse family — the glow breathes in place, nothing travels:
/// - ``pulseOutward``: blooms past the host's bounds as an uncropped halo.
/// - ``pulseInward``: breathes contained inside the host's border.
///
/// Deliberately not `RawRepresentable`. The tuning tables are keyed by the case
/// itself, so a string form would be a second spelling of every preset with
/// nothing to keep the two in step.
public enum AuroraSize: CaseIterable, Hashable, Sendable {
    case compact
    case regular
    case underline
    case pulseOutward
    case pulseInward

    /// How a preset animates. Determines layer composition and which clock drives it.
    public enum Family: Hashable, Sendable {
        /// A conic mask rotates around the border, revealing a static color ring.
        case rotate
        /// A blob travels along the bottom edge.
        case underline
        /// Desynced cosine oscillators breathe the glow in place.
        case pulse
    }

    public var family: Family {
        switch self {
        case .compact, .regular: .rotate
        case .underline: .underline
        case .pulseOutward, .pulseInward: .pulse
        }
    }

    /// `true` when the effect paints outside the host's bounds and therefore must
    /// not be clipped to them.
    public var bloomsOutward: Bool { self == .pulseOutward }
}
