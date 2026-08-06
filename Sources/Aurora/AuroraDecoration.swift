import AuroraCore
import SwiftUI

/// Draws the glow for an explicitly supplied content size, without wrapping anything.
///
/// Most callers want ``Aurora`` or `View.aurora(…)`, which measure their content and
/// place this on both sides of it. This type is the shared engine underneath, exposed because
/// a host that already owns its content view — a `UIView`, a collection view cell — cannot
/// hand SwiftUI a child to measure, but can say how big it is.
///
/// It owns the clock and the activation ramp; it deliberately does *not* own visibility.
/// Whether the glow should be running is something only the host knows, so `isPaused` is an
/// input. Inferring it from `onAppear` would be wrong inside a UIKit hierarchy, where a
/// hosted view's appearance callbacks do not track the enclosing view's visibility.
public struct AuroraDecoration: View {
    private let configuration: AuroraConfiguration
    private let contentSize: CGSize
    private let placement: AuroraLayer.Placement
    private let isActive: Bool
    private let isPaused: Bool
    private let onActivate: (() -> Void)?
    private let onDeactivate: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.auroraClock) private var clock

    @State private var activation: Activation
    /// `true` once the activation ramp has finished. Lets the clock stop entirely when the
    /// glow is off, rather than ticking forever over an empty scene.
    @State private var isSettled = false

    public init(
        configuration: AuroraConfiguration,
        contentSize: CGSize,
        placement: AuroraLayer.Placement = .aboveContent,
        isActive: Bool = true,
        isPaused: Bool = false,
        onActivate: (() -> Void)? = nil,
        onDeactivate: (() -> Void)? = nil
    ) {
        self.configuration = configuration
        self.contentSize = contentSize
        self.placement = placement
        self.isActive = isActive
        self.isPaused = isPaused
        self.onActivate = onActivate
        self.onDeactivate = onDeactivate
        _activation = State(initialValue: Activation(isActive: isActive, changedAt: .now))
    }

    public var body: some View {
        TimelineView(
            .animation(minimumInterval: minimumFrameInterval, paused: isClockStopped)
        ) { timeline in
            let scene = scene(at: timeline.date)
            SceneView(scene: scene, placement: placement)
                .modifier(ClipModifier(scene: scene))
        }
        .onChange(of: isActive) { _, newValue in
            activation = Activation(isActive: newValue, changedAt: .now)
        }
        .task(id: activation) { await settleActivation() }
    }

    // MARK: Scene

    private func scene(at date: Date) -> AuroraScene {
        let resolved = configuration.resolved(isDarkEnvironment: colorScheme == .dark)
        return AuroraSceneBuilder(configuration: resolved).scene(
            contentSize: contentSize,
            time: time(at: date, duration: resolved.duration),
            activation: activationOpacity(at: date)
        )
    }

    /// The timestamp handed to the scene builder.
    ///
    /// Whenever the clock is stopped — Reduce Motion, offscreen, or an explicitly frozen clock —
    /// the glow shows a *representative* instant rather than whatever moment it happened to stop
    /// on. Under Reduce Motion that keeps the glow present while removing the movement, which is
    /// the right trade: the glow is the component's affordance, so hiding it changes what the
    /// layout communicates rather than only how it animates.
    ///
    /// The representative instant is halfway through the cycle, not zero, and that is not
    /// arbitrary: the `underline` preset's edge fade sits at zero for the first eighth of its cycle, so
    /// stopping near the start would render nothing at all.
    private func time(at date: Date, duration: Double) -> Double {
        if let frozen = clock.frozenSeconds { return frozen }
        return isClockStopped ? duration * 0.5 : date.timeIntervalSinceReferenceDate
    }

    /// The activation fade for this frame.
    ///
    /// A stopped clock jumps to the settled value instead of ramping. The ramp is derived from
    /// elapsed time, and `TimelineView` only advances that while it is running — so reading it
    /// against a stopped clock pins the fade at its starting value of 0 and the glow never
    /// appears at all. That would make an active glow invisible under Reduce Motion, and would
    /// leave a glow that activates while offscreen blank once it scrolls back in.
    ///
    /// Snapping is also the correct behavior on its own terms: no motion means no fade, just the
    /// end state.
    private func activationOpacity(at date: Date) -> Double {
        guard isClockStopped == false else { return activation.isActive ? 1 : 0 }

        let defaults = Tuning.standard.defaults
        return AuroraTimeline.fadeOpacity(
            isActive: activation.isActive,
            secondsSinceChange: date.timeIntervalSince(activation.changedAt),
            fadeInSeconds: defaults.fadeInSeconds,
            fadeOutSeconds: defaults.fadeOutSeconds
        )
    }

    // MARK: Clock

    /// Caps the pulse presets to their tuned sample rate.
    ///
    /// Their oscillators run on roughly 1–4.2 second periods, so redrawing at the display's rate buys
    /// nothing visible and costs a full gradient rebuild per frame. The rotate and underline
    /// presets move fast enough to want every frame, so they get `nil`.
    private var minimumFrameInterval: Double? {
        guard configuration.size.family == .pulse else { return nil }
        return 1 / Tuning.standard.defaults.pulseSampleRate
    }

    private var isClockStopped: Bool {
        if isPaused || reduceMotion || clock.frozenSeconds != nil { return true }
        // Nothing left to animate once an inactive glow has finished fading out.
        return isSettled && activation.isActive == false
    }

    /// Waits out the activation ramp, then reports it.
    ///
    /// Driven by `.task(id:)` so a flag that flips mid-ramp cancels the pending notification
    /// automatically — no bookkeeping, and no callback fired for a state the view has already
    /// left.
    private func settleActivation() async {
        isSettled = false
        let defaults = Tuning.standard.defaults
        let seconds = activation.isActive ? defaults.fadeInSeconds : defaults.fadeOutSeconds
        do {
            try await Task.sleep(for: .seconds(seconds))
        } catch {
            return // Cancelled: the activation state changed again.
        }
        isSettled = true
        if activation.isActive {
            onActivate?()
        } else {
            onDeactivate?()
        }
    }
}

// MARK: - Supporting types

/// When the active flag last changed, so the fade can be derived rather than stored.
struct Activation: Hashable, Sendable {
    var isActive: Bool
    var changedAt: Date
}

/// Clips a scene to the content's shape unless the scene is meant to paint outside it.
///
/// Without this a blurred bloom bleeds past the card's corners. The one preset that is
/// *meant* to escape carries a non-zero outset and is left unclipped.
struct ClipModifier: ViewModifier {
    let scene: AuroraScene

    func body(content: Content) -> some View {
        if scene.outset.value > 0 {
            content
        } else {
            content.clipShape(
                RoundedRectangle(cornerRadius: scene.cornerRadius, style: .continuous)
            )
        }
    }
}
