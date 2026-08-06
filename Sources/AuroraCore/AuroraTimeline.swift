import Foundation

/// Samples the keyframe tracks the effect's motion is built from.
///
/// The tuned motion is expressed as keyframe tracks — a sorted list of
/// `(fractionThroughCycle, value)` stops per animated parameter — and the effect interpolates
/// between adjacent stops. Sampling those tracks directly is deliberate: `withAnimation` and a
/// spring would look plausible and be wrong, and the bottom-edge preset runs five independent
/// tracks at different duration multiples off one time base, which is awkward to express as
/// implicit animations.
///
/// Every function here is pure and takes time explicitly. That is what lets a renderer freeze the
/// effect for Reduce Motion, and lets tests pin an exact frame.
public enum AuroraTimeline {
    /// The timing curves the tuned tracks reference.
    public enum Easing: Hashable, Sendable {
        case linear
        case easeInOut

        /// Maps linear `0...1` progress onto the eased curve.
        func applied(to progress: Double) -> Double {
            switch self {
            case .linear:
                progress
            case .easeInOut:
                // Between two adjacent stops a cosine ramp is visually indistinguishable from a
                // cubic ease-in-out and needs no solver.
                (1 - cos(.pi * progress)) / 2
            }
        }
    }

    /// Wraps `time` into `0..<period` and returns it as a `0...1` phase.
    ///
    /// Negative inputs wrap correctly — `phase(at: -1, period: 4) == 0.75` — which is what makes a
    /// negative phase offset behave as a head start.
    public static func phase(at time: Double, period: Double) -> Double {
        guard period > 0 else { return 0 }
        let cycles = time / period
        return cycles - cycles.rounded(.down)
    }

    /// Cosine ease-in-out factor in `0...1`: `0` at phase 0 and 1, `1` at phase 0.5.
    ///
    /// Both the breathing oscillators and the sweeping presets' hue drift are built on this.
    public static func pingPong(_ phase: Double) -> Double {
        (1 - cos(2 * .pi * phase)) / 2
    }

    /// Interpolates a keyframe track at a `0...1` phase.
    ///
    /// Phases outside a track's range clamp to its endpoints, which is the right behavior for the
    /// tracks that deliberately do not span the full cycle.
    package static func sample(_ track: [Keyframe], phase: Double, easing: Easing) -> Double {
        guard let first = track.first else { return 0 }
        guard track.count > 1, let last = track.last else { return first.value }

        if phase <= first.position { return first.value }
        if phase >= last.position { return last.value }

        // Tracks are short (5–11 stops) and sorted, so a linear scan beats the complexity of a
        // binary search here.
        for index in 1..<track.count {
            let upper = track[index]
            guard phase <= upper.position else { continue }
            let lower = track[index - 1]
            let span = upper.position - lower.position
            guard span > 0 else { return upper.value }
            let eased = easing.applied(to: (phase - lower.position) / span)
            return lower.value + (upper.value - lower.value) * eased
        }
        return last.value
    }

    /// Value of a keyframe track at `time`, given the track's own period.
    package static func sample(
        _ track: [Keyframe],
        at time: Double,
        period: Double,
        easing: Easing
    ) -> Double {
        sample(track, phase: phase(at: time, period: period), easing: easing)
    }
}

// MARK: - Activation fade

extension AuroraTimeline {
    /// Progress of the activation fade, in `0...1`.
    ///
    /// The effect ramps in over `fadeInSeconds` when it activates and out over `fadeOutSeconds` when
    /// it deactivates, notifying the host once each ramp finishes. Modelling it as a pure function of
    /// "how long since the active flag last changed" keeps the renderers from owning animation state,
    /// so the same value drives the SwiftUI and UIKit paths identically.
    public static func fadeOpacity(
        isActive: Bool,
        secondsSinceChange: Double,
        fadeInSeconds: Double,
        fadeOutSeconds: Double
    ) -> Double {
        let duration = isActive ? fadeInSeconds : fadeOutSeconds
        guard duration > 0 else { return isActive ? 1 : 0 }
        let progress = min(max(secondsSinceChange / duration, 0), 1)
        let eased = progress * progress * (3 - 2 * progress) // smoothstep
        return isActive ? eased : 1 - eased
    }
}
