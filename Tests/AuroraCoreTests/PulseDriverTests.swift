import Foundation
import Testing

@testable import AuroraCore

@Suite("Breathing oscillators")
struct PulseDriverTests {
    private func tuning(
        size: AuroraSize = .pulseInward,
        theme: AuroraResolvedTheme = .dark
    ) throws -> PulseThemeTuning {
        try #require(Tuning.standard.pulse.themeTuning(for: size, theme: theme))
    }

    // MARK: Tempo

    /// The scale has to move the clock, and move it *uniformly*.
    ///
    /// Every period and offset is multiplied by it, so halving the scale halves the time to any given frame:
    /// `t` under a 0.5 scale must land on exactly what `2t` lands on at full scale. Asserting that identity
    /// rather than "the frames differ" is what proves the whole oscillator bank scaled together — one
    /// oscillator left unscaled would still produce different frames and pass a weaker test.
    @Test("Halving the duration scale halves the time to the same frame")
    func durationScaleIsUniform() throws {
        let tuning = try tuning()
        let full = PulseDriver(tuning: tuning, durationScale: 1, staticColors: true)
        let half = PulseDriver(tuning: tuning, durationScale: 0.5, staticColors: true)

        for time in [0.3, 0.7, 1.9] {
            #expect(half.frame(at: time) == full.frame(at: time * 2), "scale broke at \(time)")
        }
    }

    /// The breathing presets run faster than the cycle their tables were authored at, and the *mechanism* is
    /// that the reference is a fixed constant rather than an alias of the duration.
    ///
    /// This is the regression guard. Point `pulseReferenceDuration` back at `defaults.pulseDuration` and the
    /// scale collapses to exactly 1 for every duration — retuning the speed would then change nothing, with
    /// nothing failing to say so.
    @Test("The pulse duration is a real speed control, not a no-op")
    func pulseDurationScalesTheClock() {
        let tuning = Tuning.standard
        let scale = tuning.defaults.pulseDuration / tuning.pulseReferenceDuration
        #expect(scale != 1, "the duration and its reference are coupled again")
        #expect(scale < 1, "the pulse presets should run faster than their authoring reference")

        for size in [AuroraSize.pulseInward, .pulseOutward] {
            #expect(tuning.defaults.duration(for: size) == tuning.defaults.pulseDuration)
        }
    }

    /// Each oscillator drives a typed target, so the compiler guarantees the routing is exhaustive.
    /// What is still worth checking is that the *table* covers all of them — a missing entry would
    /// leave that part of the breathing at its neutral default, so the motion would go absent rather
    /// than look wrong.
    @Test("Every target is driven by an oscillator")
    func everyTargetIsDriven() throws {
        let driver = PulseDriver(tuning: try tuning(), durationScale: 1, staticColors: false)
        let frame = driver.frame(at: 1.234)

        #expect(frame.widthByRegion.count == PulseRegion.allCases.count)
        #expect(frame.heightByRegion.count == PulseRegion.allCases.count)
        #expect(frame.driftXByRegion.count == PulseRegion.allCases.count)
        #expect(frame.driftYByRegion.count == PulseRegion.allCases.count)
        #expect(frame.opacityByQuadrant.count == PulseQuadrant.allCases.count)
    }

    @Test("Oscillator values stay inside their tuned bounds")
    func valuesStayInBounds() throws {
        let themeTuning = try tuning()
        let driver = PulseDriver(tuning: themeTuning, durationScale: 1, staticColors: false)

        for step in 0..<400 {
            let frame = driver.frame(at: Double(step) * 0.05)
            for oscillator in themeTuning.oscillators {
                let value = frame.value(for: oscillator.target)
                #expect(value >= min(oscillator.from, oscillator.to) - 1e-9)
                #expect(value <= max(oscillator.from, oscillator.to) + 1e-9)
            }
        }
    }

    /// Quadrant oscillators carry offsets specifically so the four corners do not brighten together. If
    /// they collapsed onto one phase, the effect would read as the whole frame blinking instead of
    /// light moving around it.
    @Test("Quadrant opacities are desynced from one another")
    func quadrantsAreDesynced() throws {
        let driver = PulseDriver(tuning: try tuning(), durationScale: 1, staticColors: false)
        let frame = driver.frame(at: 3.7)
        let distinct = Set(frame.opacityByQuadrant.values.map { ($0 * 1000).rounded() })
        #expect(distinct.count > 1)
    }

    /// Regions carry different periods for the same reason, one level up: three blobs breathing in
    /// lockstep read as one object scaling.
    @Test("Region sizes are desynced from one another")
    func regionsAreDesynced() throws {
        let driver = PulseDriver(tuning: try tuning(), durationScale: 1, staticColors: false)
        let frame = driver.frame(at: 2.4)
        let distinct = Set(frame.widthByRegion.values.map { ($0 * 1000).rounded() })
        #expect(distinct.count > 1)
    }

    @Test("Hue sweeps a full circle over its period")
    func hueSweepsFullCircle() throws {
        let themeTuning = try tuning()
        let driver = PulseDriver(tuning: themeTuning, durationScale: 1, staticColors: false)
        let period = themeTuning.parameters.huePeriod

        #expect(abs(driver.frame(at: 0).hueRotationDegrees) < 1e-9)
        #expect(abs(driver.frame(at: period / 2).hueRotationDegrees - 180) < 1e-6)
        // Wrapping back to zero rather than climbing keeps a long-lived view from accumulating an
        // ever-growing rotation.
        #expect(abs(driver.frame(at: period).hueRotationDegrees) < 1e-6)
    }

    @Test("Static colors pin the hue at zero")
    func staticColorsPinHue() throws {
        let driver = PulseDriver(tuning: try tuning(), durationScale: 1, staticColors: true)
        #expect(driver.frame(at: 5.5).hueRotationDegrees == 0)
    }

    /// The periods are tuned at one reference duration, so a caller-supplied duration has to scale them
    /// uniformly. Doubling the duration should reach the same point in the cycle at twice the elapsed
    /// time.
    @Test("Duration scaling stretches every period uniformly")
    func durationScalingStretchesPeriods() throws {
        let themeTuning = try tuning()
        let normal = PulseDriver(tuning: themeTuning, durationScale: 1, staticColors: true)
        let slow = PulseDriver(tuning: themeTuning, durationScale: 2, staticColors: true)

        let reference = normal.frame(at: 1.1)
        let stretched = slow.frame(at: 2.2)
        for region in PulseRegion.allCases {
            #expect(abs(reference.width(region) - stretched.width(region)) < 1e-9)
            #expect(abs(reference.driftX(region) - stretched.driftX(region)) < 1e-9)
        }
    }

    @Test("A non-positive duration scale falls back to unscaled periods")
    func durationScaleGuarded() throws {
        let themeTuning = try tuning()
        let guarded = PulseDriver(tuning: themeTuning, durationScale: 0, staticColors: true)
        let normal = PulseDriver(tuning: themeTuning, durationScale: 1, staticColors: true)
        #expect(guarded.frame(at: 1.5).globalHeight == normal.frame(at: 1.5).globalHeight)
    }

    @Test("Sampling snaps time onto the tuned grid")
    func quantizeSnapsToGrid() {
        // Times inside one frame of the grid collapse onto the same instant, which is what stops a
        // 120 Hz display rebuilding the gradient stack four times per visible change.
        #expect(PulseDriver.quantize(time: 1.000, sampleRate: 30) == PulseDriver.quantize(time: 1.020, sampleRate: 30))
        #expect(PulseDriver.quantize(time: 1.000, sampleRate: 30) != PulseDriver.quantize(time: 1.040, sampleRate: 30))
    }

    @Test("A non-positive sample rate leaves time untouched")
    func quantizeGuarded() {
        #expect(PulseDriver.quantize(time: 1.234, sampleRate: 0) == 1.234)
    }
}

// MARK: - Test helpers

extension PulseDriver.Frame {
    /// Reads a value back by target, mirroring ``PulseDriver/Frame/apply(_:to:)`` so bounds can be
    /// asserted against the very oscillator that produced them.
    fileprivate func value(for target: PulseTarget) -> Double {
        switch target {
        case .width(let region): width(region)
        case .height(let region): height(region)
        case .driftX(let region): driftX(region)
        case .driftY(let region): driftY(region)
        case .globalHeight: globalHeight
        case .quadrantOpacity(let quadrant): opacity(quadrant)
        }
    }
}
