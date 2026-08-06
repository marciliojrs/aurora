import AuroraCore
import SwiftUI

extension View {
    /// Adds an animated aurora around this view.
    ///
    /// Two arguments carry the weight, and only the first is required:
    ///
    /// ```swift
    /// CardView()
    ///     .aurora(.regular, in: .rounded(cornerRadius: 20))
    ///
    /// SummariseButton()
    ///     .aurora(.compact, in: .capsule)   // no radius arithmetic, correct at any height
    /// ```
    ///
    /// Palette, appearance, intensity and tempo come from the inherited ``AuroraStyle``, so a reusable
    /// component can attach a glow without deciding how the app looks. Set that once with
    /// ``SwiftUI/View/auroraStyle(_:)``, and override it here only where one view needs to differ.
    ///
    /// Equivalent to wrapping the view in ``Aurora``, and preferable when the glow is one decoration among
    /// several in a chain.
    ///
    /// - Parameters:
    ///   - size: Which preset to draw. See ``AuroraSize``.
    ///   - shape: The outline this view is clipped to. Name the same shape you passed to `clipShape` or
    ///     `background(_:in:)`; a mismatch shows at the corners. See ``AuroraShape``.
    ///   - showsBorder: Draws this view's outline under the glow and lets the effect light it. Reach for it
    ///     when the view has no border of its own. See ``AuroraConfiguration/showsBorder``.
    ///   - colorVariant: Overrides the inherited palette. `nil` inherits.
    ///   - theme: Overrides the inherited appearance. `nil` inherits, which follows the color scheme.
    ///   - strength: Overrides the inherited intensity, `0...1`. `nil` inherits.
    ///   - duration: Overrides the inherited tempo, in seconds per cycle. `nil` inherits.
    ///   - staticColors: Overrides the inherited hue animation. `nil` inherits.
    ///   - isActive: Fades the glow in and out.
    ///   - onActivate: Called once the fade-in finishes.
    ///   - onDeactivate: Called once the fade-out finishes.
    public func aurora(
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
        onDeactivate: (() -> Void)? = nil
    ) -> some View {
        Aurora(
            size,
            in: shape,
            showsBorder: showsBorder,
            colorVariant: colorVariant,
            theme: theme,
            strength: strength,
            duration: duration,
            staticColors: staticColors,
            isActive: isActive,
            onActivate: onActivate,
            onDeactivate: onDeactivate
        ) {
            self
        }
    }

    /// Adds an animated aurora configured by value.
    ///
    /// Use this when the configuration is computed, held in a view model, or driven by a
    /// design token — passing one value keeps the call site from growing a dozen arguments.
    public func aurora(
        configuration: AuroraConfiguration,
        isActive: Bool = true,
        onActivate: (() -> Void)? = nil,
        onDeactivate: (() -> Void)? = nil
    ) -> some View {
        Aurora(
            configuration: configuration,
            isActive: isActive,
            onActivate: onActivate,
            onDeactivate: onDeactivate
        ) {
            self
        }
    }
}
