import Aurora
import SwiftUI

/// The demo's root screen: the five presets as a plain grouped list, each pushing its own screen.
///
/// Demo code, deliberately not part of the library. Depend on Aurora and you get the component, not a
/// showcase screen in your API surface. For previews of the component itself, see
/// `Sources/Aurora/Previews.swift`.
///
/// One preset per screen rather than all five on one scroll. That costs a tap and buys two things: each
/// preset gets a host that actually suits it — `underline` wraps a real focused text field,
/// `pulseOutward` gets the room its halo needs — and only one `TimelineView` animates at a time, which
/// is how you would ship it.
struct PresetList: View {
    @Environment(DemoSettings.self) private var settings

    var body: some View {
        List {
            Section {
                ForEach(Preset.all) { preset in
                    NavigationLink(value: preset) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name).font(.body.monospaced())
                                Text(preset.blurb)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: preset.symbol).foregroundStyle(.tint)
                        }
                    }
                }
            } header: {
                Text("Presets")
            } footer: {
                Text(
                    """
                    Palette, tint, intensity and appearance are shared across all five, so a setting \
                    picked on one screen survives going back.
                    """
                )
            }

            Section {
                Text("Reduce Motion holds the effect at a settled frame rather than hiding it.")
                Text("Aurora never intercepts touches. It draws behind or above, never in front.")
            } header: {
                Text("Worth knowing")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .navigationDestination(for: Preset.self) { PresetDetail(preset: $0) }
        .navigationTitle("Aurora")
        .preferredColorScheme(settings.appearance.colorScheme)
    }
}

#Preview {
    NavigationStack { PresetList() }
        .environment(DemoSettings())
}
