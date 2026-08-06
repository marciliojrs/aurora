/// Theme mode. Adapts the aurora's colors to the background behind the element.
public enum AuroraTheme: Hashable, Sendable {
    case dark
    case light
    /// Follows the environment's color scheme.
    case auto

    /// Collapses ``auto`` using the surrounding color scheme.
    ///
    /// The renderers call this with the live environment value; the core never reads
    /// the environment itself, which is what keeps ``AuroraSceneBuilder`` pure.
    public func resolved(isDarkEnvironment: Bool) -> AuroraResolvedTheme {
        switch self {
        case .dark: .dark
        case .light: .light
        case .auto: isDarkEnvironment ? .dark : .light
        }
    }
}

/// A theme with ``AuroraTheme/auto`` already collapsed. Every preset table in
/// ``Tuning`` is keyed by this, never by ``AuroraTheme``.
public enum AuroraResolvedTheme: CaseIterable, Hashable, Sendable {
    case dark
    case light

    public var isDark: Bool { self == .dark }
}
