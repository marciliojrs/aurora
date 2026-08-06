// Tuned constants for the glow. Generated data, edited only when the design changes.
//
// These live as Swift literals rather than as a bundled payload so they are type-checked at build
// time, need no resource bundle, and cannot fail to load at runtime.


import CoreGraphics

extension Tuning {

    static let standardDefaults = Defaults(
        rotateDuration: 1.96,
        lineDuration: 3.1,
        pulseDuration: 1.5,
        hueRange: 30,
        lineHueRangeCap: 13,
        brightnessFallback: 1.3,
        fadeInSeconds: 0.6,
        fadeOutSeconds: 0.5,
        rotateHuePeriod: 12,
        lineBloomHuePeriod: 8,
        lineBloomHueRangeBonus: 10,
        uniformOpacityMultiplier: 0.5,
        uniformPaletteHoldsHue: true,
        pulseSampleRate: 30
    )

    static let standardSizePresets: [AuroraSize: SizePreset] = [
        .compact: SizePreset(cornerRadius: 32, borderWidth: 1, referenceSize: CGSize(width: 70, height: 36)),
        .regular: SizePreset(cornerRadius: 16, borderWidth: 1, referenceSize: nil),
        .underline: SizePreset(cornerRadius: 16, borderWidth: 1, referenceSize: nil),
        .pulseOutward: SizePreset(cornerRadius: 16, borderWidth: 1, referenceSize: nil),
        .pulseInward: SizePreset(cornerRadius: 16, borderWidth: 1, referenceSize: nil),
    ]

    static let standardThemePresets: [AuroraSize: [AuroraResolvedTheme: ThemePreset]] = [
        .compact: [
            .dark: ThemePreset(
                strokeOpacity: 0.46,
                innerOpacity: 0.24,
                bloomOpacity: 0.38,
                innerShadow: AuroraColor(r: 255, g: 255, b: 255, a: 0.3),
                saturation: 1.2,
                brightness: nil,
                hairlineOpacity: 0
            ),
            .light: ThemePreset(
                strokeOpacity: 0.12,
                innerOpacity: 0.3,
                bloomOpacity: 0.16,
                innerShadow: AuroraColor(r: 0, g: 0, b: 0, a: 0.14),
                saturation: 1.8,
                brightness: nil,
                hairlineOpacity: 0
            ),
        ],
        .regular: [
            .dark: ThemePreset(
                strokeOpacity: 0.26,
                innerOpacity: 0.42,
                bloomOpacity: 0.24,
                innerShadow: AuroraColor(r: 255, g: 255, b: 255, a: 0.27),
                saturation: 1.2,
                brightness: nil,
                hairlineOpacity: 0
            ),
            .light: ThemePreset(
                strokeOpacity: 0.12,
                innerOpacity: 0.26,
                bloomOpacity: 0.34,
                innerShadow: AuroraColor(r: 0, g: 0, b: 0, a: 0.14),
                saturation: 1.5,
                brightness: nil,
                hairlineOpacity: 0
            ),
        ],
        .underline: [
            .dark: ThemePreset(
                strokeOpacity: 1.14,
                innerOpacity: 0.7,
                bloomOpacity: 0.8,
                innerShadow: AuroraColor(r: 255, g: 255, b: 255, a: 0.1),
                saturation: 1.2,
                brightness: nil,
                hairlineOpacity: 0
            ),
            .light: ThemePreset(
                strokeOpacity: 0.16,
                innerOpacity: 0.32,
                bloomOpacity: 0.3,
                innerShadow: AuroraColor(r: 0, g: 0, b: 0, a: 0.14),
                saturation: 1.95,
                brightness: nil,
                hairlineOpacity: 0
            ),
        ],
        .pulseOutward: [
            .dark: ThemePreset(
                strokeOpacity: 0.94,
                innerOpacity: 0.34,
                bloomOpacity: 0.3,
                innerShadow: .clear,
                saturation: 1.2,
                brightness: 1.9,
                hairlineOpacity: 0
            ),
            .light: ThemePreset(
                strokeOpacity: 1.96,
                innerOpacity: 1.04,
                bloomOpacity: 0.42,
                innerShadow: .clear,
                saturation: 0.6,
                brightness: 1.7,
                hairlineOpacity: 0
            ),
        ],
        .pulseInward: [
            .dark: ThemePreset(
                strokeOpacity: 1.54,
                innerOpacity: 0.44,
                bloomOpacity: 0.66,
                innerShadow: .clear,
                saturation: 1.2,
                brightness: 0.75,
                hairlineOpacity: 0
            ),
            .light: ThemePreset(
                strokeOpacity: 0.32,
                innerOpacity: 0.4,
                bloomOpacity: 0.8,
                innerShadow: .clear,
                saturation: 0.75,
                brightness: 1.3,
                hairlineOpacity: 0
            ),
        ],
    ]
}
