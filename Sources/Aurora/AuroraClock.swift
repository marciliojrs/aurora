import SwiftUI

/// Whether the glow runs on a live clock or a pinned one.
///
/// The effect normally reads a monotonic clock and advances every frame, which makes it hard to
/// capture reproducibly: a snapshot lands on whatever phase the animation happened to reach, and a
/// single-pass rasterization such as `ImageRenderer` catches the very first frame, where the
/// fade-in has not started and the glow is legitimately invisible.
///
/// Freezing pins the phase *and* treats the activation ramp as finished, so one pass renders a
/// fully faded-in glow at a chosen instant.
///
/// Modelled as a type rather than a bare `Double?` because `@Environment` cannot disambiguate an
/// optional value from its observable-object overload, and because `.frozen(at:)` reads better at
/// the call site than a raw number.
public struct AuroraClock: Equatable, Sendable {
    /// Pinned timestamp in seconds, or `nil` to follow the live clock.
    public let frozenSeconds: Double?

    /// Advances every frame. The default.
    public static let live = AuroraClock(frozenSeconds: nil)

    /// Pins the glow to one instant.
    ///
    /// Choose the instant with care for ``AuroraSize/underline``: its edge fade sits at zero for the
    /// first eighth of the cycle, so freezing near zero renders nothing at all. Pick something
    /// between 33% and 67% of the duration.
    public static func frozen(at seconds: Double) -> AuroraClock {
        AuroraClock(frozenSeconds: seconds)
    }

    private init(frozenSeconds: Double?) {
        self.frozenSeconds = frozenSeconds
    }
}

extension EnvironmentValues {
    /// The clock driving every glow in this subtree.
    public var auroraClock: AuroraClock {
        get { self[ClockKey.self] }
        set { self[ClockKey.self] = newValue }
    }
}

private struct ClockKey: EnvironmentKey {
    static let defaultValue = AuroraClock.live
}

extension View {
    /// Pins every glow in this subtree to one instant, for a reproducible capture.
    ///
    /// ```swift
    /// let renderer = ImageRenderer(
    ///     content: CardView()
    ///         .aurora(.regular, cornerRadius: 20)
    ///         .auroraClockFrozen(at: 0.98)
    /// )
    /// ```
    public func auroraClockFrozen(at seconds: Double) -> some View {
        environment(\.auroraClock, .frozen(at: seconds))
    }
}
