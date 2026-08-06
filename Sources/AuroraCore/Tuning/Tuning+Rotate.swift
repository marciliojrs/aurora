// Tuned constants for the glow. Generated data, edited only when the design changes.
//
// These live as Swift literals rather than as a bundled payload so they are type-checked at build
// time, need no resource bundle, and cannot fail to load at runtime.


extension Tuning {

    static let standardRotate = RotateTuning(
        highlightStops: [
            .dark: [
                AlphaStop(location: 0, alpha: 0),
                AlphaStop(location: 0.54, alpha: 0),
                AlphaStop(location: 0.57, alpha: 0.1),
                AlphaStop(location: 0.6, alpha: 0.3),
                AlphaStop(location: 0.63, alpha: 0.6),
                AlphaStop(location: 0.66, alpha: 0.75),
                AlphaStop(location: 0.69, alpha: 0.6),
                AlphaStop(location: 0.72, alpha: 0.3),
                AlphaStop(location: 0.75, alpha: 0.1),
                AlphaStop(location: 0.78, alpha: 0),
                AlphaStop(location: 1, alpha: 0),
            ],
            .light: [
                AlphaStop(location: 0, alpha: 0),
                AlphaStop(location: 0.54, alpha: 0),
                AlphaStop(location: 0.57, alpha: 0.08),
                AlphaStop(location: 0.6, alpha: 0.2),
                AlphaStop(location: 0.63, alpha: 0.4),
                AlphaStop(location: 0.66, alpha: 0.55),
                AlphaStop(location: 0.69, alpha: 0.4),
                AlphaStop(location: 0.72, alpha: 0.2),
                AlphaStop(location: 0.75, alpha: 0.08),
                AlphaStop(location: 0.78, alpha: 0),
                AlphaStop(location: 1, alpha: 0),
            ],
        ],
        bloomStops: [
            .dark: [
                AlphaStop(location: 0, alpha: 0),
                AlphaStop(location: 0.58, alpha: 0),
                AlphaStop(location: 0.62, alpha: 0.03),
                AlphaStop(location: 0.65, alpha: 0.08),
                AlphaStop(location: 0.67, alpha: 0.2),
                AlphaStop(location: 0.69, alpha: 0.45),
                AlphaStop(location: 0.7, alpha: 0.85),
                AlphaStop(location: 0.705, alpha: 0.85),
                AlphaStop(location: 0.715, alpha: 0.45),
                AlphaStop(location: 0.73, alpha: 0.2),
                AlphaStop(location: 0.75, alpha: 0.08),
                AlphaStop(location: 0.78, alpha: 0.03),
                AlphaStop(location: 0.82, alpha: 0),
            ],
            .light: [
                AlphaStop(location: 0, alpha: 0),
                AlphaStop(location: 0.58, alpha: 0),
                AlphaStop(location: 0.62, alpha: 0.02),
                AlphaStop(location: 0.65, alpha: 0.08),
                AlphaStop(location: 0.67, alpha: 0.2),
                AlphaStop(location: 0.69, alpha: 0.4),
                AlphaStop(location: 0.7, alpha: 0.6),
                AlphaStop(location: 0.705, alpha: 0.6),
                AlphaStop(location: 0.715, alpha: 0.4),
                AlphaStop(location: 0.73, alpha: 0.2),
                AlphaStop(location: 0.75, alpha: 0.08),
                AlphaStop(location: 0.78, alpha: 0.02),
                AlphaStop(location: 0.82, alpha: 0),
            ],
        ],
        sweepMaskStops: [
            AlphaStop(location: 0, alpha: 0),
            AlphaStop(location: 0.3, alpha: 0),
            AlphaStop(location: 0.36, alpha: 0.1),
            AlphaStop(location: 0.44, alpha: 0.35),
            AlphaStop(location: 0.52, alpha: 1),
            AlphaStop(location: 0.8, alpha: 1),
            AlphaStop(location: 0.86, alpha: 0.35),
            AlphaStop(location: 0.92, alpha: 0.1),
            AlphaStop(location: 0.95, alpha: 0),
            AlphaStop(location: 1, alpha: 0),
        ],
        compactMaskStops: [
            AlphaStop(location: 0, alpha: 0),
            AlphaStop(location: 0.22, alpha: 0),
            AlphaStop(location: 0.28, alpha: 0.12),
            AlphaStop(location: 0.36, alpha: 0.4),
            AlphaStop(location: 0.46, alpha: 1),
            AlphaStop(location: 0.82, alpha: 1),
            AlphaStop(location: 0.88, alpha: 0.4),
            AlphaStop(location: 0.94, alpha: 0.12),
            AlphaStop(location: 0.97, alpha: 0),
            AlphaStop(location: 1, alpha: 0),
        ],
        innerGlow: RotateTuning.InnerGlow(radiiScale: 0.9, alpha: 0.45, uniformAlpha: 0.225),
        innerEdgeInset: 28,
        standardInnerShadowBlur: 9,
        compactInnerShadowBlur: 5,
        bloomBlurRadius: 8
    )

    static let standardLine = LineTuning(
        travelPosition: [
            Keyframe(position: 0, value: 0.06),
            Keyframe(position: 0.1, value: 0.15),
            Keyframe(position: 0.2, value: 0.25),
            Keyframe(position: 0.3, value: 0.35),
            Keyframe(position: 0.4, value: 0.44),
            Keyframe(position: 0.5, value: 0.5),
            Keyframe(position: 0.6, value: 0.56),
            Keyframe(position: 0.7, value: 0.65),
            Keyframe(position: 0.8, value: 0.75),
            Keyframe(position: 0.9, value: 0.85),
            Keyframe(position: 1, value: 0.94),
        ],
        travelWidth: [
            Keyframe(position: 0, value: 0.5),
            Keyframe(position: 0.1, value: 0.8),
            Keyframe(position: 0.2, value: 1.1),
            Keyframe(position: 0.3, value: 1.3),
            Keyframe(position: 0.4, value: 1.45),
            Keyframe(position: 0.5, value: 1.5),
            Keyframe(position: 0.6, value: 1.45),
            Keyframe(position: 0.7, value: 1.3),
            Keyframe(position: 0.8, value: 1.1),
            Keyframe(position: 0.9, value: 0.8),
            Keyframe(position: 1, value: 0.5),
        ],
        edgeFade: [
            Keyframe(position: 0, value: 0),
            Keyframe(position: 0.125, value: 0),
            Keyframe(position: 0.325, value: 1),
            Keyframe(position: 0.675, value: 1),
            Keyframe(position: 0.875, value: 0),
            Keyframe(position: 1, value: 0),
        ],
        breathe: [
            Keyframe(position: 0, value: 0.8),
            Keyframe(position: 0.25, value: 1.25),
            Keyframe(position: 0.55, value: 0.85),
            Keyframe(position: 0.8, value: 1.3),
            Keyframe(position: 1, value: 0.8),
        ],
        spike: [
            Keyframe(position: 0, value: 0.8),
            Keyframe(position: 0.25, value: 1.3),
            Keyframe(position: 0.5, value: 0.9),
            Keyframe(position: 0.75, value: 1.4),
            Keyframe(position: 1, value: 0.8),
        ],
        alternateSpike: [
            Keyframe(position: 0, value: 1.2),
            Keyframe(position: 0.25, value: 0.7),
            Keyframe(position: 0.5, value: 1.4),
            Keyframe(position: 0.75, value: 0.8),
            Keyframe(position: 1, value: 1.2),
        ],
        durationScale: LineTuning.DurationScale(
            travel: 1,
            edgeFade: 1,
            breathe: 1.3,
            spike: 1.33,
            alternateSpike: 1.7
        ),
        easing: LineTuning.Easings(
            travel: .linear,
            edgeFade: .linear,
            breathe: .easeInOut,
            spike: .easeInOut,
            alternateSpike: .easeInOut
        ),
        headMask: LineTuning.MaskEllipse(width: 78, height: 60, softStop: AlphaStop(location: 0.45, alpha: 0.5)),
        bloomMask: LineTuning.MaskEllipse(width: 84, height: 110, softStop: AlphaStop(location: 0.35, alpha: 0.5)),
        highlight: [
            .dark: LineTuning.Highlight(
                width: 24, height: 28, verticalOffset: 2,
                tint: .white,
                stops: [
                    AlphaStop(location: 0, alpha: 0.38),
                    AlphaStop(location: 0.3, alpha: 0.12),
                    AlphaStop(location: 0.65, alpha: 0),
                ]
            ),
            .light: LineTuning.Highlight(
                width: 35, height: 28, verticalOffset: 2,
                tint: .black,
                stops: [
                    AlphaStop(location: 0, alpha: 0.6),
                    AlphaStop(location: 0.35, alpha: 0.25),
                    AlphaStop(location: 0.7, alpha: 0),
                ]
            ),
        ],
        neutralBloomBlurRadius: 6,
        bloomBlurRadius: 8,
        bloomBlobs: standardLineBloomBlobs
    )
}
