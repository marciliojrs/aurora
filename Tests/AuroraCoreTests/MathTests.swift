import Foundation
import Testing

@testable import AuroraCore

@Suite("Timeline")
struct AuroraTimelineTests {
    @Test("Phase wraps forward through a cycle")
    func phaseWraps() {
        #expect(AuroraTimeline.phase(at: 0, period: 4) == 0)
        #expect(AuroraTimeline.phase(at: 1, period: 4) == 0.25)
        #expect(AuroraTimeline.phase(at: 4, period: 4) == 0)
        #expect(AuroraTimeline.phase(at: 5, period: 4) == 0.25)
    }

    /// Oscillator offsets are subtracted from the current time, so negative inputs are the common
    /// case rather than an edge case. Wrapping them wrongly would desync every oscillator that
    /// carries an offset.
    @Test("Phase wraps backward, so an offset behaves as a head start")
    func phaseWrapsNegative() {
        #expect(AuroraTimeline.phase(at: -1, period: 4) == 0.75)
        #expect(AuroraTimeline.phase(at: -4, period: 4) == 0)
        #expect(AuroraTimeline.phase(at: -5, period: 4) == 0.75)
    }

    @Test("A zero period yields a fixed phase instead of dividing by zero")
    func phaseGuardsZeroPeriod() {
        #expect(AuroraTimeline.phase(at: 3, period: 0) == 0)
    }

    @Test("Ping-pong peaks at the half phase and returns to zero")
    func pingPongShape() {
        #expect(abs(AuroraTimeline.pingPong(0)) < 1e-12)
        #expect(abs(AuroraTimeline.pingPong(0.5) - 1) < 1e-12)
        #expect(abs(AuroraTimeline.pingPong(1)) < 1e-12)
        // Symmetric about the peak, which keeps a breathing blob from favouring one direction.
        #expect(abs(AuroraTimeline.pingPong(0.25) - AuroraTimeline.pingPong(0.75)) < 1e-12)
    }

    @Test("Keyframe sampling hits its stops exactly")
    func keyframeSamplingHitsStops() throws {
        let track = Tuning.standard.line.travelPosition
        let first = try #require(track.first)
        let last = try #require(track.last)
        #expect(AuroraTimeline.sample(track, phase: 0, easing: .linear) == first.value)
        #expect(AuroraTimeline.sample(track, phase: 1, easing: .linear) == last.value)
    }

    @Test("Keyframe sampling interpolates between two stops")
    func keyframeSamplingInterpolates() {
        // A synthetic track keeps the assertion independent of any tuned values.
        let track = [
            Keyframe(position: 0, value: 0),
            Keyframe(position: 1, value: 10),
        ]

        #expect(abs(AuroraTimeline.sample(track, phase: 0.5, easing: .linear) - 5) < 1e-12)
        // Ease-in-out is symmetric, so its midpoint matches linear even though its shape differs.
        #expect(abs(AuroraTimeline.sample(track, phase: 0.5, easing: .easeInOut) - 5) < 1e-12)
        // Away from the midpoint the eased curve lags the linear one.
        let easedQuarter = AuroraTimeline.sample(track, phase: 0.25, easing: .easeInOut)
        let linearQuarter = AuroraTimeline.sample(track, phase: 0.25, easing: .linear)
        #expect(easedQuarter < linearQuarter)
    }

    @Test("Phases outside a track's range clamp to its endpoints")
    func keyframeSamplingClamps() {
        // Several tracks deliberately do not span the full cycle; clamping is what keeps those
        // from wrapping mid-ramp.
        let track = Tuning.standard.line.breathe
        #expect(AuroraTimeline.sample(track, phase: -0.5, easing: .easeInOut) == track.first?.value)
    }

    @Test("The activation fade ramps in and out over its own durations")
    func fadeRamps() {
        #expect(
            AuroraTimeline.fadeOpacity(
                isActive: true, secondsSinceChange: 0, fadeInSeconds: 0.6, fadeOutSeconds: 0.5
            ) == 0
        )
        #expect(
            AuroraTimeline.fadeOpacity(
                isActive: true, secondsSinceChange: 0.6, fadeInSeconds: 0.6, fadeOutSeconds: 0.5
            ) == 1
        )
        #expect(
            AuroraTimeline.fadeOpacity(
                isActive: false, secondsSinceChange: 0, fadeInSeconds: 0.6, fadeOutSeconds: 0.5
            ) == 1
        )
        #expect(
            AuroraTimeline.fadeOpacity(
                isActive: false, secondsSinceChange: 0.5, fadeInSeconds: 0.6, fadeOutSeconds: 0.5
            ) == 0
        )
    }

    @Test("The fade stays settled past its duration rather than wrapping")
    func fadeDoesNotWrap() {
        let long = AuroraTimeline.fadeOpacity(
            isActive: true, secondsSinceChange: 60, fadeInSeconds: 0.6, fadeOutSeconds: 0.5
        )
        #expect(long == 1)
    }
}

@Suite("Color adjustment")
struct AuroraColorMatrixTests {
    @Test("A zero-degree hue rotation is the identity")
    func hueRotationIdentity() {
        let color = AuroraColor(r: 200, g: 60, b: 120)
        let rotated = AuroraColorMatrix.hueRotation(degrees: 0).applied(to: color)
        #expect(abs(rotated.red - color.red) < 1e-9)
        #expect(abs(rotated.green - color.green) < 1e-9)
        #expect(abs(rotated.blue - color.blue) < 1e-9)
    }

    /// The distinction that motivates this whole type: the adjustment must *multiply*. A
    /// SwiftUI-style additive brightness would wash the palette out instead of intensifying it.
    @Test("Brightness multiplies rather than adds")
    func brightnessMultiplies() {
        let color = AuroraColor(red: 0.4, green: 0.2, blue: 0.1)
        let brighter = AuroraColorMatrix.brightness(2).applied(to: color)
        #expect(abs(brighter.red - 0.8) < 1e-12)
        #expect(abs(brighter.green - 0.4) < 1e-12)
        #expect(abs(brighter.blue - 0.2) < 1e-12)
    }

    @Test("Brightness above 1 passes through rather than clipping")
    func brightnessExceedsUnity() {
        // Several presets drive brightness past 1. Clamping here instead of at composite time
        // would visibly dull the bloom, so the matrix has to let it through.
        #expect(AuroraColorMatrix.brightness(1.9).applied(to: .white).red > 1)
    }

    @Test("Full desaturation collapses a color onto its luminance")
    func saturationCollapses() {
        let gray = AuroraColorMatrix.saturation(0).applied(to: AuroraColor(red: 1, green: 0, blue: 0))
        #expect(abs(gray.red - gray.green) < 1e-12)
        #expect(abs(gray.green - gray.blue) < 1e-12)
        // Red's standard luminance weight.
        #expect(abs(gray.red - 0.213) < 1e-9)
    }

    @Test("No adjustment touches alpha")
    func alphaPreserved() {
        let color = AuroraColor(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.42)
        let adjusted = AuroraColorMatrix
            .adjustment(hueRotationDegrees: 47, brightness: 1.7, saturation: 1.3)
            .applied(to: color)
        #expect(abs(adjusted.alpha - 0.42) < 1e-12)
    }

    @Test("Concatenation applies the receiver first")
    func concatenationOrder() {
        // Doubling then halving returns the original.
        let roundTrip = AuroraColorMatrix.brightness(2)
            .concatenated(with: .brightness(0.5))
            .applied(to: AuroraColor(red: 0.2, green: 0.2, blue: 0.2))
        #expect(abs(roundTrip.red - 0.2) < 1e-12)

        // Desaturation runs on the *brightened* color, so the order is observable: 0.5 red
        // doubled to 1.0, then collapsed onto red's luminance weight.
        let chained = AuroraColorMatrix.brightness(2)
            .concatenated(with: .saturation(0))
            .applied(to: AuroraColor(red: 0.5, green: 0, blue: 0))
        #expect(abs(chained.red - 0.213) < 1e-9)
    }

    /// This is the property that lets the scene builder bake the adjustment into gradient stops
    /// instead of filtering composited layers at draw time. If these matrices ever gained a bias
    /// term or started touching alpha, the two would stop agreeing and every overlapping blob
    /// would shift color — so it is worth asserting rather than assuming.
    @Test("The adjustment is linear, so it commutes with source-over compositing")
    func adjustmentCommutesWithCompositing() {
        let matrix = AuroraColorMatrix.adjustment(
            hueRotationDegrees: 33, brightness: 1.4, saturation: 1.2
        )
        let source = AuroraColor(r: 255, g: 50, b: 100)
        let destination = AuroraColor(r: 40, g: 140, b: 255)
        let coverage = 0.37

        func over(_ top: AuroraColor, _ bottom: AuroraColor) -> AuroraColor {
            AuroraColor(
                red: top.red * coverage + bottom.red * (1 - coverage),
                green: top.green * coverage + bottom.green * (1 - coverage),
                blue: top.blue * coverage + bottom.blue * (1 - coverage)
            )
        }

        let adjustedAfter = matrix.applied(to: over(source, destination))
        let compositedAfter = over(matrix.applied(to: source), matrix.applied(to: destination))

        #expect(abs(adjustedAfter.red - compositedAfter.red) < 1e-12)
        #expect(abs(adjustedAfter.green - compositedAfter.green) < 1e-12)
        #expect(abs(adjustedAfter.blue - compositedAfter.blue) < 1e-12)
    }
}

@Suite("Geometry and descriptors")
struct GeometryTests {

    @Test("A length resolves both terms against its container")
    func lengthResolves() {
        #expect(AuroraLength(fraction: 0.5, points: 4).resolved(in: 100) == 54)
    }



    @Test("Scaling a size scales both the fractional and absolute terms")
    func sizeScaling() {
        let size = AuroraSizeSpec(width: AuroraLength(fraction: 0.5, points: 10), height: .points(20))
        let scaled = size.scaled(x: 0.9, y: 0.5)
        #expect(abs(scaled.width.fraction - 0.45) < 1e-12)
        #expect(abs(scaled.width.points - 9) < 1e-12)
        #expect(abs(scaled.height.points - 10) < 1e-12)
    }

    /// A blob's trailing stop keeps its color and drops only alpha. Fading toward a zeroed color
    /// instead lets the interpolator walk through dark gray, which leaves a dirty halo around
    /// every blob in the palette.
    @Test("A blob fades by alpha rather than toward a zeroed color")
    func blobFadesByAlpha() throws {
        let color = AuroraColor(r: 255, g: 50, b: 100)
        let blob = AuroraEllipseGradient.blob(
            color: color,
            center: AuroraPoint(x: .percent(50), y: .percent(50)),
            radii: .points(width: 10, height: 20)
        )
        let last = try #require(blob.stops.last)
        #expect(last.color.alpha == 0)
        #expect(last.color.red == color.red)
        #expect(last.color.green == color.green)
        #expect(last.color.blue == color.blue)
    }
}
