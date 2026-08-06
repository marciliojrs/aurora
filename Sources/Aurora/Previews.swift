#if DEBUG

import AuroraCore
import SwiftUI

// Previews of the component, one per preset.
//
// These live in the shipping target on purpose. A preview only renders when some scheme builds the file
// it sits in, so previews placed under `Examples/` — which belongs to no package target — cannot render
// at all; Xcode reports "Active scheme does not build this file". Keeping them here means opening
// `Package.swift` is enough to see every preset.
//
// `#if DEBUG` keeps them out of release builds. The interactive showcase, with controls for palette,
// appearance and strength, is demo code and lives in `Examples/`.

// Semantic surfaces for the previews that demonstrate `theme: .auto`.
//
// Spelled per platform because this target builds for macOS and tvOS as well as iOS, and the semantic
// palettes are framework-specific — `UIColor.systemGroupedBackground` does not exist off UIKit. The pair
// matters more than the exact values: the page and the card need *different* values in both schemes, so
// the glow always has an edge to sit against.
extension Color {
    fileprivate static var previewPage: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.15)
        #endif
    }

    fileprivate static var previewCard: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.3)
        #endif
    }
}

/// An opaque card to hang the effect on.
///
/// Opaque rather than translucent because `.pulseOutward` draws its halo *behind* the content: over a
/// see-through card the halo shows through the middle and reads as a smear.
private struct PreviewCard: View {
    var title: String
    var subtitle: String
    var cornerRadius: Double = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct PreviewStage<Content: View>: View {
    /// `.pulseOutward` paints well past its bounds, so the stage leaves room rather than cropping it.
    var padding: Double = 48
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}

#Preview("regular — full border") {
    PreviewStage {
        Aurora(.regular, in: .rounded(cornerRadius: 20)) {
            PreviewCard(title: "Sync in progress", subtitle: "Last updated 2 minutes ago")
        }
    }
}

#Preview("compact — compact control") {
    PreviewStage {
        Text("Generate")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 18)
            .frame(height: 38)
            .background(Color(white: 0.08))
            .clipShape(Capsule())
            // `.capsule` rather than a hand-computed 19: the radius is half the height, and the height
            // moves with Dynamic Type. Naming the shape keeps the glow on the outline at any size.
            .aurora(.compact, in: .capsule)
    }
}

#Preview("underline — bottom edge") {
    PreviewStage {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            Text("Search everything").foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .aurora(.underline, in: .rounded(cornerRadius: 14))
    }
}

#Preview("pulseInward — contained") {
    PreviewStage {
        Aurora(.pulseInward, in: .rounded(cornerRadius: 20)) {
            PreviewCard(title: "Listening", subtitle: "Say something to get started")
        }
    }
}

#Preview("pulseOutward — outward halo") {
    PreviewStage(padding: 72) {
        PreviewCard(title: "Analysing", subtitle: "Working through 1,204 records")
            .aurora(.pulseOutward, in: .rounded(cornerRadius: 20))
    }
}

/// One card per palette shape, since `AuroraColorVariant` carries caller colors and so has no
/// `allCases` to walk. That is the point of the design: a preview names what it wants to show.
private struct PaletteSample: Identifiable {
    let id: Int
    let label: String
    let variant: AuroraColorVariant

    static let all: [PaletteSample] = [
        PaletteSample(id: 0, label: ".glow", variant: .glow),
        PaletteSample(
            id: 1,
            label: ".tinted(iris)",
            variant: .tinted(AuroraColor(r: 70, g: 140, b: 255))
        ),
        PaletteSample(
            id: 2,
            label: ".multiColor([moss, amber])",
            variant: .multiColor([
                AuroraColor(r: 80, g: 200, b: 140),
                AuroraColor(r: 255, g: 170, b: 60),
            ])
        ),
        PaletteSample(id: 3, label: ".neutral", variant: .neutral),
        PaletteSample(id: 4, label: ".cool", variant: .cool),
        PaletteSample(id: 5, label: ".warm", variant: .warm),
    ]
}

#Preview("Palettes") {
    PreviewStage(padding: 24) {
        VStack(spacing: 20) {
            ForEach(PaletteSample.all) { sample in
                Aurora(.regular, in: .rounded(cornerRadius: 16), colorVariant: sample.variant) {
                    PreviewCard(
                        title: sample.label,
                        subtitle: "AuroraColorVariant",
                        cornerRadius: 16
                    )
                }
            }
        }
    }
}

#Preview("Light appearance") {
    Aurora(.regular, in: .rounded(cornerRadius: 20), theme: .light) {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sync in progress").font(.headline)
            Text("Tuned separately for light").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .padding(48)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(white: 0.94))
    .preferredColorScheme(.light)
}

/// `theme: .auto` over semantic surfaces — the configuration most apps will ship.
///
/// Toggle the canvas between light and dark and everything re-tunes: the card follows the scheme
/// because its background is semantic, and the glow follows because `.auto` reads the surrounding
/// scheme. Hardcoding either one breaks the pair, since the palettes are tuned against the surface
/// behind them.
#Preview("Follows the colour scheme") {
    VStack(spacing: 24) {
        Aurora(.regular, in: .rounded(cornerRadius: 20), theme: .auto) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sync in progress").font(.headline)
                Text("theme: .auto").font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.previewCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }

        Aurora(.pulseInward, in: .rounded(cornerRadius: 20), theme: .auto) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Listening").font(.headline)
                Text("theme: .auto").font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.previewCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.previewPage)
}

/// A frozen frame, which is what a snapshot test captures.
///
/// Mid-cycle rather than at zero: the `underline` preset's edge fade sits at zero early on, so freezing near
/// the start renders nothing at all.
#Preview("Frozen — mid-cycle") {
    PreviewStage {
        Aurora(.underline, in: .rounded(cornerRadius: 20)) {
            PreviewCard(title: "Frozen at 1.55s", subtitle: "Reproducible for snapshots")
        }
        .auroraClockFrozen(at: 1.55)
    }
}

#endif
