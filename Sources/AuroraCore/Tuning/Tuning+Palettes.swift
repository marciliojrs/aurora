// Tuned constants for the glow. Generated data, edited only when the design changes.
//
// These live as Swift literals rather than as a bundled payload so they are type-checked at build
// time, need no resource bundle, and cannot fail to load at runtime.


extension Tuning {

    static let standardPerimeterPalettes: [PaletteBase: [PaletteBlob]] = [
        .spectrum: [
            PaletteBlob(color: AuroraColor(r: 255, g: 50, b: 100), position: AuroraPoint(x: .percent(33), y: .percent(-7.4)), radii: AuroraSizeSpec(width: .points(70), height: .points(40))),
            PaletteBlob(color: AuroraColor(r: 40, g: 140, b: 255), position: AuroraPoint(x: .percent(12), y: .percent(-5)), radii: AuroraSizeSpec(width: .points(60), height: .points(35))),
            PaletteBlob(color: AuroraColor(r: 50, g: 200, b: 80), position: AuroraPoint(x: .percent(2.1), y: .percent(68.3)), radii: AuroraSizeSpec(width: .points(40), height: .points(70))),
            PaletteBlob(color: AuroraColor(r: 30, g: 185, b: 170), position: AuroraPoint(x: .percent(2.1), y: .percent(68.3)), radii: AuroraSizeSpec(width: .points(20), height: .points(35))),
            PaletteBlob(color: AuroraColor(r: 100, g: 70, b: 255), position: AuroraPoint(x: .percent(74.4), y: .percent(100)), radii: AuroraSizeSpec(width: .points(180), height: .points(32))),
            PaletteBlob(color: AuroraColor(r: 40, g: 140, b: 255), position: AuroraPoint(x: .percent(55), y: .percent(100)), radii: AuroraSizeSpec(width: .points(85), height: .points(26))),
            PaletteBlob(color: AuroraColor(r: 255, g: 120, b: 40), position: AuroraPoint(x: .percent(93.9), y: .percent(0)), radii: AuroraSizeSpec(width: .points(74), height: .points(32))),
            PaletteBlob(color: AuroraColor(r: 240, g: 50, b: 180), position: AuroraPoint(x: .percent(100), y: .percent(27.1)), radii: AuroraSizeSpec(width: .points(26), height: .points(42))),
            PaletteBlob(color: AuroraColor(r: 180, g: 40, b: 240), position: AuroraPoint(x: .percent(100), y: .percent(27.1)), radii: AuroraSizeSpec(width: .points(52), height: .points(48))),
        ],
        .neutral: [
            PaletteBlob(color: AuroraColor(r: 180, g: 180, b: 180), position: AuroraPoint(x: .percent(33), y: .percent(-7.4)), radii: AuroraSizeSpec(width: .points(70), height: .points(40))),
            PaletteBlob(color: AuroraColor(r: 140, g: 140, b: 140), position: AuroraPoint(x: .percent(12), y: .percent(-5)), radii: AuroraSizeSpec(width: .points(60), height: .points(35))),
            PaletteBlob(color: AuroraColor(r: 160, g: 160, b: 160), position: AuroraPoint(x: .percent(2.1), y: .percent(68.3)), radii: AuroraSizeSpec(width: .points(40), height: .points(70))),
            PaletteBlob(color: AuroraColor(r: 130, g: 130, b: 130), position: AuroraPoint(x: .percent(2.1), y: .percent(68.3)), radii: AuroraSizeSpec(width: .points(20), height: .points(35))),
            PaletteBlob(color: AuroraColor(r: 170, g: 170, b: 170), position: AuroraPoint(x: .percent(74.4), y: .percent(100)), radii: AuroraSizeSpec(width: .points(180), height: .points(32))),
            PaletteBlob(color: AuroraColor(r: 150, g: 150, b: 150), position: AuroraPoint(x: .percent(55), y: .percent(100)), radii: AuroraSizeSpec(width: .points(85), height: .points(26))),
            PaletteBlob(color: AuroraColor(r: 190, g: 190, b: 190), position: AuroraPoint(x: .percent(93.9), y: .percent(0)), radii: AuroraSizeSpec(width: .points(74), height: .points(32))),
            PaletteBlob(color: AuroraColor(r: 145, g: 145, b: 145), position: AuroraPoint(x: .percent(100), y: .percent(27.1)), radii: AuroraSizeSpec(width: .points(26), height: .points(42))),
            PaletteBlob(color: AuroraColor(r: 165, g: 165, b: 165), position: AuroraPoint(x: .percent(100), y: .percent(27.1)), radii: AuroraSizeSpec(width: .points(52), height: .points(48))),
        ],
    ]

    static let standardCompactPalettes: [PaletteBase: CompactPalette] = [
        .spectrum: CompactPalette(
            perimeter: [
                PaletteBlob(color: AuroraColor(r: 50, g: 200, b: 80), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(9), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 30, g: 185, b: 170), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(4), height: .points(8))),
                PaletteBlob(color: AuroraColor(r: 255, g: 120, b: 40), position: AuroraPoint(x: .percent(72), y: .percent(-3)), radii: AuroraSizeSpec(width: .points(59), height: .points(9))),
                PaletteBlob(color: AuroraColor(r: 100, g: 70, b: 255), position: AuroraPoint(x: .percent(74), y: .percent(100)), radii: AuroraSizeSpec(width: .points(42), height: .points(7))),
                PaletteBlob(color: AuroraColor(r: 240, g: 50, b: 180), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(17))),
                PaletteBlob(color: AuroraColor(r: 180, g: 40, b: 240), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 40, g: 140, b: 255), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(5), height: .points(10))),
                PaletteBlob(color: AuroraColor(r: 255, g: 50, b: 100), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(11), height: .points(12))),
            ],
            inner: [
                PaletteBlob(color: AuroraColor(r: 50, g: 200, b: 80, a: 0.5), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(9), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 30, g: 185, b: 170, a: 0.45), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(4), height: .points(8))),
                PaletteBlob(color: AuroraColor(r: 255, g: 120, b: 40, a: 0.35), position: AuroraPoint(x: .percent(72), y: .percent(-3)), radii: AuroraSizeSpec(width: .points(59), height: .points(9))),
                PaletteBlob(color: AuroraColor(r: 100, g: 70, b: 255, a: 0.35), position: AuroraPoint(x: .percent(74), y: .percent(100)), radii: AuroraSizeSpec(width: .points(42), height: .points(7))),
                PaletteBlob(color: AuroraColor(r: 240, g: 50, b: 180, a: 0.3), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(17))),
                PaletteBlob(color: AuroraColor(r: 180, g: 40, b: 240, a: 0.4), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 40, g: 140, b: 255, a: 0.3), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(5), height: .points(10))),
                PaletteBlob(color: AuroraColor(r: 255, g: 50, b: 100, a: 0.3), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(11), height: .points(12))),
            ]
        ),
        .neutral: CompactPalette(
            perimeter: [
                PaletteBlob(color: AuroraColor(r: 160, g: 160, b: 160), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(9), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 140, g: 140, b: 140), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(4), height: .points(8))),
                PaletteBlob(color: AuroraColor(r: 180, g: 180, b: 180), position: AuroraPoint(x: .percent(72), y: .percent(-3)), radii: AuroraSizeSpec(width: .points(59), height: .points(9))),
                PaletteBlob(color: AuroraColor(r: 150, g: 150, b: 150), position: AuroraPoint(x: .percent(74), y: .percent(100)), radii: AuroraSizeSpec(width: .points(42), height: .points(7))),
                PaletteBlob(color: AuroraColor(r: 170, g: 170, b: 170), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(17))),
                PaletteBlob(color: AuroraColor(r: 155, g: 155, b: 155), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 145, g: 145, b: 145), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(5), height: .points(10))),
                PaletteBlob(color: AuroraColor(r: 165, g: 165, b: 165), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(11), height: .points(12))),
            ],
            inner: [
                PaletteBlob(color: AuroraColor(r: 160, g: 160, b: 160, a: 0.25), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(9), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 140, g: 140, b: 140, a: 0.22), position: AuroraPoint(x: .percent(2), y: .percent(68)), radii: AuroraSizeSpec(width: .points(4), height: .points(8))),
                PaletteBlob(color: AuroraColor(r: 180, g: 180, b: 180, a: 0.17), position: AuroraPoint(x: .percent(72), y: .percent(-3)), radii: AuroraSizeSpec(width: .points(59), height: .points(9))),
                PaletteBlob(color: AuroraColor(r: 150, g: 150, b: 150, a: 0.17), position: AuroraPoint(x: .percent(74), y: .percent(100)), radii: AuroraSizeSpec(width: .points(42), height: .points(7))),
                PaletteBlob(color: AuroraColor(r: 170, g: 170, b: 170, a: 0.15), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(17))),
                PaletteBlob(color: AuroraColor(r: 155, g: 155, b: 155, a: 0.2), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(10), height: .points(18))),
                PaletteBlob(color: AuroraColor(r: 145, g: 145, b: 145, a: 0.15), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(5), height: .points(10))),
                PaletteBlob(color: AuroraColor(r: 165, g: 165, b: 165, a: 0.15), position: AuroraPoint(x: .percent(100), y: .percent(27)), radii: AuroraSizeSpec(width: .points(11), height: .points(12))),
            ]
        ),
    ]

    static let standardLinePalettes: [PaletteBase: [AuroraResolvedTheme: [LineBlob]]] = [
        .spectrum: [
            .dark: [
                LineBlob(color: AuroraColor(r: 255, g: 50, b: 100), width: 36, height: 36, horizontalOffset: 0, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 40, g: 180, b: 220), width: 30, height: 32, horizontalOffset: 39, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 50, g: 200, b: 80), width: 33, height: 28, horizontalOffset: -36, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 180, g: 40, b: 240), width: 29, height: 34, horizontalOffset: -54, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 255, g: 160, b: 30), width: 27, height: 30, horizontalOffset: 51, verticalOffset: -1),
                LineBlob(color: AuroraColor(r: 100, g: 70, b: 255), width: 36, height: 24, horizontalOffset: 21, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 40, g: 140, b: 255), width: 30, height: 22, horizontalOffset: -21, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 240, g: 50, b: 180), width: 25, height: 28, horizontalOffset: 66, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 30, g: 185, b: 170), width: 23, height: 30, horizontalOffset: -66, verticalOffset: -1),
            ],
            .light: [
                LineBlob(color: AuroraColor(r: 255, g: 50, b: 100), width: 45, height: 36, horizontalOffset: 0, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 40, g: 140, b: 255), width: 35, height: 32, horizontalOffset: 65, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 50, g: 200, b: 80), width: 40, height: 28, horizontalOffset: -60, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 180, g: 40, b: 240), width: 35, height: 34, horizontalOffset: -90, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 30, g: 185, b: 170), width: 38, height: 30, horizontalOffset: 85, verticalOffset: -1),
                LineBlob(color: AuroraColor(r: 100, g: 70, b: 255), width: 50, height: 24, horizontalOffset: 35, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 40, g: 140, b: 255), width: 40, height: 22, horizontalOffset: -35, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 255, g: 120, b: 40), width: 35, height: 28, horizontalOffset: 110, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 240, g: 50, b: 180), width: 30, height: 30, horizontalOffset: -110, verticalOffset: -1),
            ],
        ],
        .neutral: [
            .dark: [
                LineBlob(color: AuroraColor(r: 200, g: 200, b: 200), width: 36, height: 36, horizontalOffset: 0, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 170, g: 170, b: 170), width: 30, height: 32, horizontalOffset: 39, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 155, g: 155, b: 155), width: 33, height: 28, horizontalOffset: -36, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 185, g: 185, b: 185), width: 29, height: 34, horizontalOffset: -54, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 165, g: 165, b: 165), width: 27, height: 30, horizontalOffset: 51, verticalOffset: -1),
                LineBlob(color: AuroraColor(r: 180, g: 180, b: 180), width: 36, height: 24, horizontalOffset: 21, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 160, g: 160, b: 160), width: 30, height: 22, horizontalOffset: -21, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 175, g: 175, b: 175), width: 25, height: 28, horizontalOffset: 66, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 190, g: 190, b: 190), width: 23, height: 30, horizontalOffset: -66, verticalOffset: -1),
            ],
            .light: [
                LineBlob(color: AuroraColor(r: 100, g: 100, b: 100), width: 45, height: 36, horizontalOffset: 0, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 80, g: 80, b: 80), width: 35, height: 32, horizontalOffset: 65, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 90, g: 90, b: 90), width: 40, height: 28, horizontalOffset: -60, verticalOffset: 2),
                LineBlob(color: AuroraColor(r: 70, g: 70, b: 70), width: 35, height: 34, horizontalOffset: -90, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 85, g: 85, b: 85), width: 38, height: 30, horizontalOffset: 85, verticalOffset: -1),
                LineBlob(color: AuroraColor(r: 95, g: 95, b: 95), width: 50, height: 24, horizontalOffset: 35, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 75, g: 75, b: 75), width: 40, height: 22, horizontalOffset: -35, verticalOffset: 0),
                LineBlob(color: AuroraColor(r: 105, g: 105, b: 105), width: 35, height: 28, horizontalOffset: 110, verticalOffset: 1),
                LineBlob(color: AuroraColor(r: 65, g: 65, b: 65), width: 30, height: 30, horizontalOffset: -110, verticalOffset: -1),
            ],
        ],
    ]

    static let standardLineInnerPalettes: [PaletteBase: [LineBlob]] = [
        .spectrum: [
            LineBlob(color: AuroraColor(r: 255, g: 50, b: 100, a: 0.48), width: 33, height: 30, horizontalOffset: 0, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 40, g: 180, b: 220, a: 0.42), width: 24, height: 26, horizontalOffset: 39, verticalOffset: -3),
            LineBlob(color: AuroraColor(r: 50, g: 200, b: 80, a: 0.48), width: 27, height: 24, horizontalOffset: -36, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 180, g: 40, b: 240, a: 0.42), width: 23, height: 28, horizontalOffset: -54, verticalOffset: -2),
            LineBlob(color: AuroraColor(r: 255, g: 160, b: 30, a: 0.5), width: 24, height: 24, horizontalOffset: 51, verticalOffset: -1),
            LineBlob(color: AuroraColor(r: 100, g: 70, b: 255, a: 0.45), width: 30, height: 20, horizontalOffset: 21, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 40, g: 140, b: 255, a: 0.4), width: 25, height: 18, horizontalOffset: -21, verticalOffset: -2),
            LineBlob(color: AuroraColor(r: 240, g: 50, b: 180, a: 0.45), width: 21, height: 24, horizontalOffset: 66, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 30, g: 185, b: 170, a: 0.52), width: 18, height: 26, horizontalOffset: -66, verticalOffset: -1),
        ],
        .neutral: [
            LineBlob(color: AuroraColor(r: 200, g: 200, b: 200, a: 0.48), width: 33, height: 30, horizontalOffset: 0, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 170, g: 170, b: 170, a: 0.42), width: 24, height: 26, horizontalOffset: 39, verticalOffset: -3),
            LineBlob(color: AuroraColor(r: 155, g: 155, b: 155, a: 0.48), width: 27, height: 24, horizontalOffset: -36, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 185, g: 185, b: 185, a: 0.42), width: 23, height: 28, horizontalOffset: -54, verticalOffset: -2),
            LineBlob(color: AuroraColor(r: 165, g: 165, b: 165, a: 0.5), width: 24, height: 24, horizontalOffset: 51, verticalOffset: -1),
            LineBlob(color: AuroraColor(r: 180, g: 180, b: 180, a: 0.45), width: 30, height: 20, horizontalOffset: 21, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 160, g: 160, b: 160, a: 0.4), width: 25, height: 18, horizontalOffset: -21, verticalOffset: -2),
            LineBlob(color: AuroraColor(r: 175, g: 175, b: 175, a: 0.45), width: 21, height: 24, horizontalOffset: 66, verticalOffset: 0),
            LineBlob(color: AuroraColor(r: 190, g: 190, b: 190, a: 0.52), width: 18, height: 26, horizontalOffset: -66, verticalOffset: -1),
        ],
    ]
}
