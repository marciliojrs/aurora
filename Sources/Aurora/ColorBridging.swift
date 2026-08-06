import AuroraCore
import SwiftUI

extension Color {
    /// Bridges a ``AuroraColor`` into SwiftUI.
    ///
    /// Built with the `.sRGB` space rather than `.displayP3` because the palette's
    /// components *are* sRGB — handing sRGB numbers to a wider space would shift every
    /// color. `Color(.sRGB, …)` accepts components outside `0...1` and treats them as
    /// extended sRGB, which matters here: several presets drive brightness above 1, and
    /// clamping that early visibly dulls the bloom.
    init(aurora color: AuroraColor) {
        self.init(
            .sRGB,
            red: color.red,
            green: color.green,
            blue: color.blue,
            opacity: color.alpha
        )
    }
}

extension Gradient {
    /// Bridges a glow gradient's stops into SwiftUI.
    init(auroraStops stops: [AuroraGradientStop]) {
        self.init(stops: stops.map { Gradient.Stop(color: Color(aurora: $0.color), location: $0.location) })
    }
}
