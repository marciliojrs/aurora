import Testing

@testable import AuroraCore

/// Completeness checks on the tuning tables.
///
/// The tables used to be decoded from a bundled payload and validated at load. Now they are Swift
/// literals, so a *type* mismatch is a build error — but a table that is merely missing an entry still
/// compiles, and would surface as an absent glow for one preset. These tests close that gap.
@Suite("Tuning")
struct TuningTests {
    @Test(
        "Every size preset has geometry and per-appearance opacities",
        arguments: AuroraSize.allCases
    )
    func presetsExist(size: AuroraSize) {
        let tuning = Tuning.standard
        #expect(tuning.sizePreset(for: size).borderWidth > 0)
        #expect(tuning.sizePreset(for: size).cornerRadius > 0)
        for theme in AuroraResolvedTheme.allCases {
            let preset = tuning.themePreset(for: size, theme: theme)
            #expect(preset.strokeOpacity >= 0)
            #expect(preset.saturation > 0)
        }
    }

    /// The compact preset is the only one carrying a reference box, which is what
    /// `AuroraSceneBuilder.paletteScale(for:)` scales its blobs against. The others author their radii for
    /// hosts whose size range they already tolerate, so a reference would only add a scale of 1.
    @Test("Only the compact preset carries a reference size")
    func compactPresetHasReferenceSize() {
        let tuning = Tuning.standard
        #expect(tuning.sizePreset(for: .compact).referenceSize != nil)
        for size in AuroraSize.allCases where size != .compact {
            #expect(tuning.sizePreset(for: size).referenceSize == nil, "\(size) gained a reference size")
        }
    }

    /// A variant that resolves to each base, so the accessors can be exercised one base at a time.
    ///
    /// Driving this from `PaletteBase.allCases` rather than from a hand-written list of variants is what
    /// makes the coverage exhaustive: add a base and this test fails until its tables exist. Enumerating
    /// variants could never do that, since ``AuroraColorVariant/tinted(_:)`` carries a color and so has
    /// no finite set of values.
    private static func variant(for base: PaletteBase) -> AuroraColorVariant {
        switch base {
        case .spectrum: .glow
        case .neutral: .neutral
        }
    }

    @Test("Palettes are populated for every base", arguments: PaletteBase.allCases)
    func palettesExist(base: PaletteBase) {
        let tuning = Tuning.standard
        let variant = Self.variant(for: base)
        for theme in AuroraResolvedTheme.allCases {
            #expect(tuning.perimeterPalette(variant, theme: theme).isEmpty == false)
            #expect(tuning.compactPalette(variant, theme: theme).perimeter.isEmpty == false)
            #expect(tuning.compactPalette(variant, theme: theme).inner.isEmpty == false)
            #expect(tuning.lineInnerPalette(variant, theme: theme).isEmpty == false)
            #expect(tuning.linePalette(variant, theme: theme).isEmpty == false)
            #expect(tuning.lineBloomBlobs(variant, theme: theme).isEmpty == false)
        }
    }

    @Test("Per-appearance tables cover both appearances")
    func appearanceTablesAreComplete() {
        let tuning = Tuning.standard
        for theme in AuroraResolvedTheme.allCases {
            #expect(tuning.rotate.highlightStops[theme]?.isEmpty == false)
            #expect(tuning.rotate.bloomStops[theme]?.isEmpty == false)
            #expect(tuning.line.highlight[theme] != nil)
            #expect(tuning.pulse.contained[theme] != nil)
            #expect(tuning.pulse.outward[theme] != nil)
            #expect(tuning.pulse.cornerAccent.alpha[theme] != nil)
        }
    }

    /// Every breathing table indexes into the perimeter palette by position, so the two have to agree on
    /// length. A short table would drop blobs; an over-long index would trap.
    @Test("The breathing tables index inside the perimeter palette")
    func pulseTablesIndexInsidePalette() {
        let tuning = Tuning.standard
        let count = tuning.perimeterPalette(.glow, theme: .dark).count
        #expect(tuning.pulse.ringMap.count == count)
        #expect(tuning.pulse.innerGlowSizes.count == count)

        let tables = tuning.pulse.innerBloom + tuning.pulse.outerCore + tuning.pulse.outerBloom
        #expect(tables.allSatisfy { $0.paletteIndex >= 0 && $0.paletteIndex < count })
    }

    /// Both bases must agree on length, since the breathing tables index into whichever one is in play.
    @Test("Every palette has the same number of perimeter blobs")
    func palettesAgreeOnLength() {
        let tuning = Tuning.standard
        let lengths = Set(
            PaletteBase.allCases.map {
                tuning.perimeterPalette(Self.variant(for: $0), theme: .dark).count
            }
        )
        #expect(lengths.count == 1)
    }

    /// Four presets legitimately store an opacity above 1. Compositing requires `0...1`, and leaving them
    /// unclamped drives premultiplied alpha past 1 — the `pulseOutward` light hairline blows out and
    /// stops tracing the corners. This documents that the raw values really do exceed 1, so the clamp in
    /// the scene builder is not mistaken for dead code and removed.
    @Test("Some presets store opacities above 1, which the builder must clamp")
    func someOpacitiesExceedOne() {
        let tuning = Tuning.standard
        var presets: [ThemePreset] = []
        for size in AuroraSize.allCases {
            for theme in AuroraResolvedTheme.allCases {
                presets.append(tuning.themePreset(for: size, theme: theme))
            }
        }
        let overOne = presets.filter { preset in
            preset.strokeOpacity > 1 || preset.innerOpacity > 1 || preset.bloomOpacity > 1
        }
        #expect(overOne.isEmpty == false)
    }

    /// The breathing presets draw no inner shadow, and a fully clear color is how that is expressed.
    @Test("The breathing presets carry a clear inner shadow")
    func breathingPresetsHaveClearInnerShadow() {
        let tuning = Tuning.standard
        #expect(tuning.themePreset(for: .pulseInward, theme: .dark).innerShadow.alpha == 0)
        #expect(tuning.themePreset(for: .pulseOutward, theme: .dark).innerShadow.alpha == 0)
    }

    // MARK: neutral on a light appearance

    /// `neutral` has to *deepen* on a light surface, the mirror of how it brightens on a dark one.
    ///
    /// The greyscale palette is authored once as a light glow. Left unadapted it is nearly invisible on
    /// a light card — which is the bug this covers. Every table that ships a single set of greys must
    /// come back darker for `.light`.
    @Test("neutral greys are darker on a light appearance")
    func neutralIsDarkerOnLight() {
        let tuning = Tuning.standard

        func meanLuminance(_ colors: [AuroraColor]) -> Double {
            guard colors.isEmpty == false else { return 0 }
            return colors.reduce(0) { $0 + ($1.red + $1.green + $1.blue) / 3 } / Double(colors.count)
        }

        let perimeterDark = meanLuminance(tuning.perimeterPalette(.neutral, theme: .dark).map(\.color))
        let perimeterLight = meanLuminance(tuning.perimeterPalette(.neutral, theme: .light).map(\.color))
        #expect(perimeterLight < perimeterDark)

        let compactDark = meanLuminance(tuning.compactPalette(.neutral, theme: .dark).perimeter.map(\.color))
        let compactLight = meanLuminance(tuning.compactPalette(.neutral, theme: .light).perimeter.map(\.color))
        #expect(compactLight < compactDark)

        let innerDark = meanLuminance(tuning.compactPalette(.neutral, theme: .dark).inner.map(\.color))
        let innerLight = meanLuminance(tuning.compactPalette(.neutral, theme: .light).inner.map(\.color))
        #expect(innerLight < innerDark)

        let lineInnerDark = meanLuminance(tuning.lineInnerPalette(.neutral, theme: .dark).map(\.color))
        let lineInnerLight = meanLuminance(tuning.lineInnerPalette(.neutral, theme: .light).map(\.color))
        #expect(lineInnerLight < lineInnerDark)

        // The ratio is the one the per-appearance tables already encode, not an arbitrary dimming.
        #expect(abs(perimeterLight / perimeterDark - Tuning.neutralLightBrightnessScale) < 1e-9)
    }

    /// The tables that already ship per-appearance greys must *not* be adapted again, or `neutral` on light
    /// would be darkened twice and collapse toward black.
    @Test("Already per-appearance neutral tables are left alone")
    func perAppearanceMonoTablesAreNotDoubleAdapted() {
        let tuning = Tuning.standard
        let dark = tuning.linePalette(.neutral, theme: .dark).map(\.color.red)
        let light = tuning.linePalette(.neutral, theme: .light).map(\.color.red)

        // These are authored dark-on-light already; the ratio sits near a half without any code running.
        let ratios = zip(dark, light).filter { $0.0 > 0 }.map { $0.1 / $0.0 }
        let mean = ratios.reduce(0, +) / Double(ratios.count)
        #expect(mean > 0.35)
        #expect(mean < 0.65)
    }

    /// The authored spectrum carries its own hues and reads against either surface, so it must be left
    /// untouched — dimming it would desaturate the whole palette on light.
    @Test("The spectrum is not adapted")
    func spectrumIsUnchangedAcrossAppearances() {
        let tuning = Tuning.standard
        let dark = tuning.perimeterPalette(.glow, theme: .dark).map(\.color)
        let light = tuning.perimeterPalette(.glow, theme: .light).map(\.color)
        #expect(dark == light)
    }

    /// Caller-supplied palettes *are* adapted, because they sit on the achromatic base rather than on
    /// their own authored table.
    ///
    /// This is a deliberate change from the four fixed palettes, where the blue-violet and amber sets
    /// were identical in both appearances and so stayed bright against a light card. Adapting the base
    /// once, before the hue is multiplied in, gives every combination the light tuning for free and only
    /// moves brightness — the hue arrives unchanged.
    @Test("Caller palettes darken on a light appearance", arguments: [
        AuroraColorVariant.cool, .warm, .tinted(AuroraColor(r: 60, g: 120, b: 255)),
    ])
    func callerPalettesAreAdapted(variant: AuroraColorVariant) {
        let tuning = Tuning.standard

        func meanLuminance(_ colors: [AuroraColor]) -> Double {
            colors.reduce(0) { $0 + ($1.red + $1.green + $1.blue) / 3 } / Double(colors.count)
        }
        let dark = tuning.perimeterPalette(variant, theme: .dark).map(\.color)
        let light = tuning.perimeterPalette(variant, theme: .light).map(\.color)
        #expect(meanLuminance(light) < meanLuminance(dark))
    }

    /// Keyframe positions are fractions through the cycle and must be sorted, or interpolation walks off
    /// the end of a track.
    @Test("Keyframe tracks are sorted inside 0...1")
    func keyframeTracksAreWellFormed() {
        let line = Tuning.standard.line
        let tracks = [
            line.travelPosition, line.travelWidth, line.edgeFade,
            line.breathe, line.spike, line.alternateSpike,
        ]
        for track in tracks {
            #expect(track.isEmpty == false)
            #expect(track.allSatisfy { $0.position >= 0 && $0.position <= 1 })
            #expect(zip(track, track.dropFirst()).allSatisfy { $0.position <= $1.position })
        }
    }

    /// Gradient stop locations are fractions too, for the same reason.
    @Test("Gradient stop tables are sorted inside 0...1")
    func stopTablesAreWellFormed() {
        let rotate = Tuning.standard.rotate
        var tables = [rotate.sweepMaskStops, rotate.compactMaskStops]
        tables.append(contentsOf: rotate.highlightStops.values)
        tables.append(contentsOf: rotate.bloomStops.values)

        for table in tables {
            #expect(table.isEmpty == false)
            #expect(table.allSatisfy { $0.location >= 0 && $0.location <= 1 })
            #expect(zip(table, table.dropFirst()).allSatisfy { $0.location <= $1.location })
        }
    }
}
