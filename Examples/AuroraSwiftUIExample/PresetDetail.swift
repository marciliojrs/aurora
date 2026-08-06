import Aurora
import SwiftUI

/// One preset, on a host chosen to suit it, over the knobs that change how it reads.
///
/// The subject sits in a `Form` row rather than above the form, so the whole screen scrolls as one and
/// the controls stay a thumb's reach from the thing they change.
struct PresetDetail: View {
    let preset: Preset

    @Environment(DemoSettings.self) private var settings
    @State private var isActive = true
    @State private var query = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        // `@Bindable` is what turns an `@Observable` read out of the environment back into something
        // `$`-bindable. Without it the pickers below have nothing to write to.
        @Bindable var settings = settings

        Form {
            Section {
                subject
                    .frame(maxWidth: .infinity)
                    // The row is flattened to the page color so each host's own surface still reads as
                    // raised. A `Form` row is *already* the secondary grouped color, so leaving it
                    // alone would put the card on an identical background and the glow would have no
                    // edge to sit against.
                    .listRowBackground(Color(uiColor: .systemGroupedBackground))
                    .listRowInsets(EdgeInsets(top: 44, leading: 28, bottom: 44, trailing: 28))
            } footer: {
                Text(preset.blurb)
            }

            Section {
                Picker("Palette", selection: $settings.paletteKind) {
                    ForEach(DemoSettings.PaletteKind.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                // Each case needs different extra input, so only the relevant picker is shown.
                switch settings.paletteKind {
                case .glow:
                    EmptyView()
                case .tinted:
                    Picker("Tint", selection: $settings.tint) {
                        ForEach(DemoSettings.Tint.allCases) { tint in
                            Text(tint.label).tag(tint)
                        }
                    }
                case .multiColor:
                    Picker("Colors", selection: $settings.combination) {
                        ForEach(DemoSettings.Combination.allCases) { combination in
                            Text(combination.label).tag(combination)
                        }
                    }
                }
            } header: {
                Text("Color")
            } footer: {
                Text(settings.paletteKind.note)
            }

            Section {
                LabeledContent("Strength") {
                    Text(settings.strength.formatted(.number.precision(.fractionLength(2))))
                        .monospacedDigit()
                }
                Slider(value: $settings.strength, in: 0...1)
            } header: {
                Text("Intensity")
            }

            Section {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(DemoSettings.Appearance.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            } footer: {
                Text(appearanceNote)
            }

            activationSection
        }
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.inline)
        // Every glow below inherits palette, appearance and intensity from here. The subject views name
        // a preset and an outline and nothing else — which is what makes them reusable components rather
        // than demo-specific ones.
        .auroraStyle(settings.style)
        .preferredColorScheme(settings.appearance.colorScheme)
    }

    private var appearanceNote: String {
        switch settings.appearance {
        case .system: "theme: .auto — change the device appearance and the glow re-tunes live."
        case .dark: "theme: .dark — pinned, ignoring the device."
        case .light: "theme: .light — pinned, ignoring the device."
        }
    }

    // MARK: Activation

    /// `underline` is driven by focus instead of a toggle, because that is how you would ship it: the
    /// field glows while the caret is in it. The other presets get the toggle so the activation fade
    /// stays visible on demand.
    @ViewBuilder private var activationSection: some View {
        if preset.size == .underline {
            Section {
                LabeledContent("Active", value: isFieldFocused ? "Yes" : "No")
            } header: {
                Text("Activation")
            } footer: {
                Text("Bound to `@FocusState`. Tap the field above to fade the glow in.")
            }
        } else {
            Section {
                Toggle("Active", isOn: $isActive)
            } header: {
                Text("Activation")
            } footer: {
                Text("Toggling fades rather than cutting, in both directions.")
            }
        }
    }

    // MARK: Subjects

    @ViewBuilder private var subject: some View {
        switch preset.size {
        case .regular: draftCard
        case .compact: actionButton
        case .underline: questionField
        case .pulseOutward: listeningTile
        case .pulseInward: recordingCard
        }
    }

    /// `showsBorder` draws the card's outline and lets the sweep light it as it goes.
    ///
    /// A hand-rolled `strokeBorder` could match the colour — white on dark, black on light is just
    /// `Color.primary` — but not the motion: the demo has no access to the sweep's phase, so its outline
    /// would sit dead while the glow travelled over it. Asking the library for it is the only way the two
    /// stay in step.
    private var draftCard: some View {
        Aurora(.regular, in: .rounded(cornerRadius: 20), showsBorder: true, isActive: isActive) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Draft ready").font(.headline)
                Text("Three suggestions pulled from your notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var actionButton: some View {
        Button {} label: {
            Text("Summarise")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 20)
                .frame(height: 40)
        }
        .buttonStyle(.plain)
        .background(surface)
        .clipShape(Capsule())
        // No radius: `.capsule` measures the button. It stays right when Dynamic Type changes the height,
        // which a hardcoded 20 would not.
        .aurora(.compact, in: .capsule, isActive: isActive)
    }

    private var questionField: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(.secondary)
            TextField("Ask a question", text: $query)
                .focused($isFieldFocused)
                .submitLabel(.go)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .aurora(.underline, in: .rounded(cornerRadius: 14), isActive: isFieldFocused)
    }

    private var listeningTile: some View {
        // This preset draws *behind* its host, so the host has to be opaque or the halo shows through
        // the middle. A semantic color stays opaque in both schemes, which an `.opacity` one would not.
        VStack(spacing: 10) {
            Image(systemName: "waveform").font(.system(size: 34, weight: .light))
            Text("Listening").font(.subheadline.weight(.medium))
        }
        .frame(width: 150, height: 150)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .aurora(.pulseOutward, in: .rounded(cornerRadius: 28), isActive: isActive)
    }

    private var recordingCard: some View {
        Aurora(.pulseInward, in: .rounded(cornerRadius: 20), isActive: isActive) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recording").font(.headline)
                    Text("Tap to stop").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("04:12").font(.title3.monospacedDigit())
            }
            .padding(20)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    /// Semantic, so every host re-tunes with the scheme. A host hardcoded to `Color(white: 0.08)` would
    /// stay near-black in a light scheme, and the light palette — which deepens with black rather than
    /// brightening with white — would have nothing to read against.
    private var surface: Color { Color(uiColor: .secondarySystemGroupedBackground) }
}

#Preview("regular") {
    NavigationStack { PresetDetail(preset: Preset.all[0]) }
        .environment(DemoSettings())
}

#Preview("underline") {
    NavigationStack { PresetDetail(preset: Preset.all[2]) }
        .environment(DemoSettings())
}
