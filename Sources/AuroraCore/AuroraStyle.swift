/// How the glow looks, without saying where it goes.
///
/// This is the half of ``AuroraConfiguration`` a whole app usually wants to agree on — palette,
/// appearance, intensity, tempo — separated from the half only the call site can know: which preset, and
/// what outline the host is clipped to.
///
/// That split is what lets a component attach a glow without deciding how the app looks:
///
/// ```swift
/// // In the component. Says where, not what color.
/// Text(title)
///     .background(.fill, in: .capsule)
///     .aurora(.compact, in: .capsule)
///
/// // Once, near the root. Says what color, for everything below.
/// RootView()
///     .auroraStyle(AuroraStyle(colorVariant: .tinted(.brand), strength: 0.8))
/// ```
///
/// In SwiftUI it travels through the environment, so restyling a subtree is one modifier and needs no
/// cooperation from the components inside it. UIKit has no equivalent channel, so there you hold a style
/// and hand it over — see `UIView.addAurora(_:in:style:isActive:)`.
public struct AuroraStyle: Hashable, Sendable {
    /// Which palette. See ``AuroraColorVariant``.
    public var colorVariant: AuroraColorVariant

    /// Which appearance to tune colors for.
    ///
    /// ``AuroraTheme/auto`` by default, and deliberately: a component dropped into an unknown screen has
    /// no business pinning the appearance. Pinning is for comparing the two tunings side by side.
    public var theme: AuroraTheme

    /// Overall intensity, `0...1`.
    public var strength: Double

    /// Seconds per cycle. `nil` uses each preset's tuned duration, which differs per preset on purpose.
    public var duration: Double?

    /// Freezes the hue animation.
    public var staticColors: Bool

    /// Degrees of hue drift either side of the base hue. `nil` uses the tuned default.
    public var hueRange: Double?

    public init(
        colorVariant: AuroraColorVariant = .glow,
        theme: AuroraTheme = .auto,
        strength: Double = 1,
        duration: Double? = nil,
        staticColors: Bool = false,
        hueRange: Double? = nil
    ) {
        self.colorVariant = colorVariant
        self.theme = theme
        self.strength = strength
        self.duration = duration
        self.staticColors = staticColors
        self.hueRange = hueRange
    }

    /// The shipped look: the authored spectrum, following the color scheme, at full strength.
    public static let standard = AuroraStyle()

    /// Combines this style with a preset and an outline into something the renderers can consume.
    ///
    /// `showsBorder` sits here rather than on the style because an outline is a fact about the host, like
    /// its shape — not something a whole app agrees on.
    public func configuration(
        _ size: AuroraSize,
        in shape: AuroraShape,
        showsBorder: Bool = false
    ) -> AuroraConfiguration {
        AuroraConfiguration(
            size: size,
            colorVariant: colorVariant,
            theme: theme,
            shape: shape,
            showsBorder: showsBorder,
            staticColors: staticColors,
            duration: duration,
            hueRange: hueRange,
            strength: strength
        )
    }
}
