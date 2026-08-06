import CoreGraphics
import Foundation
import Testing

@testable import AuroraCore

/// A named palette to run a test against.
///
/// `AuroraColorVariant` carries caller colors, so it has no `allCases` for `arguments:` to walk. Naming
/// the shapes is the replacement, and it is more honest anyway: the interesting cases are the authored
/// spectrum, a single hue, a combination, and the empty combination that falls back to achromatic.
///
/// File scope rather than a static on the suite, because `@Test(arguments:)` evaluates its arguments
/// outside the suite — a `@MainActor` suite cannot hand one over.
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

@Suite("Scene builder")
struct AuroraSceneBuilderTests {
    private static let cardSize = CGSize(width: 320, height: 180)

    private func builder(
        size: AuroraSize,
        variant: AuroraColorVariant = .glow,
        theme: AuroraTheme = .dark,
        strength: Double = 1,
        shape: AuroraShape = .rounded(cornerRadius: 20)
    ) -> AuroraSceneBuilder {
        let configuration = AuroraConfiguration(
            size: size,
            colorVariant: variant,
            theme: theme,
            shape: shape,
            strength: strength
        )
        return AuroraSceneBuilder(
            configuration: configuration.resolved(isDarkEnvironment: theme != .light)
        )
    }

    /// The `underline` preset's edge fade sits at zero for the first eighth of its cycle, so a naive
    /// sample at `time: 0` renders nothing. Any frozen frame has to land mid-cycle — this is the
    /// detail most easily mistaken for a broken port.
    private func timeMidCycle(for size: AuroraSize) -> Double {
        Tuning.standard.defaults.duration(for: size) * 0.5
    }

    // MARK: Coverage

    /// The whole public matrix has to produce something drawable. A preset that silently returns an
    /// empty scene is the failure mode most likely to slip through, because nothing crashes — the
    /// glow is simply absent.
    @Test(
        "Every preset and palette produces visible layers",
        arguments: AuroraSize.allCases, paletteSamples
    )
    func everyCombinationDraws(size: AuroraSize, sample: PaletteSample) {
        for theme in [AuroraTheme.dark, .light] {
            let scene = builder(size: size, variant: sample.variant, theme: theme)
                .scene(contentSize: Self.cardSize, time: timeMidCycle(for: size), activation: 1)

            #expect(scene.isEmpty == false, "\(size)/\(sample.name)/\(theme) drew nothing")
            #expect(scene.layers.allSatisfy { $0.isVisible })
        }
    }

    @Test("The underline preset draws nothing at the very start of its cycle, by design")
    func lineIsDarkAtCycleStart() {
        let scene = builder(size: .underline).scene(contentSize: Self.cardSize, time: 0, activation: 1)
        #expect(scene.isEmpty)
    }

    @Test("The underline preset draws mid-cycle")
    func lineDrawsMidCycle() {
        let scene = builder(size: .underline)
            .scene(contentSize: Self.cardSize, time: timeMidCycle(for: .underline), activation: 1)
        #expect(scene.isEmpty == false)
    }

    // MARK: Degenerate inputs

    @Test("A zero-sized host produces an empty scene rather than dividing by zero")
    func zeroSizeIsEmpty() {
        #expect(builder(size: .regular).scene(contentSize: .zero, time: 1, activation: 1).isEmpty)
    }

    @Test("A fully faded-out glow produces an empty scene, not a zero-opacity stack")
    func fadedOutIsEmpty() {
        #expect(builder(size: .regular).scene(contentSize: Self.cardSize, time: 1, activation: 0).isEmpty)
    }

    @Test("Zero strength produces an empty scene")
    func zeroStrengthIsEmpty() {
        let scene = builder(size: .regular, strength: 0)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        #expect(scene.isEmpty)
    }

    // MARK: Opacity

    /// Four presets store an opacity above 1 because the source they were tuned against clamps for
    /// you. Left unclamped, premultiplied alpha climbs past 1 and compositing breaks down.
    @Test("No layer escapes with an opacity outside 0...1", arguments: AuroraSize.allCases)
    func opacitiesAreClamped(size: AuroraSize) {
        for theme in [AuroraTheme.dark, .light] {
            let scene = builder(size: size, theme: theme)
                .scene(contentSize: Self.cardSize, time: timeMidCycle(for: size), activation: 1)
            #expect(scene.layers.allSatisfy { $0.opacity <= 1 }, "\(size)/\(theme) exceeded 1")
            #expect(scene.layers.allSatisfy { $0.opacity >= 0 })
        }
    }

    @Test("Strength scales layer opacity down")
    func strengthScalesOpacity() {
        let full = builder(size: .regular, strength: 1)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        let half = builder(size: .regular, strength: 0.5)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)

        #expect(full.layers.count == half.layers.count)
        for (bright, dim) in zip(full.layers, half.layers) {
            #expect(dim.opacity <= bright.opacity)
        }
    }

    @Test("A uniform palette dims the presets that use the shared multiplier")
    func neutralIsDimmer() {
        let varied = builder(size: .regular, variant: .glow)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        let uniform = builder(size: .regular, variant: .neutral)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)

        for (color, gray) in zip(varied.layers, uniform.layers) {
            #expect(gray.opacity < color.opacity)
        }
    }

    /// The underline preset attenuates `neutral` inside its own bloom table, so applying the shared
    /// multiplier on top would double-dim it.
    @Test("The underline preset does not apply the shared neutral multiplier")
    func lineSkipsMonoMultiplier() {
        let tuning = Tuning.standard
        let neutral = AuroraConfiguration(size: .underline, colorVariant: .neutral)
            .resolved(isDarkEnvironment: true, tuning: tuning)
        #expect(neutral.strokeOpacity == tuning.themePreset(for: .underline, theme: .dark).strokeOpacity)
    }

    // MARK: Placement and outset

    @Test("Only pulseOutward paints behind the content", arguments: AuroraSize.allCases)
    func placementMatchesPreset(size: AuroraSize) {
        let scene = builder(size: size)
            .scene(contentSize: Self.cardSize, time: timeMidCycle(for: size), activation: 1)

        if size == .pulseOutward {
            #expect(scene.layersBehindContent.isEmpty == false)
            #expect(scene.layersAboveContent.isEmpty == false)
        } else {
            #expect(scene.layersBehindContent.isEmpty)
        }
    }

    /// The outward halo is meant to escape the bounds, and a Gaussian blur reaches well past the box
    /// it was drawn in — so the outset has to exceed the layer inset alone, or the halo is clipped
    /// at the canvas edge.
    @Test("Only pulseOutward requests an outset, and it covers its blur")
    func outsetOnlyForOutwardHalo() {
        for size in AuroraSize.allCases where size != .pulseOutward {
            let scene = builder(size: size)
                .scene(contentSize: Self.cardSize, time: timeMidCycle(for: size), activation: 1)
            #expect(scene.outset == .zero, "\(size) should stay inside its bounds")
        }

        let halo = builder(size: .pulseOutward)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        let widestBlur = halo.layers.map(\.blurRadius).max() ?? 0
        #expect(halo.outset.value > AuroraSceneBuilder.outwardBloomInset)
        #expect(halo.outset.value >= AuroraSceneBuilder.outwardBloomInset + widestBlur)
    }

    @Test("The outward halo copes with hosts far from its reference size")
    func outwardGlowScaleIsBounded() {
        // A host far smaller than the reference card would otherwise get a halo so far off-scale it
        // stops looking attached to anything.
        let tiny = builder(size: .pulseOutward)
            .scene(contentSize: CGSize(width: 8, height: 8), time: 1, activation: 1)
        let huge = builder(size: .pulseOutward)
            .scene(contentSize: CGSize(width: 4000, height: 4000), time: 1, activation: 1)
        #expect(tiny.isEmpty == false)
        #expect(huge.isEmpty == false)
    }

    // MARK: Clip and geometry

    @Test("The crisp ring is clipped to the configured thickness")
    func ringUsesBorderWidth() {
        let configuration = AuroraConfiguration(size: .regular, shape: .rounded(cornerRadius: 20), borderWidth: 3)
        let scene = AuroraSceneBuilder(configuration: configuration.resolved(isDarkEnvironment: true))
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)

        let thicknesses: [Double] = scene.layers.compactMap { layer in
            guard case .ring(_, let thickness) = layer.clip else { return nil }
            return thickness
        }
        #expect(thicknesses.isEmpty == false)
        #expect(thicknesses.allSatisfy { $0 == 3 })
    }

    @Test("An explicit corner radius reaches the scene")
    func cornerRadiusIsHonoured() {
        let scene = builder(size: .regular, shape: .rounded(cornerRadius: 42))
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        #expect(scene.cornerRadius == 42)
    }

    @Test("The preset shape falls back to the preset default radius")
    func cornerRadiusFallsBack() {
        let scene = builder(size: .regular, shape: .preset)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        #expect(scene.cornerRadius == Tuning.standard.sizePreset(for: .regular).cornerRadius)
    }

    /// The reason ``AuroraShape`` exists: a capsule's radius is a function of the host, so it cannot be a
    /// number the caller supplies up front. Two hosts, one shape, two radii.
    @Test("A capsule resolves its radius from the host, not from the caller")
    func capsuleResolvesFromHost() {
        let subject = builder(size: .compact, shape: .capsule)

        let short = subject.scene(contentSize: CGSize(width: 200, height: 40), time: 1, activation: 1)
        let tall = subject.scene(contentSize: CGSize(width: 200, height: 64), time: 1, activation: 1)
        #expect(short.cornerRadius == 20)
        #expect(tall.cornerRadius == 32)

        // Half the *short* side, so a tall narrow host rounds on its width.
        let narrow = subject.scene(contentSize: CGSize(width: 30, height: 300), time: 1, activation: 1)
        #expect(narrow.cornerRadius == 15)
    }

    /// A radius past half the host inverts the corner arcs and the ring crosses itself. Clamping is what
    /// keeps a caller's mistake looking merely wrong rather than broken.
    @Test("A radius larger than the host is clamped to a capsule")
    func oversizedRadiusIsClamped() {
        let scene = builder(size: .regular, shape: .rounded(cornerRadius: 400))
            .scene(contentSize: CGSize(width: 200, height: 48), time: 1, activation: 1)
        #expect(scene.cornerRadius == 24)
    }

    @Test("A negative radius is treated as square corners")
    func negativeRadiusIsSquare() {
        let scene = builder(size: .regular, shape: .rounded(cornerRadius: -10))
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        #expect(scene.cornerRadius == 0)
    }

    // MARK: Palette scaling

    /// The compact palette's blob radii are absolute points authored for a 70×36 control, so they have to
    /// track the host or the same tuning that sweeps a chip leaves a wide button looking gapped. This is
    /// what makes `.compact` safe to attach to a control of any size.
    @Test("The compact palette scales its blobs with the host")
    func compactPaletteScalesWithHost() {
        func widestBlob(_ contentSize: CGSize) -> Double {
            let scene = builder(size: .compact, shape: .capsule)
                .scene(contentSize: contentSize, time: 1, activation: 1)
            return scene.layers.flatMap(\.gradients).compactMap { gradient -> Double? in
                guard case .ellipse(let ellipse) = gradient else { return nil }
                return ellipse.radii.width.points
            }
            .max() ?? 0
        }

        let reference = widestBlob(CGSize(width: 70, height: 36))
        let wide = widestBlob(CGSize(width: 175, height: 36))
        #expect(reference > 0)
        // 175 / 70 is 2.5, exactly the upper bound.
        #expect(abs(wide / reference - 2.5) < 1e-9)
    }

    /// `.regular` carries no reference box, so it must be untouched by the scaling — its palette is authored
    /// for a card and reads correctly across the range a card spans.
    @Test("The regular palette is not scaled by the host")
    func regularPaletteIgnoresHostSize() {
        func widestBlob(_ contentSize: CGSize) -> Double {
            let scene = builder(size: .regular)
                .scene(contentSize: contentSize, time: 1, activation: 1)
            return scene.layers.flatMap(\.gradients).compactMap { gradient -> Double? in
                guard case .ellipse(let ellipse) = gradient else { return nil }
                return ellipse.radii.width.points
            }
            .max() ?? 0
        }
        #expect(widestBlob(CGSize(width: 320, height: 180)) == widestBlob(CGSize(width: 700, height: 300)))
    }

    /// Unbounded scaling would let a host far from the reference produce blobs so large they merge into one
    /// band, or so small they detach from the edge.
    @Test("Palette scaling is clamped at both ends")
    func paletteScalingIsClamped() {
        let bounds = AuroraSceneBuilder.paletteScaleBounds
        #expect(bounds.lowerBound > 0)
        #expect(bounds.upperBound > bounds.lowerBound)

        func widestBlob(_ contentSize: CGSize) -> Double {
            let scene = builder(size: .compact, shape: .capsule)
                .scene(contentSize: contentSize, time: 1, activation: 1)
            return scene.layers.flatMap(\.gradients).compactMap { gradient -> Double? in
                guard case .ellipse(let ellipse) = gradient else { return nil }
                return ellipse.radii.width.points
            }
            .max() ?? 0
        }

        let reference = widestBlob(CGSize(width: 70, height: 36))
        let absurdlyWide = widestBlob(CGSize(width: 4000, height: 36))
        let absurdlyNarrow = widestBlob(CGSize(width: 4, height: 36))
        #expect(abs(absurdlyWide / reference - bounds.upperBound) < 1e-9)
        #expect(abs(absurdlyNarrow / reference - bounds.lowerBound) < 1e-9)
    }

    // MARK: Border

    /// The builder appends the traced outline first, so it sits under the colored ring.
    private func borderLayer(_ scene: AuroraScene) -> AuroraLayer? {
        scene.layers.first
    }

    /// The outline's arc: a fixed table of stops plus the angle it is rotated to.
    ///
    /// Those two carry different jobs, and the split is the mechanism. The stops describe the *shape* of
    /// the lit arc and never change; the angle is what advances each frame. A test that only compared
    /// stops would see a static border and be satisfied by one.
    private func borderSweep(_ scene: AuroraScene) -> (stops: [AuroraGradientStop], angle: Double)? {
        guard case .angularSweep(let stops, let angle) = borderLayer(scene)?.gradients.first else {
            return nil
        }
        return (stops, angle)
    }

    private func borderStops(_ scene: AuroraScene) -> [AuroraGradientStop] {
        borderSweep(scene)?.stops ?? []
    }

    private func borderedScene(
        size: AuroraSize = .regular,
        theme: AuroraTheme = .dark,
        time: Double
    ) -> AuroraScene {
        let configuration = AuroraConfiguration(
            size: size,
            theme: theme,
            shape: .rounded(cornerRadius: 20),
            showsBorder: true
        )
        return AuroraSceneBuilder(configuration: configuration.resolved(isDarkEnvironment: theme != .light))
            .scene(contentSize: Self.cardSize, time: time, activation: 1)
    }

    @Test("No border is drawn unless asked for", arguments: AuroraSize.allCases)
    func borderIsOptOut(size: AuroraSize) {
        let without = builder(size: size)
            .scene(contentSize: Self.cardSize, time: timeMidCycle(for: size), activation: 1)
        let with = borderedScene(size: size, time: timeMidCycle(for: size))
        #expect(with.layers.count == without.layers.count + 1, "\(size) did not gain a border layer")
    }

    /// The point of the feature: the outline is lit by the sweep rather than sitting dead under it.
    ///
    /// What moves is the angle, not the stops — so this asserts the angle advances *and* that it stays
    /// locked to the colored ring's own angle. Drifting apart is the failure that would look worst: two
    /// bright arcs chasing each other round the same border.
    @Test("The border travels with the sweep, in step with the ring")
    func borderTravelsWithTheSweep() {
        let duration = Tuning.standard.defaults.duration(for: .regular)

        func angles(at time: Double) -> (border: Double, ring: Double)? {
            let scene = borderedScene(time: time)
            guard let border = borderSweep(scene)?.angle else { return nil }
            // The ring's highlight is the last angular sweep in the stack; the bloom follows it.
            let ringAngles = scene.layers.dropFirst().flatMap(\.gradients).compactMap { gradient -> Double? in
                guard case .angularSweep(_, let angle) = gradient else { return nil }
                return angle
            }
            guard let ring = ringAngles.first else { return nil }
            return (border, ring)
        }

        guard let early = angles(at: duration * 0.1), let late = angles(at: duration * 0.6) else {
            Issue.record("no angular sweep found")
            return
        }
        #expect(early.border != late.border, "the border did not advance")
        #expect(early.border == early.ring, "the border is out of step with the ring")
        #expect(late.border == late.ring)
    }

    /// The border belongs to the light, not to the host: away from the head it is gone, so no resting
    /// hairline draws a box around the card. Both ends of the range matter — fully clear behind, fully
    /// opaque at the head — because a uniform mid-alpha would be the static outline this replaced.
    @Test("The border appears only along the lit arc")
    func borderAppearsOnlyWhereTheLightIs() {
        let stops = borderStops(borderedScene(time: 1))
        #expect(stops.isEmpty == false)

        let alphas = stops.map(\.color.alpha)
        #expect(alphas.contains { $0 <= AuroraSceneBuilder.borderRestingAlpha + 1e-9 }, "no clear stop")
        #expect(alphas.contains { $0 >= 0.999 }, "no fully lit stop")
        // Soft at both ends rather than a hard edge: the ramp is what keeps it from blinking.
        #expect(alphas.filter { $0 > 0.01 && $0 < 0.99 }.count >= 4, "the arc has no ramp")
    }

    /// Achromatic in both appearances — the outline takes no hue from the palette — and inverted between
    /// them. Light is a mid grey rather than black, which is where it differs from the mask tint.
    @Test("The border is tinted by the appearance, and grey on light")
    func borderFollowsTheAppearance() {
        for theme in [AuroraTheme.dark, AuroraTheme.light] {
            let stops = borderStops(borderedScene(theme: theme, time: 1))
            #expect(stops.isEmpty == false)
            #expect(
                stops.allSatisfy { $0.color.red == $0.color.green && $0.color.green == $0.color.blue },
                "\(theme) border took a hue"
            )
        }

        let dark = borderStops(borderedScene(theme: .dark, time: 1)).map(\.color.red)
        let light = borderStops(borderedScene(theme: .light, time: 1)).map(\.color.red)
        #expect(dark.allSatisfy { $0 == 1 }, "dark should be white")
        // Grey, not black: pure black reads as a drawn outline rather than an edge catching the light.
        #expect(light.allSatisfy { $0 > 0.2 && $0 < 0.8 }, "light should be a mid grey")
    }

    /// The breathing presets have no angular head to follow, so their outline is steady rather than absent.
    /// A flag that silently did nothing would be the worse option.
    @Test("Presets without a sweep draw a steady border", arguments: [
        AuroraSize.pulseInward, .pulseOutward, .underline,
    ])
    func borderIsSteadyWithoutASweep(size: AuroraSize) {
        let duration = Tuning.standard.defaults.duration(for: size)
        let early = borderLayer(borderedScene(size: size, time: duration * 0.35))
        let late = borderLayer(borderedScene(size: size, time: duration * 0.6))
        #expect(early != nil)
        #expect(early == late, "\(size) border moved when it has no sweep to follow")

        // And it has to be *visible*. A zero resting alpha is right for a swept arc; applied here it would
        // make the flag draw nothing at all.
        guard case .fill(let color) = early?.gradients.first else {
            Issue.record("\(size) border is not a steady fill")
            return
        }
        #expect(color.alpha > 0.01, "\(size) border is invisible")
    }

    // MARK: Style

    /// ``AuroraStyle`` is the half of the configuration a whole app shares. Combining it with a preset and
    /// a shape has to produce exactly what writing the configuration by hand would.
    @Test("A style plus a preset and shape equals the configuration written out")
    func styleBuildsTheSameConfiguration() {
        let style = AuroraStyle(
            colorVariant: .tinted(Self.iris),
            theme: .light,
            strength: 0.4,
            duration: 3,
            staticColors: true,
            hueRange: 12
        )
        let built = style.configuration(.compact, in: .capsule)
        let byHand = AuroraConfiguration(
            size: .compact,
            colorVariant: .tinted(Self.iris),
            theme: .light,
            shape: .capsule,
            staticColors: true,
            duration: 3,
            hueRange: 12,
            strength: 0.4
        )
        #expect(built == byHand)
    }

    /// The default that makes a glow safe to attach anywhere: it follows the surrounding scheme rather
    /// than pinning an appearance the component cannot know.
    @Test("The default style and configuration both follow the color scheme")
    func defaultsFollowTheColorScheme() {
        #expect(AuroraStyle.standard.theme == .auto)
        #expect(AuroraConfiguration().theme == .auto)

        let configuration = AuroraStyle.standard.configuration(.regular, in: .capsule)
        #expect(configuration.resolved(isDarkEnvironment: true).theme == .dark)
        #expect(configuration.resolved(isDarkEnvironment: false).theme == .light)
    }

    // MARK: neutral tint

    /// Every blob colour the scene ends up drawing, for inspecting what a configuration produces.
    private func blobColors(_ scene: AuroraScene) -> [AuroraColor] {
        scene.layers.flatMap(\.gradients).compactMap { gradient in
            guard case .ellipse(let ellipse) = gradient else { return nil }
            return ellipse.stops.first?.color
        }
    }

    private func scene(
        size: AuroraSize,
        variant: AuroraColorVariant,
        theme: AuroraTheme
    ) -> AuroraScene {
        let configuration = AuroraConfiguration(
            size: size,
            colorVariant: variant,
            theme: theme,
            shape: .rounded(cornerRadius: 20)
        )
        let resolved = configuration.resolved(isDarkEnvironment: theme != .light)
        return AuroraSceneBuilder(configuration: resolved)
            .scene(contentSize: Self.cardSize, time: timeMidCycle(for: size), activation: 1)
    }

    private static let iris = AuroraColor(r: 60, g: 120, b: 255)
    private static let amber = AuroraColor(r: 255, g: 170, b: 60)

    private func brightness(_ color: AuroraColor) -> Double {
        (color.red + color.green + color.blue) / 3
    }

    // MARK: Recoloring

    /// A tint has to reach the drawn colours, not just sit in the configuration. Checked for every
    /// preset, because each family assembles its blobs through a different path.
    @Test("A tint recolours the drawn blobs", arguments: AuroraSize.allCases)
    func tintReachesTheScene(size: AuroraSize) {
        let grey = blobColors(scene(size: size, variant: .neutral, theme: .dark))
        let blue = blobColors(scene(size: size, variant: .tinted(Self.iris), theme: .dark))
        #expect(grey.isEmpty == false)
        #expect(grey != blue, "\(size) ignored the tint")
        // A tint means blue outweighs red; the achromatic base has them equal by definition.
        #expect(grey.allSatisfy { abs($0.red - $0.blue) < 1e-9 })
        #expect(blue.contains { $0.blue > $0.red + 0.01 })
    }

    /// Multiplying through each blob's own brightness is what keeps the palette's structure. Replacing
    /// the colours outright would flatten the nine blobs to one shade, and the perimeter would stop
    /// reading as separate pools of light.
    @Test("A tint preserves the palette's relative brightness")
    func tintPreservesStructure() {
        let grey = blobColors(scene(size: .regular, variant: .neutral, theme: .dark))
        let tinted = blobColors(scene(size: .regular, variant: .tinted(Self.iris), theme: .dark))
        #expect(grey.count == tinted.count)

        // Distinct brightnesses before, still as many distinct after — not collapsed to one shade.
        let distinctBefore = Set(grey.map { (brightness($0) * 1000).rounded() })
        let distinctAfter = Set(tinted.map { (brightness($0) * 1000).rounded() })
        #expect(distinctBefore.count > 1)
        #expect(distinctAfter.count == distinctBefore.count)
    }

    /// The authored spectrum carries its own hues and must come through untouched.
    @Test("The glow palette is never recoloured")
    func glowPaletteIsNotRecoloured() {
        let resolved = AuroraConfiguration(size: .regular, colorVariant: .glow, shape: .rounded(cornerRadius: 20))
            .resolved(isDarkEnvironment: true)
        let subject = AuroraSceneBuilder(configuration: resolved)
        let sample = AuroraColor(r: 12, g: 34, b: 56)
        #expect(subject.recolored(sample, at: 0) == sample)
        #expect(subject.recolored(sample, at: 7) == sample)
    }

    /// The point of `multiColor`: hues land on different blobs rather than collapsing onto one.
    @Test("multiColor deals its hues across the blobs")
    func multiColorDealsHuesAcrossBlobs() {
        let red = AuroraColor(r: 255, g: 40, b: 40)
        let blue = AuroraColor(r: 40, g: 40, b: 255)
        let colors = blobColors(scene(size: .regular, variant: .multiColor([red, blue]), theme: .dark))

        #expect(colors.contains { $0.red > $0.blue + 0.01 }, "no red-dominant blob")
        #expect(colors.contains { $0.blue > $0.red + 0.01 }, "no blue-dominant blob")
    }

    /// One colour in a combination is the same thing as a tint and has to render identically — the two
    /// cases share one code path, and this is what stops them drifting apart.
    @Test("A one-colour combination matches the equivalent tint", arguments: AuroraSize.allCases)
    func oneColourCombinationMatchesTinted(size: AuroraSize) {
        let viaTint = scene(size: size, variant: .tinted(Self.iris), theme: .dark)
        let viaList = scene(size: size, variant: .multiColor([Self.iris]), theme: .dark)
        #expect(viaTint == viaList)
    }

    /// An empty list is a caller mistake, most likely a computed array that came back short. It leaves
    /// the structure achromatic rather than trapping, so a view cannot be crashed by one.
    @Test("An empty combination falls back to achromatic", arguments: AuroraSize.allCases)
    func emptyCombinationIsAchromatic(size: AuroraSize) {
        let empty = blobColors(scene(size: size, variant: .multiColor([]), theme: .dark))
        #expect(empty.isEmpty == false)
        #expect(empty.allSatisfy { abs($0.red - $0.blue) < 1e-9 && abs($0.red - $0.green) < 1e-9 })
    }

    // MARK: Uniformity

    /// A single hue is held still and dimmed; several hues get neither treatment. One predicate drives
    /// both, because uniform brightness is what reads as a hard band.
    @Test("A uniform palette holds its hue and is dimmed, a varied one is not")
    func uniformityDrivesHueAndOpacity() {
        let tuning = Tuning.standard
        let raw = tuning.themePreset(for: .regular, theme: .dark).strokeOpacity

        func resolved(_ variant: AuroraColorVariant) -> AuroraResolvedConfiguration {
            AuroraConfiguration(size: .regular, colorVariant: variant)
                .resolved(isDarkEnvironment: true, tuning: tuning)
        }

        let single = resolved(.tinted(Self.iris))
        #expect(single.staticColors)
        #expect(abs(single.strokeOpacity - raw * tuning.defaults.uniformOpacityMultiplier) < 1e-9)

        let several = resolved(.multiColor([Self.iris, Self.amber]))
        #expect(several.staticColors == false)
        #expect(abs(several.strokeOpacity - raw) < 1e-9)

        // The authored spectrum is varied by definition.
        #expect(resolved(.glow).staticColors == false)
        #expect(abs(resolved(.glow).strokeOpacity - raw) < 1e-9)
    }

    /// The original complaint: `neutral` was authored as a light glow, so on a light surface it has to deepen
    /// instead. Both halves of the fix are checked — darker greys, *and* the opacity halving no longer
    /// stacking on light's already-lower presets.
    @Test("neutral draws darker and no fainter on a light appearance")
    func neutralIsDarkerButNotFainterOnLight() {
        let dark = blobColors(scene(size: .regular, variant: .neutral, theme: .dark))
        let light = blobColors(scene(size: .regular, variant: .neutral, theme: .light))

        func meanBrightness(_ colors: [AuroraColor]) -> Double {
            colors.reduce(0) { $0 + ($1.red + $1.green + $1.blue) / 3 } / Double(colors.count)
        }
        #expect(meanBrightness(light) < meanBrightness(dark))

        let tuning = Tuning.standard
        let lightPreset = AuroraConfiguration(size: .regular, colorVariant: .neutral, theme: .light)
            .resolved(isDarkEnvironment: false, tuning: tuning)
        // Unhalved on light: the raw preset value comes through intact.
        #expect(lightPreset.strokeOpacity == tuning.themePreset(for: .regular, theme: .light).strokeOpacity)

        let darkPreset = AuroraConfiguration(size: .regular, colorVariant: .neutral, theme: .dark)
            .resolved(isDarkEnvironment: true, tuning: tuning)
        // Still halved on dark, where a bright uniform grey would glare.
        let darkRaw = tuning.themePreset(for: .regular, theme: .dark).strokeOpacity
        let expected = darkRaw * tuning.defaults.uniformOpacityMultiplier
        #expect(abs(darkPreset.strokeOpacity - expected) < 1e-9)
    }

    // MARK: Determinism

    /// The builder being a pure function of its inputs is what lets the renderers hold no animation
    /// state, and lets Reduce Motion be handled by pinning the clock rather than by a second code
    /// path.
    @Test("The same inputs always produce the same scene", arguments: AuroraSize.allCases)
    func buildIsDeterministic(size: AuroraSize) {
        let subject = builder(size: size)
        let time = timeMidCycle(for: size)
        let first = subject.scene(contentSize: Self.cardSize, time: time, activation: 1)
        let second = subject.scene(contentSize: Self.cardSize, time: time, activation: 1)
        #expect(first == second)
    }

    @Test("Advancing time changes the scene", arguments: AuroraSize.allCases)
    func timeAdvancesTheScene(size: AuroraSize) {
        let subject = builder(size: size)
        let duration = Tuning.standard.defaults.duration(for: size)
        let first = subject.scene(contentSize: Self.cardSize, time: duration * 0.4, activation: 1)
        let second = subject.scene(contentSize: Self.cardSize, time: duration * 0.5, activation: 1)
        #expect(first != second)
    }

    // MARK: Appearance

    @Test("auto follows the environment", arguments: AuroraSize.allCases)
    func autoThemeFollowsEnvironment(size: AuroraSize) {
        let configuration = AuroraConfiguration(size: size, theme: .auto)
        #expect(configuration.resolved(isDarkEnvironment: true).theme == .dark)
        #expect(configuration.resolved(isDarkEnvironment: false).theme == .light)
    }

    @Test("An explicit theme ignores the environment")
    func explicitThemeIgnoresEnvironment() {
        let configuration = AuroraConfiguration(size: .regular, theme: .light)
        #expect(configuration.resolved(isDarkEnvironment: true).theme == .light)
    }

    @Test("Dark and light appearances build different scenes")
    func themesDiffer() {
        let dark = builder(size: .regular, theme: .dark)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        let light = builder(size: .regular, theme: .light)
            .scene(contentSize: Self.cardSize, time: 1, activation: 1)
        #expect(dark != light)
    }

    // MARK: Configuration resolution

    @Test("neutral freezes the hue animation without the caller asking")
    func uniformPaletteHoldsHue() {
        let resolved = AuroraConfiguration(size: .regular, colorVariant: .neutral)
            .resolved(isDarkEnvironment: true)
        #expect(resolved.staticColors)
    }

    @Test("The underline preset caps its hue range tighter than the default")
    func lineCapsHueRange() {
        let tuning = Tuning.standard
        let line = AuroraConfiguration(size: .underline, hueRange: 90)
            .resolved(isDarkEnvironment: true, tuning: tuning)
        #expect(line.hueRange == tuning.defaults.lineHueRangeCap)

        let card = AuroraConfiguration(size: .regular, hueRange: 90)
            .resolved(isDarkEnvironment: true, tuning: tuning)
        #expect(card.hueRange == 90)
    }

    @Test("Strength is clamped into a usable range")
    func strengthIsClamped() {
        let tooHigh = AuroraConfiguration(size: .regular, strength: 4)
            .resolved(isDarkEnvironment: true)
        let tooLow = AuroraConfiguration(size: .regular, strength: -2)
            .resolved(isDarkEnvironment: true)
        #expect(tooHigh.strength == 1)
        #expect(tooLow.strength == 0)
    }

    /// `nil` brightness has to resolve per preset. A plain default in the initializer would flatten
    /// five separately tuned presets into one.
    @Test("An unset brightness resolves per preset, not to one global default")
    func brightnessResolvesPerPreset() {
        let card = AuroraConfiguration(size: .regular).resolved(isDarkEnvironment: true)
        let halo = AuroraConfiguration(size: .pulseOutward).resolved(isDarkEnvironment: true)
        #expect(card.brightness != halo.brightness)
    }

    @Test("An explicit brightness overrides the preset")
    func brightnessOverride() {
        let resolved = AuroraConfiguration(size: .pulseOutward, brightness: 1.05)
            .resolved(isDarkEnvironment: true)
        #expect(resolved.brightness == 1.05)
    }
}
