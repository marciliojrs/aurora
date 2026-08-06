import CoreGraphics

/// The outline the glow traces.
///
/// This replaces passing a corner radius. A radius is a number the caller has to keep in step with the
/// `clipShape` or `layer.cornerRadius` they already wrote, and nothing checks that they did. Worse, the
/// right number is not always knowable up front: a capsule's radius is half its height, so a control that
/// grows with Dynamic Type has a radius that changes at layout time.
///
/// Describing the shape instead defers the arithmetic to the moment the host has been measured, which is
/// the only moment it can be right.
///
/// ```swift
/// Text("Summarise")
///     .padding(.horizontal, 20)
///     .background(.fill, in: .capsule)
///     .aurora(.compact, in: .capsule)   // no arithmetic, and correct at any height
/// ```
///
/// Every case is clamped to half the host's short side, so a radius can never exceed what the outline can
/// actually hold.
public enum AuroraShape: Hashable, Sendable {
    /// The preset's own tuned radius. The default, and the right choice only when the host is not
    /// clipped to something else.
    case preset

    /// A rounded rectangle. Pass the same radius the host is clipped to.
    ///
    /// Named after `RoundedRectangle(cornerRadius:)`, so it reads as the shape you already wrote rather
    /// than as a second vocabulary for it. Square corners are `.rounded(cornerRadius: 0)` — no separate
    /// case, because there is no separate arithmetic.
    case rounded(cornerRadius: Double)

    /// Fully rounded on the short axis: half of whichever side is smaller.
    ///
    /// Covers circles too. A square host rounded on its short axis *is* a circle, so there is one case
    /// here rather than two names for the same arithmetic.
    case capsule

    /// The radius to trace for a host of this size.
    ///
    /// - Parameter presetCornerRadius: What ``preset`` resolves to, which only the tuning knows.
    public func cornerRadius(for size: CGSize, presetCornerRadius: Double) -> Double {
        let maximum = min(size.width, size.height) / 2
        switch self {
        case .preset:
            // Clamped like an explicit radius: the tuned default suits a card, and on a 32pt-tall field
            // it would otherwise exceed the host.
            return min(presetCornerRadius, maximum)
        case .rounded(let cornerRadius):
            // A radius past half the host inverts the corner arcs and the ring crosses itself. Clamping
            // turns a caller's 40 on a 32pt field into a capsule rather than into a mess.
            return min(max(cornerRadius, 0), maximum)
        case .capsule:
            return maximum
        }
    }
}
