#if canImport(UIKit)

import AuroraCore
import UIKit

/// Platform lookups the UIKit surface needs.
///
/// The whole target is wrapped in `canImport(UIKit)` so the package still builds for
/// macOS, where only the SwiftUI surface applies.
enum Appearance {
    /// Whether the interface is currently in a dark appearance.
    ///
    /// Read from a specific trait collection rather than `UITraitCollection.current`,
    /// because a view can sit inside a container that sets
    /// `overrideUserInterfaceStyle`. The glow has to match the surface it is drawn on,
    /// not the app-wide appearance.
    static func isDark(_ traits: UITraitCollection) -> Bool {
        traits.userInterfaceStyle == .dark
    }
}

#endif
