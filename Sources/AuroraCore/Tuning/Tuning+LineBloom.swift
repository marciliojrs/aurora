// Tuned constants for the glow. Generated data, edited only when the design changes.
//
// These live as Swift literals rather than as a bundled payload so they are type-checked at build
// time, need no resource bundle, and cannot fail to load at runtime.


extension Tuning {

    static let standardLineBloomBlobs: [PaletteBase: [AuroraResolvedTheme: [LineBloomBlob]]] = [
        .spectrum: [
            .dark: [
                LineBloomBlob(
                    horizontalFraction: 0.08,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 0.8, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 92, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 255, g: 60, b: 80, a: 1)),
                        AuroraGradientStop(location: 0.3, color: AuroraColor(r: 255, g: 60, b: 80, a: 1)),
                        AuroraGradientStop(location: 0.88, color: AuroraColor(r: 255, g: 60, b: 80, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.22,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 10, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 35, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 40, g: 190, b: 180, a: 0.98)),
                        AuroraGradientStop(location: 0.5, color: AuroraColor(r: 40, g: 190, b: 180, a: 0.49)),
                        AuroraGradientStop(location: 0.95, color: AuroraColor(r: 40, g: 190, b: 180, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.36,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 2, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 72, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 100, g: 70, b: 255, a: 1)),
                        AuroraGradientStop(location: 0.4, color: AuroraColor(r: 100, g: 70, b: 255, a: 1)),
                        AuroraGradientStop(location: 0.9, color: AuroraColor(r: 100, g: 70, b: 255, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.5,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 14, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 28, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 255, g: 170, b: 40, a: 0.59)),
                        AuroraGradientStop(location: 0.55, color: AuroraColor(r: 255, g: 170, b: 40, a: 0.29)),
                        AuroraGradientStop(location: 0.96, color: AuroraColor(r: 255, g: 170, b: 40, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.64,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 1.2, multiplier: .inverseAlternateSpike),
                    height: LineBloomBlob.Axis(base: 85, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 50, g: 200, b: 100, a: 1)),
                        AuroraGradientStop(location: 0.35, color: AuroraColor(r: 50, g: 200, b: 100, a: 1)),
                        AuroraGradientStop(location: 0.89, color: AuroraColor(r: 50, g: 200, b: 100, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.78,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 7, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 45, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 200, g: 50, b: 240, a: 0.91)),
                        AuroraGradientStop(location: 0.48, color: AuroraColor(r: 200, g: 50, b: 240, a: 0.45)),
                        AuroraGradientStop(location: 0.94, color: AuroraColor(r: 200, g: 50, b: 240, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.92,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 0.6, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 60, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 40, g: 140, b: 255, a: 1)),
                        AuroraGradientStop(location: 0.42, color: AuroraColor(r: 40, g: 140, b: 255, a: 1)),
                        AuroraGradientStop(location: 0.91, color: AuroraColor(r: 40, g: 140, b: 255, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: nil,
                    verticalOffset: 1,
                    width: LineBloomBlob.Axis(base: 21, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 15, multiplier: .alternateSpike),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 255, g: 255, b: 255, a: 1)),
                        AuroraGradientStop(location: 0.2, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.9)),
                        AuroraGradientStop(location: 0.5, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.5)),
                        AuroraGradientStop(location: 1, color: AuroraColor(r: 255, g: 255, b: 255, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: nil,
                    verticalOffset: 0,
                    width: LineBloomBlob.Axis(base: 42, multiplier: .headWidth),
                    height: LineBloomBlob.Axis(base: 40, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.3)),
                        AuroraGradientStop(location: 0.25, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.12)),
                        AuroraGradientStop(location: 0.55, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.03)),
                        AuroraGradientStop(location: 0.8, color: AuroraColor(r: 255, g: 255, b: 255, a: 0)),
                    ]
                ),
            ],
            .light: [
                LineBloomBlob(
                    horizontalFraction: 0.08,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 0.8, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 92, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 200, g: 30, b: 60, a: 1)),
                        AuroraGradientStop(location: 0.3, color: AuroraColor(r: 200, g: 30, b: 60, a: 0.85)),
                        AuroraGradientStop(location: 0.88, color: AuroraColor(r: 200, g: 30, b: 60, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.22,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 10, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 35, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 20, g: 150, b: 140, a: 1)),
                        AuroraGradientStop(location: 0.5, color: AuroraColor(r: 20, g: 150, b: 140, a: 0.7)),
                        AuroraGradientStop(location: 0.95, color: AuroraColor(r: 20, g: 150, b: 140, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.36,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 2, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 72, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 80, g: 50, b: 200, a: 1)),
                        AuroraGradientStop(location: 0.4, color: AuroraColor(r: 80, g: 50, b: 200, a: 0.8)),
                        AuroraGradientStop(location: 0.9, color: AuroraColor(r: 80, g: 50, b: 200, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.5,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 14, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 28, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 210, g: 130, b: 0, a: 0.7)),
                        AuroraGradientStop(location: 0.55, color: AuroraColor(r: 210, g: 130, b: 0, a: 0.46)),
                        AuroraGradientStop(location: 0.96, color: AuroraColor(r: 210, g: 130, b: 0, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.64,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 1.2, multiplier: .inverseAlternateSpike),
                    height: LineBloomBlob.Axis(base: 85, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 30, g: 160, b: 70, a: 1)),
                        AuroraGradientStop(location: 0.35, color: AuroraColor(r: 30, g: 160, b: 70, a: 0.82)),
                        AuroraGradientStop(location: 0.89, color: AuroraColor(r: 30, g: 160, b: 70, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.78,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 7, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 45, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 160, g: 30, b: 190, a: 1)),
                        AuroraGradientStop(location: 0.48, color: AuroraColor(r: 160, g: 30, b: 190, a: 0.7)),
                        AuroraGradientStop(location: 0.94, color: AuroraColor(r: 160, g: 30, b: 190, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.92,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 1, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 60, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 30, g: 100, b: 200, a: 1)),
                        AuroraGradientStop(location: 0.42, color: AuroraColor(r: 30, g: 100, b: 200, a: 0.78)),
                        AuroraGradientStop(location: 0.91, color: AuroraColor(r: 30, g: 100, b: 200, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: nil,
                    verticalOffset: 0,
                    width: LineBloomBlob.Axis(base: 50, multiplier: .headWidth),
                    height: LineBloomBlob.Axis(base: 32, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 0, g: 0, b: 0, a: 0.5)),
                        AuroraGradientStop(location: 0.3, color: AuroraColor(r: 0, g: 0, b: 0, a: 0.18)),
                        AuroraGradientStop(location: 0.6, color: AuroraColor(r: 0, g: 0, b: 0, a: 0.03)),
                        AuroraGradientStop(location: 0.85, color: AuroraColor(r: 0, g: 0, b: 0, a: 0)),
                    ]
                ),
            ],
        ],
        .neutral: [
            .dark: [
                LineBloomBlob(
                    horizontalFraction: 0.08,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 12, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 42, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 200, g: 200, b: 200, a: 0.14)),
                        AuroraGradientStop(location: 0.3, color: AuroraColor(r: 200, g: 200, b: 200, a: 0.09)),
                        AuroraGradientStop(location: 0.88, color: AuroraColor(r: 200, g: 200, b: 200, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.22,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 10, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 35, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 170, g: 170, b: 170, a: 0.12)),
                        AuroraGradientStop(location: 0.5, color: AuroraColor(r: 170, g: 170, b: 170, a: 0.06)),
                        AuroraGradientStop(location: 0.95, color: AuroraColor(r: 170, g: 170, b: 170, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.36,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 14, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 38, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 200, g: 200, b: 200, a: 0.14)),
                        AuroraGradientStop(location: 0.4, color: AuroraColor(r: 200, g: 200, b: 200, a: 0.098)),
                        AuroraGradientStop(location: 0.9, color: AuroraColor(r: 200, g: 200, b: 200, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.5,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 14, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 28, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 180, g: 180, b: 180, a: 0.0826)),
                        AuroraGradientStop(location: 0.55, color: AuroraColor(r: 180, g: 180, b: 180, a: 0.0284)),
                        AuroraGradientStop(location: 0.96, color: AuroraColor(r: 180, g: 180, b: 180, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.64,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 12, multiplier: .inverseAlternateSpike),
                    height: LineBloomBlob.Axis(base: 40, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 190, g: 190, b: 190, a: 0.14)),
                        AuroraGradientStop(location: 0.35, color: AuroraColor(r: 190, g: 190, b: 190, a: 0.098)),
                        AuroraGradientStop(location: 0.89, color: AuroraColor(r: 190, g: 190, b: 190, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.78,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 7, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 45, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 170, g: 170, b: 170, a: 0.1274)),
                        AuroraGradientStop(location: 0.48, color: AuroraColor(r: 170, g: 170, b: 170, a: 0.0441)),
                        AuroraGradientStop(location: 0.94, color: AuroraColor(r: 170, g: 170, b: 170, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.92,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 10, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 32, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 185, g: 185, b: 185, a: 0.14)),
                        AuroraGradientStop(location: 0.42, color: AuroraColor(r: 185, g: 185, b: 185, a: 0.098)),
                        AuroraGradientStop(location: 0.91, color: AuroraColor(r: 185, g: 185, b: 185, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: nil,
                    verticalOffset: 1,
                    width: LineBloomBlob.Axis(base: 21, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 15, multiplier: .alternateSpike),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.5)),
                        AuroraGradientStop(location: 0.2, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.45)),
                        AuroraGradientStop(location: 0.5, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.25)),
                        AuroraGradientStop(location: 1, color: AuroraColor(r: 255, g: 255, b: 255, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: nil,
                    verticalOffset: 0,
                    width: LineBloomBlob.Axis(base: 42, multiplier: .headWidth),
                    height: LineBloomBlob.Axis(base: 40, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.15)),
                        AuroraGradientStop(location: 0.25, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.06)),
                        AuroraGradientStop(location: 0.55, color: AuroraColor(r: 255, g: 255, b: 255, a: 0.015)),
                        AuroraGradientStop(location: 0.8, color: AuroraColor(r: 255, g: 255, b: 255, a: 0)),
                    ]
                ),
            ],
            .light: [
                LineBloomBlob(
                    horizontalFraction: 0.08,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 12, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 42, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 80, g: 80, b: 80, a: 0.14)),
                        AuroraGradientStop(location: 0.3, color: AuroraColor(r: 80, g: 80, b: 80, a: 0.11)),
                        AuroraGradientStop(location: 0.88, color: AuroraColor(r: 80, g: 80, b: 80, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.22,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 10, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 35, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 120, g: 120, b: 120, a: 0.12)),
                        AuroraGradientStop(location: 0.5, color: AuroraColor(r: 120, g: 120, b: 120, a: 0.09)),
                        AuroraGradientStop(location: 0.95, color: AuroraColor(r: 120, g: 120, b: 120, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.36,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 14, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 38, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 80, g: 80, b: 80, a: 0.14)),
                        AuroraGradientStop(location: 0.4, color: AuroraColor(r: 80, g: 80, b: 80, a: 0.0784)),
                        AuroraGradientStop(location: 0.9, color: AuroraColor(r: 80, g: 80, b: 80, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.5,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 14, multiplier: .alternateSpike),
                    height: LineBloomBlob.Axis(base: 28, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 100, g: 100, b: 100, a: 0.098)),
                        AuroraGradientStop(location: 0.55, color: AuroraColor(r: 100, g: 100, b: 100, a: 0.0451)),
                        AuroraGradientStop(location: 0.96, color: AuroraColor(r: 100, g: 100, b: 100, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.64,
                    verticalOffset: -4,
                    width: LineBloomBlob.Axis(base: 12, multiplier: .inverseAlternateSpike),
                    height: LineBloomBlob.Axis(base: 40, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 70, g: 70, b: 70, a: 0.14)),
                        AuroraGradientStop(location: 0.35, color: AuroraColor(r: 70, g: 70, b: 70, a: 0.0804)),
                        AuroraGradientStop(location: 0.89, color: AuroraColor(r: 70, g: 70, b: 70, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.78,
                    verticalOffset: -2,
                    width: LineBloomBlob.Axis(base: 7, multiplier: .spike),
                    height: LineBloomBlob.Axis(base: 45, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 90, g: 90, b: 90, a: 0.14)),
                        AuroraGradientStop(location: 0.48, color: AuroraColor(r: 90, g: 90, b: 90, a: 0.0686)),
                        AuroraGradientStop(location: 0.94, color: AuroraColor(r: 90, g: 90, b: 90, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: 0.92,
                    verticalOffset: -3,
                    width: LineBloomBlob.Axis(base: 12, multiplier: .inverseSpike),
                    height: LineBloomBlob.Axis(base: 32, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 85, g: 85, b: 85, a: 0.14)),
                        AuroraGradientStop(location: 0.42, color: AuroraColor(r: 85, g: 85, b: 85, a: 0.0764)),
                        AuroraGradientStop(location: 0.91, color: AuroraColor(r: 85, g: 85, b: 85, a: 0)),
                    ]
                ),
                LineBloomBlob(
                    horizontalFraction: nil,
                    verticalOffset: 0,
                    width: LineBloomBlob.Axis(base: 50, multiplier: .headWidth),
                    height: LineBloomBlob.Axis(base: 32, multiplier: .breathe),
                    stops: [
                        AuroraGradientStop(location: 0, color: AuroraColor(r: 0, g: 0, b: 0, a: 0.5)),
                        AuroraGradientStop(location: 0.3, color: AuroraColor(r: 0, g: 0, b: 0, a: 0.18)),
                        AuroraGradientStop(location: 0.6, color: AuroraColor(r: 0, g: 0, b: 0, a: 0.03)),
                        AuroraGradientStop(location: 0.85, color: AuroraColor(r: 0, g: 0, b: 0, a: 0)),
                    ]
                ),
            ],
        ],
    ]
}
