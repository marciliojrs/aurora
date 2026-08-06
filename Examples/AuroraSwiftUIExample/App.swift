import SwiftUI

@main
struct AuroraSwiftUIExampleApp: App {
    /// Owned here rather than in ``PresetList`` so the settings outlive any one screen: the pushed
    /// detail views read them out of the environment and every screen sees the same choices.
    @State private var settings = DemoSettings()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PresetList()
            }
            .environment(settings)
        }
    }
}
