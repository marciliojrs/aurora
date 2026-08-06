// Tuned constants for the glow. Generated data, edited only when the design changes.
//
// These live as Swift literals rather than as a bundled payload so they are type-checked at build
// time, need no resource bundle, and cannot fail to load at runtime.


import CoreGraphics

extension Tuning {

    static let standardPulse = PulseTuning(
        ringMap: [
            PulseRingEntry(region: .one, quadrant: .topLeading),
            PulseRingEntry(region: .two, quadrant: .topLeading),
            PulseRingEntry(region: .three, quadrant: .bottomLeading),
            PulseRingEntry(region: .one, quadrant: .bottomLeading),
            PulseRingEntry(region: .two, quadrant: .bottomTrailing),
            PulseRingEntry(region: .three, quadrant: .bottomTrailing),
            PulseRingEntry(region: .one, quadrant: .topTrailing),
            PulseRingEntry(region: .two, quadrant: .topTrailing),
            PulseRingEntry(region: .three, quadrant: .topTrailing),
        ],
        innerGlowSizes: [
            CGSize(width: 65, height: 35),
            CGSize(width: 55, height: 30),
            CGSize(width: 35, height: 65),
            CGSize(width: 15, height: 30),
            CGSize(width: 173, height: 28),
            CGSize(width: 80, height: 22),
            CGSize(width: 69, height: 28),
            CGSize(width: 22, height: 38),
            CGSize(width: 47, height: 44),
        ],
        innerBloom: [
            PulseBlob(paletteIndex: 0, region: .one, quadrant: .topLeading, width: 84, height: 48, position: nil),
            PulseBlob(paletteIndex: 1, region: .two, quadrant: .topLeading, width: 72, height: 42, position: nil),
            PulseBlob(paletteIndex: 2, region: .three, quadrant: .bottomLeading, width: 48, height: 84, position: nil),
            PulseBlob(paletteIndex: 4, region: .two, quadrant: .bottomTrailing, width: 216, height: 38, position: nil),
            PulseBlob(paletteIndex: 5, region: .three, quadrant: .bottomTrailing, width: 102, height: 31, position: nil),
            PulseBlob(paletteIndex: 6, region: .one, quadrant: .topTrailing, width: 89, height: 38, position: nil),
            PulseBlob(paletteIndex: 8, region: .three, quadrant: .topTrailing, width: 62, height: 58, position: nil),
        ],
        outerCore: [
            PulseBlob(paletteIndex: 0, region: .one, quadrant: .topLeading, width: 80, height: 19, position: AuroraPoint(x: .percent(27), y: .percent(0))),
            PulseBlob(paletteIndex: 6, region: .two, quadrant: .topTrailing, width: 74, height: 11, position: AuroraPoint(x: .percent(73), y: .percent(-1))),
            PulseBlob(paletteIndex: 7, region: .three, quadrant: .topTrailing, width: 15, height: 44, position: AuroraPoint(x: .percent(100), y: .percent(33))),
            PulseBlob(paletteIndex: 8, region: .one, quadrant: .bottomTrailing, width: 19, height: 38, position: AuroraPoint(x: .percent(101), y: .percent(72))),
            PulseBlob(paletteIndex: 4, region: .two, quadrant: .bottomTrailing, width: 84, height: 13, position: AuroraPoint(x: .percent(67), y: .percent(100))),
            PulseBlob(paletteIndex: 1, region: .three, quadrant: .bottomLeading, width: 60, height: 21, position: AuroraPoint(x: .percent(24), y: .percent(101))),
            PulseBlob(paletteIndex: 2, region: .one, quadrant: .bottomLeading, width: 17, height: 40, position: AuroraPoint(x: .percent(0), y: .percent(60))),
            PulseBlob(paletteIndex: 3, region: .two, quadrant: .topLeading, width: 13, height: 32, position: AuroraPoint(x: .percent(-1), y: .percent(28))),
        ],
        outerBloom: [
            PulseBlob(paletteIndex: 0, region: .one, quadrant: .topLeading, width: 110, height: 30, position: AuroraPoint(x: .percent(27), y: .percent(3))),
            PulseBlob(paletteIndex: 6, region: .two, quadrant: .topTrailing, width: 100, height: 20, position: AuroraPoint(x: .percent(73), y: .percent(1))),
            PulseBlob(paletteIndex: 7, region: .three, quadrant: .topTrailing, width: 26, height: 62, position: AuroraPoint(x: .percent(100), y: .percent(33))),
            PulseBlob(paletteIndex: 8, region: .one, quadrant: .bottomTrailing, width: 30, height: 56, position: AuroraPoint(x: .percent(101), y: .percent(72))),
            PulseBlob(paletteIndex: 4, region: .two, quadrant: .bottomTrailing, width: 120, height: 22, position: AuroraPoint(x: .percent(67), y: .percent(99))),
            PulseBlob(paletteIndex: 1, region: .three, quadrant: .bottomLeading, width: 88, height: 32, position: AuroraPoint(x: .percent(24), y: .percent(99))),
            PulseBlob(paletteIndex: 2, region: .one, quadrant: .bottomLeading, width: 28, height: 58, position: AuroraPoint(x: .percent(0), y: .percent(60))),
        ],
        cornerAccent: PulseTuning.CornerAccent(
            size: 60,
            alpha: [.dark: 0.18, .light: 0.08],
            fadeLocation: 0.7
        ),
        contained: [
            .dark: PulseThemeTuning(
                parameters: PulseParameters(
                    sizeAmplitude: 0.28,
                    driftRange: 33,
                    opacityAmplitude: 0.48,
                    heightAmplitude: 0.34,
                    driftPeriod: 1.9,
                    sizePeriod: 2.6,
                    heightPeriod: 2.4,
                    huePeriod: 16
                ),
                oscillators: [
                    PulseOscillator(target: .width(.one), from: 0.72, to: 1.308, period: 2.34, phaseOffset: 0),
                    PulseOscillator(target: .height(.one), from: 1.252, to: 0.762, period: 3.276, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.one), from: -33, to: 29.7, period: 3.04, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.one), from: 18.15, to: -23.1, period: 3.04, phaseOffset: 0),
                    PulseOscillator(target: .width(.two), from: 1.28, to: 0.762, period: 2.86, phaseOffset: 0),
                    PulseOscillator(target: .height(.two), from: 0.776, to: 1.294, period: 2.106, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.two), from: 26.4, to: -29.7, period: 3.572, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.two), from: -33, to: 21.45, period: 3.572, phaseOffset: 0),
                    PulseOscillator(target: .width(.three), from: 0.832, to: 1.322, period: 2.548, phaseOffset: 0),
                    PulseOscillator(target: .height(.three), from: 1.21, to: 0.72, period: 3.64, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.three), from: -19.8, to: 33, period: 2.755, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.three), from: -28.05, to: 14.85, period: 2.755, phaseOffset: 0),
                    PulseOscillator(target: .globalHeight, from: 0.66, to: 1.34, period: 2.4, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topLeading), from: 0.52, to: 1, period: 1.9, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topTrailing), from: 0.52, to: 1, period: 2.508, phaseOffset: 0.532),
                    PulseOscillator(target: .quadrantOpacity(.bottomLeading), from: 0.52, to: 1, period: 1.596, phaseOffset: 1.045),
                    PulseOscillator(target: .quadrantOpacity(.bottomTrailing), from: 0.52, to: 1, period: 3.002, phaseOffset: 1.577),
                ],
                frozenBloomAlpha: 0.76
            ),
            .light: PulseThemeTuning(
                parameters: PulseParameters(
                    sizeAmplitude: 0.28,
                    driftRange: 40,
                    opacityAmplitude: 0.45,
                    heightAmplitude: 0.22,
                    driftPeriod: 2.6,
                    sizePeriod: 4.6,
                    heightPeriod: 5.5,
                    huePeriod: 16
                ),
                oscillators: [
                    PulseOscillator(target: .width(.one), from: 0.72, to: 1.308, period: 4.14, phaseOffset: 0),
                    PulseOscillator(target: .height(.one), from: 1.252, to: 0.762, period: 5.796, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.one), from: -40, to: 36, period: 4.16, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.one), from: 22, to: -28, period: 4.16, phaseOffset: 0),
                    PulseOscillator(target: .width(.two), from: 1.28, to: 0.762, period: 5.06, phaseOffset: 0),
                    PulseOscillator(target: .height(.two), from: 0.776, to: 1.294, period: 3.726, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.two), from: 32, to: -36, period: 4.888, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.two), from: -40, to: 26, period: 4.888, phaseOffset: 0),
                    PulseOscillator(target: .width(.three), from: 0.832, to: 1.322, period: 4.508, phaseOffset: 0),
                    PulseOscillator(target: .height(.three), from: 1.21, to: 0.72, period: 6.44, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.three), from: -24, to: 40, period: 3.77, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.three), from: -34, to: 18, period: 3.77, phaseOffset: 0),
                    PulseOscillator(target: .globalHeight, from: 0.78, to: 1.22, period: 5.5, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topLeading), from: 0.55, to: 1, period: 2.6, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topTrailing), from: 0.55, to: 1, period: 3.432, phaseOffset: 0.728),
                    PulseOscillator(target: .quadrantOpacity(.bottomLeading), from: 0.55, to: 1, period: 2.184, phaseOffset: 1.43),
                    PulseOscillator(target: .quadrantOpacity(.bottomTrailing), from: 0.55, to: 1, period: 4.108, phaseOffset: 2.158),
                ],
                frozenBloomAlpha: 0.775
            ),
        ],
        outward: [
            .dark: PulseThemeTuning(
                parameters: PulseParameters(
                    sizeAmplitude: 0.28,
                    driftRange: 14,
                    opacityAmplitude: 0.46,
                    heightAmplitude: 0.16,
                    driftPeriod: 2.3,
                    sizePeriod: 6.4,
                    heightPeriod: 2.4,
                    huePeriod: 14
                ),
                oscillators: [
                    PulseOscillator(target: .width(.one), from: 0.72, to: 1.308, period: 5.76, phaseOffset: 0),
                    PulseOscillator(target: .height(.one), from: 1.252, to: 0.762, period: 8.064, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.one), from: -14, to: 12.6, period: 3.68, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.one), from: 7.7, to: -9.8, period: 3.68, phaseOffset: 0),
                    PulseOscillator(target: .width(.two), from: 1.28, to: 0.762, period: 7.04, phaseOffset: 0),
                    PulseOscillator(target: .height(.two), from: 0.776, to: 1.294, period: 5.184, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.two), from: 11.2, to: -12.6, period: 4.324, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.two), from: -14, to: 9.1, period: 4.324, phaseOffset: 0),
                    PulseOscillator(target: .width(.three), from: 0.832, to: 1.322, period: 6.272, phaseOffset: 0),
                    PulseOscillator(target: .height(.three), from: 1.21, to: 0.72, period: 8.96, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.three), from: -8.4, to: 14, period: 3.335, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.three), from: -11.9, to: 6.3, period: 3.335, phaseOffset: 0),
                    PulseOscillator(target: .globalHeight, from: 0.84, to: 1.16, period: 2.4, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topLeading), from: 0.54, to: 1, period: 2.3, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topTrailing), from: 0.54, to: 1, period: 3.036, phaseOffset: 0.644),
                    PulseOscillator(target: .quadrantOpacity(.bottomLeading), from: 0.54, to: 1, period: 1.932, phaseOffset: 1.265),
                    PulseOscillator(target: .quadrantOpacity(.bottomTrailing), from: 0.54, to: 1, period: 3.634, phaseOffset: 1.909),
                ],
                frozenBloomAlpha: 0.77
            ),
            .light: PulseThemeTuning(
                parameters: PulseParameters(
                    sizeAmplitude: 0.36,
                    driftRange: 19,
                    opacityAmplitude: 0,
                    heightAmplitude: 0.58,
                    driftPeriod: 3.7,
                    sizePeriod: 4.6,
                    heightPeriod: 3.8,
                    huePeriod: 14
                ),
                oscillators: [
                    PulseOscillator(target: .width(.one), from: 0.64, to: 1.396, period: 4.14, phaseOffset: 0),
                    PulseOscillator(target: .height(.one), from: 1.324, to: 0.694, period: 5.796, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.one), from: -19, to: 17.1, period: 5.92, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.one), from: 10.45, to: -13.3, period: 5.92, phaseOffset: 0),
                    PulseOscillator(target: .width(.two), from: 1.36, to: 0.694, period: 5.06, phaseOffset: 0),
                    PulseOscillator(target: .height(.two), from: 0.712, to: 1.378, period: 3.726, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.two), from: 15.2, to: -17.1, period: 6.956, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.two), from: -19, to: 12.35, period: 6.956, phaseOffset: 0),
                    PulseOscillator(target: .width(.three), from: 0.784, to: 1.414, period: 4.508, phaseOffset: 0),
                    PulseOscillator(target: .height(.three), from: 1.27, to: 0.64, period: 6.44, phaseOffset: 0),
                    PulseOscillator(target: .driftX(.three), from: -11.4, to: 19, period: 5.365, phaseOffset: 0),
                    PulseOscillator(target: .driftY(.three), from: -16.15, to: 8.55, period: 5.365, phaseOffset: 0),
                    PulseOscillator(target: .globalHeight, from: 0.42, to: 1.58, period: 3.8, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topLeading), from: 1, to: 1, period: 3.7, phaseOffset: 0),
                    PulseOscillator(target: .quadrantOpacity(.topTrailing), from: 1, to: 1, period: 4.884, phaseOffset: 1.036),
                    PulseOscillator(target: .quadrantOpacity(.bottomLeading), from: 1, to: 1, period: 3.108, phaseOffset: 2.035),
                    PulseOscillator(target: .quadrantOpacity(.bottomTrailing), from: 1, to: 1, period: 5.846, phaseOffset: 3.071),
                ],
                frozenBloomAlpha: 1
            ),
        ]
    )
}
