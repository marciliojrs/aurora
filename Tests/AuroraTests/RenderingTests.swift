import CoreGraphics
import SwiftUI
import Testing

@testable import Aurora
@testable import AuroraCore

/// A named palette to rasterize.
///
/// `AuroraColorVariant` carries caller colors, so it has no `allCases` for `arguments:` to walk. Declared
/// at file scope because `@Test(arguments:)` evaluates its arguments outside the suite, and this suite is
/// `@MainActor`. `AuroraCoreTests` has its own copy — separate test targets, no shared module.
struct PaletteSample: Sendable, CustomTestStringConvertible {
    let name: String
    let variant: AuroraColorVariant

    var testDescription: String { name }
}

let paletteSamples: [PaletteSample] = [
    PaletteSample(name: "glow", variant: .glow),
    PaletteSample(name: "neutral", variant: .neutral),
    PaletteSample(name: "tinted", variant: .tinted(AuroraColor(r: 60, g: 120, b: 255))),
    PaletteSample(
        name: "multiColor",
        variant: .multiColor([
            AuroraColor(r: 80, g: 200, b: 140),
            AuroraColor(r: 255, g: 170, b: 60),
        ])
    ),
    PaletteSample(name: "multiColor(empty)", variant: .multiColor([])),
    PaletteSample(name: "cool", variant: .cool),
    PaletteSample(name: "warm", variant: .warm),
]

/// Rasterizes real frames and checks that pixels arrive.
///
/// These exist because the package once built cleanly, passed every unit test, and drew nothing at
/// all. `AuroraCoreTests` asserts what the scene builder *decides*; a scene can be perfectly
/// specified and still never reach the screen, so that is a separate thing to assert.
@MainActor
@Suite("Rendering")
struct RenderingTests {
    private static let contentSize = CGSize(width: 320, height: 180)
    /// Anything below this counts as blank. Antialiasing alone can tint a few pixels.
    private static let inkThreshold = 0.005

    /// Fraction of the rendered image carrying meaningful coverage.
    private func paintedFraction(of view: some View, size: CGSize) -> Double {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.cgImage else { return 0 }

        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixels,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: width * 4,
                  space: space,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return 0 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Measured on alpha rather than color, so the greyscale `neutral` palette is judged the same
        // way as the colored ones.
        let painted = stride(from: 3, to: pixels.count, by: 4).count { pixels[$0] > 8 }
        return Double(painted) / Double(width * height)
    }

    /// The glow alone, with nothing underneath it.
    private func glow(
        _ size: AuroraSize,
        variant: AuroraColorVariant = .glow,
        theme: AuroraTheme
    ) -> some View {
        let duration = Tuning.standard.defaults.duration(for: size)
        let configuration = AuroraConfiguration(
            size: size,
            colorVariant: variant,
            theme: theme,
            shape: .rounded(cornerRadius: 20)
        )
        return Color.clear
            .aurora(configuration: configuration)
            .auroraClockFrozen(at: duration * 0.5)
    }

    /// A glow on a stopped clock, driven through `isPaused`.
    ///
    /// `\.accessibilityReduceMotion` is read-only, so Reduce Motion cannot be simulated from a test.
    /// This exercises the same guard: both settings stop the clock, and the bug lived in how the
    /// activation ramp was read against a stopped one.
    private func pausedGlow(_ size: AuroraSize, theme: AuroraTheme) -> some View {
        AuroraDecoration(
            configuration: AuroraConfiguration(size: size, theme: theme, shape: .rounded(cornerRadius: 20)),
            contentSize: Self.contentSize,
            placement: .aboveContent,
            isActive: true,
            isPaused: true
        )
    }

    /// The regression that motivated this suite. Every preset in both appearances has to put ink on
    /// the canvas.
    @Test("Every preset paints", arguments: AuroraSize.allCases)
    func everyPresetPaints(size: AuroraSize) {
        for theme in [AuroraTheme.dark, .light] {
            let coverage = paintedFraction(of: glow(size, theme: theme), size: Self.contentSize)
            #expect(coverage > Self.inkThreshold, "\(size)/\(theme) painted \(coverage)")
        }
    }

    @Test("Every palette paints", arguments: paletteSamples)
    func everyPalettePaints(sample: PaletteSample) {
        let coverage = paintedFraction(
            of: glow(.regular, variant: sample.variant, theme: .dark),
            size: Self.contentSize
        )
        #expect(coverage > Self.inkThreshold, "\(sample.name) painted \(coverage)")
    }

    /// The specific bug this suite caught. The activation ramp is derived from elapsed time, and a
    /// stopped clock never advances it — so reading the ramp against a stopped clock pinned it at
    /// zero, leaving the glow permanently invisible. Reduce Motion stops the clock, so before the
    /// fix that setting hid the effect outright.
    @Test("A stopped clock still paints", arguments: AuroraSize.allCases)
    func stoppedClockStillPaints(size: AuroraSize) {
        let coverage = paintedFraction(
            of: pausedGlow(size, theme: .dark),
            size: Self.contentSize
        )
        #expect(coverage > Self.inkThreshold, "\(size) on a stopped clock painted \(coverage)")
    }

    /// Strength has to reach the pixels, not only the scene description.
    @Test("Lower strength paints less")
    func strengthDimsTheRender() {
        func coverage(strength: Double) -> Double {
            let configuration = AuroraConfiguration(
                size: .pulseInward, theme: .dark, shape: .rounded(cornerRadius: 20),
                strength: strength
            )
            let view = Color.clear
                .aurora(configuration: configuration)
                .auroraClockFrozen(at: 1.15)
            return paintedFraction(of: view, size: Self.contentSize)
        }
        #expect(coverage(strength: 0.15) < coverage(strength: 1))
    }

    /// The environment style has to reach the pixels, not just the type system.
    ///
    /// This is the whole premise of attaching a glow to a component that names no colours: if the style
    /// failed to propagate, every such component would silently render the default look and nothing would
    /// crash. Strength is the cheapest property to observe, since it moves coverage directly.
    @Test("A style set in the environment reaches the render")
    func environmentStyleReachesTheRender() {
        func coverage(strength: Double) -> Double {
            let view = Color.clear
                .aurora(.pulseInward, in: .rounded(cornerRadius: 20), theme: .dark)
                .auroraStyle(strength: strength)
                .auroraClockFrozen(at: 1.15)
            return paintedFraction(of: view, size: Self.contentSize)
        }
        #expect(coverage(strength: 0.15) < coverage(strength: 1))
    }

    /// An override at the call site has to beat the inherited style, or per-view exceptions are impossible.
    @Test("A call-site override beats the inherited style")
    func callSiteOverrideWins() {
        let view = Color.clear
            .aurora(.pulseInward, in: .rounded(cornerRadius: 20), theme: .dark, strength: 0)
            .auroraStyle(strength: 1)
            .auroraClockFrozen(at: 1.15)
        // Zero strength produces an empty scene, so the override winning means nothing is painted.
        #expect(paintedFraction(of: view, size: Self.contentSize) < Self.inkThreshold)
    }

    /// `.capsule` has to resolve against the measured host, which only happens at render time.
    @Test("A capsule shape renders differently from square corners")
    func capsuleShapeReachesTheRender() {
        func coverage(_ shape: AuroraShape) -> Double {
            let view = Color.clear
                .aurora(.regular, in: shape, theme: .dark)
                .auroraClockFrozen(at: 0.98)
            return paintedFraction(of: view, size: CGSize(width: 240, height: 60))
        }
        // A capsule rounds 30pt off each end; square corners keep them. The ring's coverage cannot match.
        #expect(coverage(.capsule) != coverage(.rounded(cornerRadius: 0)))
    }

    @Test("An inactive glow paints nothing")
    func inactiveGlowIsBlank() {
        let view = Color.clear
            .aurora(
                configuration: AuroraConfiguration(size: .regular, shape: .rounded(cornerRadius: 20)),
                isActive: false
            )
            .auroraClockFrozen(at: 0.98)
        #expect(paintedFraction(of: view, size: Self.contentSize) < Self.inkThreshold)
    }

    /// The outward halo has to escape the content's bounds. If the canvas were sized to the content,
    /// or an enclosing clip survived, the halo would be cropped to the card and the preset would be
    /// indistinguishable from the contained one.
    @Test("The outward halo paints beyond the content bounds")
    func outwardHaloEscapesBounds() {
        let padding = 60.0
        let outerSize = CGSize(
            width: Self.contentSize.width + padding * 2,
            height: Self.contentSize.height + padding * 2
        )

        func coverage(of size: AuroraSize) -> Double {
            let view = Color.clear
                .frame(width: Self.contentSize.width, height: Self.contentSize.height)
                .aurora(
                    configuration: AuroraConfiguration(
                        size: size, theme: .dark, shape: .rounded(cornerRadius: 20)
                    )
                )
                .padding(padding)
                .auroraClockFrozen(at: 1.15)
            return paintedFraction(of: view, size: outerSize)
        }

        // Rendered into a canvas larger than the content, so extra coverage can only come from ink
        // outside the card.
        #expect(coverage(of: .pulseOutward) > coverage(of: .pulseInward))
    }

    /// A frozen clock is only useful if it is reproducible.
    ///
    /// The tolerance is deliberately loose. What this has to catch is the clock *moving* — a different
    /// phase shifts coverage by whole percentage points. Rasterization is not bit-exact between passes:
    /// pixels sitting right on the alpha threshold flip either way, moving the count by a handful out of
    /// two hundred thousand. Demanding exactness here only produces a flaky test.
    @Test("A frozen clock renders the same frame twice")
    func frozenClockIsReproducible() {
        let first = paintedFraction(of: glow(.regular, theme: .dark), size: Self.contentSize)
        let second = paintedFraction(of: glow(.regular, theme: .dark), size: Self.contentSize)
        #expect(abs(first - second) < 1e-3)
    }

    /// The counterpart to `AuroraSceneBuilderTests.lineIsDarkAtCycleStart`, at the pixel level: the
    /// `underline` preset's edge fade sits at zero early in its cycle, so a capture frozen there is
    /// legitimately blank. Anyone snapshotting that preset needs to know.
    @Test("The underline preset is blank when frozen at the start of its cycle")
    func lineIsBlankAtCycleStart() {
        let view = Color.clear
            .aurora(configuration: AuroraConfiguration(size: .underline, shape: .rounded(cornerRadius: 20)))
            .auroraClockFrozen(at: 0)
        #expect(paintedFraction(of: view, size: Self.contentSize) < Self.inkThreshold)
    }
}
