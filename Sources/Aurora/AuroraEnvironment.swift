import AuroraCore
import SwiftUI

private struct AuroraStyleKey: EnvironmentKey {
    static let defaultValue = AuroraStyle.standard
}

extension EnvironmentValues {
    /// The look inherited by every ``Aurora`` below this point that has not been told otherwise.
    ///
    /// Read it directly when a view needs to match the glow around it — a caption tinted to the same hue,
    /// say. To *change* it, use ``SwiftUI/View/auroraStyle(_:)``.
    public var auroraStyle: AuroraStyle {
        get { self[AuroraStyleKey.self] }
        set { self[AuroraStyleKey.self] = newValue }
    }
}

extension View {
    /// Sets the look of every glow in this subtree.
    ///
    /// This is what makes the effect attachable to an arbitrary component. A component says *where* the
    /// glow goes and nothing about how the app looks:
    ///
    /// ```swift
    /// struct SummariseButton: View {
    ///     var body: some View {
    ///         Text("Summarise")
    ///             .padding(.horizontal, 20)
    ///             .background(.fill, in: .capsule)
    ///             .aurora(.compact, in: .capsule)
    ///     }
    /// }
    /// ```
    ///
    /// The app answers the colour question once, and every component below picks it up:
    ///
    /// ```swift
    /// RootView()
    ///     .auroraStyle(AuroraStyle(colorVariant: .tinted(.brand), strength: 0.8))
    /// ```
    ///
    /// Replaces the inherited style outright. To change one part of it, use the argument-wise overload.
    public func auroraStyle(_ style: AuroraStyle) -> some View {
        environment(\.auroraStyle, style)
    }

    /// Changes part of the inherited look, leaving the rest alone.
    ///
    /// Composes down the hierarchy, so a screen can dim every glow inside it without knowing or restating
    /// which palette an ancestor chose:
    ///
    /// ```swift
    /// SettingsList()
    ///     .auroraStyle(strength: 0.5)
    /// ```
    ///
    /// Every argument defaults to `nil`, which means "inherit".
    public func auroraStyle(
        colorVariant: AuroraColorVariant? = nil,
        theme: AuroraTheme? = nil,
        strength: Double? = nil,
        duration: Double? = nil,
        staticColors: Bool? = nil,
        hueRange: Double? = nil
    ) -> some View {
        transformEnvironment(\.auroraStyle) { style in
            if let colorVariant { style.colorVariant = colorVariant }
            if let theme { style.theme = theme }
            if let strength { style.strength = strength }
            if let duration { style.duration = duration }
            if let staticColors { style.staticColors = staticColors }
            if let hueRange { style.hueRange = hueRange }
        }
    }
}

/// What one call site asked to change about the inherited style.
///
/// `nil` means inherit. Kept as a value rather than merged eagerly because the merge can only happen
/// inside a `View`, where the environment is readable — see ``Aurora``.
struct AuroraStyleOverrides: Hashable, Sendable {
    var colorVariant: AuroraColorVariant?
    var theme: AuroraTheme?
    var strength: Double?
    var duration: Double?
    var staticColors: Bool?
    var hueRange: Double?

    func applied(to style: AuroraStyle) -> AuroraStyle {
        var merged = style
        if let colorVariant { merged.colorVariant = colorVariant }
        if let theme { merged.theme = theme }
        if let strength { merged.strength = strength }
        if let duration { merged.duration = duration }
        if let staticColors { merged.staticColors = staticColors }
        if let hueRange { merged.hueRange = hueRange }
        return merged
    }
}
