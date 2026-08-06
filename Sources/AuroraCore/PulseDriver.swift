import Foundation

/// Evaluates the breathing presets' oscillators.
///
/// The breathing look comes from about fifteen desynced cosine oscillators per instance — three
/// independent size and drift regions, four per-quadrant opacities, a global height, and a hue
/// rotation. Each ping-pongs a value between two bounds over its own period, and the offsets are
/// what keep the glow from reading as a single object scaling in and out.
///
/// The oscillators are evaluated as a pure function of time rather than pushed from a display link
/// into mutable state. That means no shared mutable state to reason about under Swift concurrency,
/// and a frame that can be reproduced exactly in a test. Frame-rate capping still applies — see
/// ``quantize(time:sampleRate:)``.
///
/// Internal by design: callers configure the effect through ``AuroraConfiguration``, and the
/// scene builder owns the oscillators.
struct PulseDriver: Sendable {
    /// Oscillator values for a single frame.
    struct Frame: Hashable, Sendable {
        /// Per-region width multipliers.
        var widthByRegion: [PulseRegion: Double] = [:]
        /// Per-region height multipliers.
        var heightByRegion: [PulseRegion: Double] = [:]
        /// Per-region drift, in points.
        var driftXByRegion: [PulseRegion: Double] = [:]
        var driftYByRegion: [PulseRegion: Double] = [:]
        /// Global height multiplier, applied on top of the per-region one.
        var globalHeight: Double = 1
        /// Per-quadrant opacity multipliers.
        var opacityByQuadrant: [PulseQuadrant: Double] = [:]
        /// Continuous hue rotation, in degrees.
        var hueRotationDegrees: Double = 0

        func width(_ region: PulseRegion) -> Double { widthByRegion[region] ?? 1 }
        func height(_ region: PulseRegion) -> Double { heightByRegion[region] ?? 1 }
        func driftX(_ region: PulseRegion) -> Double { driftXByRegion[region] ?? 0 }
        func driftY(_ region: PulseRegion) -> Double { driftYByRegion[region] ?? 0 }
        func opacity(_ quadrant: PulseQuadrant) -> Double { opacityByQuadrant[quadrant] ?? 1 }

        /// Routes one oscillator's value onto the matching field.
        ///
        /// The target is a typed enum, so the compiler checks every case is handled. An earlier
        /// version keyed on parameter names and could silently drop an unrecognized one, which would
        /// have left part of the breathing missing rather than looking wrong.
        mutating func apply(_ value: Double, to target: PulseTarget) {
            switch target {
            case .width(let region): widthByRegion[region] = value
            case .height(let region): heightByRegion[region] = value
            case .driftX(let region): driftXByRegion[region] = value
            case .driftY(let region): driftYByRegion[region] = value
            case .globalHeight: globalHeight = value
            case .quadrantOpacity(let quadrant): opacityByQuadrant[quadrant] = value
            }
        }
    }

    private let oscillators: [PulseOscillator]
    private let huePeriod: Double
    private let isHueStatic: Bool
    /// `duration / tuning.pulseReferenceDuration`. Periods are tuned at the reference duration, so a
    /// caller-supplied duration scales them all uniformly.
    private let durationScale: Double

    init(tuning: PulseThemeTuning, durationScale: Double, staticColors: Bool) {
        self.oscillators = tuning.oscillators
        self.huePeriod = tuning.parameters.huePeriod
        self.isHueStatic = staticColors
        self.durationScale = durationScale > 0 ? durationScale : 1
    }

    /// Quantizes a timestamp onto the tuned sample rate.
    ///
    /// The breathing periods are authored at 1.6–6.4 seconds and land near 1–4.2 at the shipped tempo, so
    /// sampling faster than ~30 Hz changes nothing
    /// anyone can see while forcing the gradient stack to be rebuilt and repainted every display
    /// refresh. Snapping time to a 30 Hz grid means a 120 Hz ProMotion display does a quarter of
    /// that work.
    static func quantize(time: Double, sampleRate: Double) -> Double {
        guard sampleRate > 0 else { return time }
        return (time * sampleRate).rounded(.down) / sampleRate
    }

    /// Samples every oscillator at `time`, in seconds.
    func frame(at time: Double) -> Frame {
        var frame = Frame()

        for oscillator in oscillators {
            let period = oscillator.period * durationScale
            let offset = oscillator.phaseOffset * durationScale
            // A positive offset starts the oscillator later, desyncing it from its
            // otherwise-identical siblings.
            let phase = AuroraTimeline.phase(at: time - offset, period: period)
            let span = oscillator.to - oscillator.from
            frame.apply(oscillator.from + span * AuroraTimeline.pingPong(phase), to: oscillator.target)
        }

        if !isHueStatic, huePeriod > 0 {
            // The hue sweeps a *full* circle rather than drifting inside a range, so every color
            // visits every edge over time. Without it the palette stays pinned — always red at the
            // top trailing corner, always green on the left.
            frame.hueRotationDegrees = AuroraTimeline.phase(at: time, period: huePeriod) * 360
        }

        return frame
    }
}
