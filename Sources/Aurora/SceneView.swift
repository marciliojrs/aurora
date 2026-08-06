import AuroraCore
import SwiftUI

/// Renders the layers of a ``AuroraScene`` that belong to one placement.
///
/// Each layer gets its own `Canvas` rather than sharing one, for a specific reason: blur
/// and opacity are per-layer, and `.blur(radius:)` is a view effect applied to a finished
/// rasterization. Drawing every layer into a single canvas would force the blur onto the
/// whole stack, turning the crisp 1pt ring into mush along with the bloom it was meant to
/// soften.
struct SceneView: View {
    let scene: AuroraScene
    let placement: AuroraLayer.Placement

    var body: some View {
        ZStack {
            ForEach(layers, id: \.offset) { layer in
                Canvas(
                    opaque: false,
                    colorMode: .nonLinear,
                    rendersAsynchronously: false
                ) { context, _ in
                    context.render(layer.element, sceneOffset: sceneOffset)
                }
                .blur(radius: layer.element.blurRadius)
                .opacity(layer.element.opacity)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        // Purely decorative, and it covers the content it decorates — without this it would
        // swallow every tap meant for the wrapped view.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var layers: [(offset: Int, element: AuroraLayer)] {
        let filtered = placement == .behindContent
            ? scene.layersBehindContent
            : scene.layersAboveContent
        return Array(filtered.enumerated())
    }

    /// The canvas grows by the scene's outset on all sides so an outward halo has room to
    /// render. For every other preset the outset is zero and this is the content's size.
    private var canvasSize: CGSize {
        CGSize(
            width: scene.contentSize.width + scene.outset.value * 2,
            height: scene.contentSize.height + scene.outset.value * 2
        )
    }

    /// Shifts scene coordinates — where the content sits at the origin — into the grown
    /// canvas.
    private var sceneOffset: CGSize {
        CGSize(width: scene.outset.value, height: scene.outset.value)
    }
}
