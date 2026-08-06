import AuroraCore
import SwiftUI

/// Wraps content in an animated aurora.
///
/// ```swift
/// Aurora(.regular, in: .rounded(cornerRadius: 20)) {
///     CardView()
/// }
/// ```
///
/// The effect is decorative and never participates in layout or hit testing: the wrapped
/// content keeps its own size, and taps pass straight through the glow.
///
/// ### Two things to say, and only two
///
/// **Which preset**, and **what outline the host is clipped to**. Everything else — palette, appearance,
/// intensity, tempo — comes from ``AuroraStyle`` in the environment, so a component can attach a glow
/// without deciding how the app looks. Any of it can be overridden per call.
///
/// ### Choosing a preset
///
/// `.compact` and `.regular` both sweep a band of light around the whole border. They differ in tuning
/// rather than in motion, and the tuning is sized around the host — see ``AuroraSize``. `.underline` runs
/// a glow along the bottom edge alone, which suits text fields. `.pulseInward` and `.pulseOutward` breathe
/// in place, better for reporting an ongoing state than for drawing the eye to an edge.
///
/// ### Requirement for `.pulseOutward`
///
/// That preset paints its halo *behind* the wrapped content and lets it spill past the
/// bounds, so the content needs an opaque background. Over a translucent view the halo shows
/// through the middle and reads as a smear rather than as light.
public struct Aurora<Content: View>: View {
    /// Where the configuration comes from.
    private enum Source {
        /// Fully specified by the caller. The inherited style is ignored on purpose: someone who built a
        /// whole configuration has already answered every question it asks.
        case explicit(AuroraConfiguration)
        /// Preset, outline and border from the call site; the rest inherited, with overrides on top.
        case styled(AuroraSize, AuroraShape, Bool, AuroraStyleOverrides)
    }

    private let source: Source
    private let isActive: Bool
    private let onActivate: (() -> Void)?
    private let onDeactivate: (() -> Void)?
    private let content: Content

    @Environment(\.auroraStyle) private var inheritedStyle

    /// Tracks whether the view is in the hierarchy, so a glow scrolled out of a lazy container
    /// stops doing per-frame work.
    @State private var isOnscreen = true

    /// Configures the glow from a value, ignoring the inherited style.
    ///
    /// Use this when the configuration is computed, held in a view model, or read from a design token.
    public init(
        configuration: AuroraConfiguration,
        isActive: Bool = true,
        onActivate: (() -> Void)? = nil,
        onDeactivate: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.source = .explicit(configuration)
        self.isActive = isActive
        self.onActivate = onActivate
        self.onDeactivate = onDeactivate
        self.content = content()
    }

    /// Configures the glow from the inherited ``AuroraStyle``, overriding only what you name.
    ///
    /// - Parameters:
    ///   - size: Which preset to draw. See ``AuroraSize``.
    ///   - shape: The outline the host is clipped to. Naming a shape rather than a radius is what lets
    ///     ``AuroraShape/capsule`` stay correct at any height. See ``AuroraShape``.
    ///   - showsBorder: Draws the host's outline under the glow and lets the effect light it. See
    ///     ``AuroraConfiguration/showsBorder``.
    ///   - colorVariant: Overrides the inherited palette. `nil` inherits.
    ///   - theme: Overrides the inherited appearance. `nil` inherits, which follows the color scheme.
    ///   - strength: Overrides the inherited intensity, `0...1`. `nil` inherits.
    ///   - duration: Overrides the inherited tempo, in seconds per cycle. `nil` inherits.
    ///   - staticColors: Overrides the inherited hue animation. `nil` inherits.
    ///   - isActive: Fades the glow in and out.
    ///   - onActivate: Called once the fade-in finishes.
    ///   - onDeactivate: Called once the fade-out finishes.
    public init(
        _ size: AuroraSize = .regular,
        in shape: AuroraShape = .preset,
        showsBorder: Bool = false,
        colorVariant: AuroraColorVariant? = nil,
        theme: AuroraTheme? = nil,
        strength: Double? = nil,
        duration: Double? = nil,
        staticColors: Bool? = nil,
        isActive: Bool = true,
        onActivate: (() -> Void)? = nil,
        onDeactivate: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.source = .styled(
            size,
            shape,
            showsBorder,
            AuroraStyleOverrides(
                colorVariant: colorVariant,
                theme: theme,
                strength: strength,
                duration: duration,
                staticColors: staticColors
            )
        )
        self.isActive = isActive
        self.onActivate = onActivate
        self.onDeactivate = onDeactivate
        self.content = content()
    }

    /// The configuration for this frame, with the inherited style folded in.
    private var configuration: AuroraConfiguration {
        switch source {
        case .explicit(let configuration):
            configuration
        case .styled(let size, let shape, let showsBorder, let overrides):
            overrides
                .applied(to: inheritedStyle)
                .configuration(size, in: shape, showsBorder: showsBorder)
        }
    }

    public var body: some View {
        content
            .background { decoration(placement: .behindContent) }
            .overlay { decoration(placement: .aboveContent) }
            .onAppear { isOnscreen = true }
            .onDisappear { isOnscreen = false }
    }

    /// One side of the glow, sized to the content.
    ///
    /// The size comes from a `GeometryReader` inside a background or overlay, which reads as the
    /// content's own frame and therefore does not disturb the layout the way a greedy
    /// `GeometryReader` wrapped *around* the content would.
    ///
    /// Reading the size here rather than routing it through a preference and `@State` keeps the
    /// measurement synchronous. A preference update has to hop to the next main-actor turn before
    /// the glow can be drawn, which costs a blank first frame in a live view and produces nothing
    /// at all in a single-pass rasterization such as `ImageRenderer`.
    ///
    /// The activation callbacks go to the above-content side only. Both sides run the same ramp on
    /// the same clock, so handing callbacks to both would fire every one twice.
    private func decoration(placement: AuroraLayer.Placement) -> some View {
        GeometryReader { proxy in
            AuroraDecoration(
                configuration: configuration,
                contentSize: proxy.size,
                placement: placement,
                isActive: isActive,
                isPaused: isOnscreen == false,
                onActivate: placement == .aboveContent ? onActivate : nil,
                onDeactivate: placement == .aboveContent ? onDeactivate : nil
            )
            // A `GeometryReader` pins its content to the top leading corner. The glow's canvas is
            // larger than the content whenever a preset paints outward, so it has to be centred or
            // the halo lands off to one side.
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
