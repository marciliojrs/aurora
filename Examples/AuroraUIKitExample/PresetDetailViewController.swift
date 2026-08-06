import Aurora
import UIKit

/// One preset, on a host chosen to suit it, over the knobs that change how it reads.
///
/// ### Two ways of attaching a glow
///
/// - Most subjects build an `AuroraView(contentView:)` directly. Clearer when assembling a hierarchy
///   from scratch.
/// - `underline` builds a bare `UITextField`, constrains it, then calls `wrapInAurora(_:)`, which
///   re-parents it in place. That is the escape hatch for a view whose constraints already exist and
///   would be painful to rebuild.
///
/// Every surface is a semantic `UIColor`, which matters more than it looks: the glow is tuned against
/// the surface behind it, so a card hardcoded to near-black would stay near-black in a light scheme,
/// and the light palette — which deepens with black rather than brightening with white — would have
/// nothing to read against.
final class PresetDetailViewController: UIViewController {
    private let preset: Preset
    private let settings: DemoSettings

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let paletteControl = UISegmentedControl(
        items: DemoSettings.PaletteKind.allCases.map(\.label)
    )
    private let paletteNote = UILabel()
    private let tintControl = UISegmentedControl(
        items: DemoSettings.Tint.allCases.map(\.label)
    )
    private let tintRow = UIStackView()
    private let combinationControl = UISegmentedControl(
        items: DemoSettings.Combination.allCases.map(\.label)
    )
    private let combinationRow = UIStackView()
    private let appearanceControl = UISegmentedControl(
        items: DemoSettings.Appearance.allCases.map(\.label)
    )
    private let appearanceNote = UILabel()
    private let strengthSlider = UISlider()
    private let strengthValue = UILabel()
    private let activeSwitch = UISwitch()
    private let activationNote = UILabel()

    /// The one glow on this screen. Optional because `wrapInAurora(_:)` can decline — it needs a
    /// superview to re-parent into.
    private var glow: AuroraView?

    init(preset: Preset, settings: DemoSettings) {
        self.preset = preset
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unused — this screen is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = preset.name
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        buildLayout()
        stack.addArrangedSubview(subjectRow())
        stack.addArrangedSubview(note(preset.blurb))
        stack.addArrangedSubview(controlPanel())
        syncControlsFromSettings()
        applySettings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The window is only reachable once the view is in a hierarchy.
        view.window?.overrideUserInterfaceStyle = settings.appearance.interfaceStyle
    }

    // MARK: Layout

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8, leading: 20, bottom: 32, trailing: 20
        )
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    /// Wraps the subject in slack on all four sides. `pulseOutward` paints outside its bounds, so
    /// without the inset the next row packs tight against it and the halo gets clipped.
    private func subjectRow() -> UIView {
        let subject = buildSubject()
        let row = UIView()
        row.addSubview(subject)

        let inset = 36.0
        var constraints = [
            subject.topAnchor.constraint(equalTo: row.topAnchor, constant: inset),
            subject.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -inset),
            subject.centerXAnchor.constraint(equalTo: row.centerXAnchor),
        ]
        // A capsule button and a fixed tile keep their intrinsic width; the cards and the field fill.
        switch preset.size {
        case .compact, .pulseOutward:
            constraints.append(
                subject.widthAnchor.constraint(
                    lessThanOrEqualTo: row.widthAnchor, constant: -inset * 2
                )
            )
        case .regular, .underline, .pulseInward:
            constraints.append(
                subject.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: inset)
            )
        }
        NSLayoutConstraint.activate(constraints)
        return row
    }

    // MARK: Subjects

    private func buildSubject() -> UIView {
        switch preset.size {
        case .regular:
            attach(card(title: "Draft ready", subtitle: "Three suggestions pulled from your notes"))
        case .compact:
            attach(pillButton(title: "Summarise"))
        case .underline:
            questionField()
        case .pulseOutward:
            attach(listeningTile())
        case .pulseInward:
            attach(card(title: "Recording", subtitle: "Tap to stop", trailing: "04:12"))
        }
    }

    /// Wraps a subject, taking the preset and outline from ``Preset`` and the look from ``DemoSettings``.
    private func attach(_ content: UIView) -> UIView {
        let view = AuroraView(
            contentView: content,
            configuration: settings.style.configuration(
                preset.size,
                in: preset.shape,
                showsBorder: preset.showsBorder
            )
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        glow = view
        return view
    }

    /// A real editable field, glowing while it holds the caret. That is how you would ship this preset,
    /// so it is what the demo shows — see `textFieldDidBeginEditing(_:)`.
    private func questionField() -> UIView {
        let field = UITextField()
        field.placeholder = "Ask a question"
        field.delegate = self
        field.returnKeyType = .go
        field.backgroundColor = .secondarySystemGroupedBackground
        field.layer.cornerRadius = 14
        field.layer.cornerCurve = .continuous
        field.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = .secondaryLabel
        icon.frame = CGRect(x: 0, y: 0, width: 42, height: 24)
        icon.contentMode = .center
        field.leftView = icon
        field.leftViewMode = .always

        let container = UIView()
        container.addSubview(field)
        NSLayoutConstraint.activate([
            field.heightAnchor.constraint(equalToConstant: 48),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        // Wrapped after its constraints exist, which is the whole point of the in-place helper.
        glow = field.addAurora(
            preset.size,
            in: preset.shape,
            showsBorder: preset.showsBorder,
            style: settings.style
        )
        return container
    }

    /// `pulseOutward` draws its glow *behind* the host, so the host has to be opaque or the halo shows
    /// through the middle.
    private func listeningTile() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "waveform"))
        icon.tintColor = .label
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 34, weight: .light
        )

        let caption = UILabel()
        caption.text = "Listening"
        caption.font = .preferredFont(forTextStyle: .subheadline)
        caption.textAlignment = .center

        let content = UIStackView(arrangedSubviews: [icon, caption])
        content.axis = .vertical
        content.spacing = 10
        content.alignment = .center
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 34, leading: 20, bottom: 34, trailing: 20
        )
        content.backgroundColor = .secondarySystemGroupedBackground
        content.layer.cornerRadius = 28
        content.layer.cornerCurve = .continuous
        content.clipsToBounds = true
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.widthAnchor.constraint(equalToConstant: 150),
            content.heightAnchor.constraint(equalToConstant: 150),
        ])
        return content
    }

    private func card(title: String, subtitle: String, trailing: String? = nil) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel

        let text = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        text.axis = .vertical
        text.spacing = 6

        let row = UIStackView(arrangedSubviews: [text])
        if let trailing {
            let value = UILabel()
            value.text = trailing
            value.font = .monospacedDigitSystemFont(
                ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
                weight: .regular
            )
            row.addArrangedSubview(UIView())
            row.addArrangedSubview(value)
        }
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20, leading: 20, bottom: 20, trailing: 20
        )
        row.backgroundColor = .secondarySystemGroupedBackground
        row.layer.cornerRadius = 20
        row.layer.cornerCurve = .continuous
        row.clipsToBounds = true
        return row
    }

    private func pillButton(title: String) -> UIView {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        let button = UIButton(configuration: config)
        button.backgroundColor = .secondarySystemGroupedBackground
        button.layer.cornerRadius = 20
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    // MARK: Controls

    private func controlPanel() -> UIView {
        paletteControl.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        tintControl.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        combinationControl.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        appearanceControl.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)

        strengthSlider.minimumValue = 0
        strengthSlider.maximumValue = 1
        strengthSlider.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)

        activeSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)

        for label in [appearanceNote, activationNote, paletteNote] {
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
        }
        strengthValue.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        strengthValue.textColor = .secondaryLabel

        tintRow.axis = .vertical
        tintRow.spacing = 6
        tintRow.addArrangedSubview(caption("Tint"))
        tintRow.addArrangedSubview(tintControl)

        combinationRow.axis = .vertical
        combinationRow.spacing = 6
        combinationRow.addArrangedSubview(caption("Colors"))
        combinationRow.addArrangedSubview(combinationControl)

        let panel = UIStackView(arrangedSubviews: [
            group(caption("Palette"), paletteControl, paletteNote),
            tintRow,
            combinationRow,
            group(caption("Intensity"), row(strengthSlider, strengthValue)),
            group(caption("Appearance"), appearanceControl, appearanceNote),
            group(row(caption("Active"), UIView(), activeSwitch), activationNote),
        ])
        panel.axis = .vertical
        panel.spacing = 20
        panel.isLayoutMarginsRelativeArrangement = true
        panel.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20, leading: 20, bottom: 20, trailing: 20
        )
        panel.backgroundColor = .secondarySystemGroupedBackground
        panel.layer.cornerRadius = 16
        panel.layer.cornerCurve = .continuous
        panel.clipsToBounds = true
        return panel
    }

    private func group(_ views: UIView...) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func row(_ views: UIView...) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }

    private func note(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    // MARK: Settings

    /// The controls start from the shared settings rather than from their own defaults, so arriving here
    /// with a palette already chosen shows that palette selected.
    private func syncControlsFromSettings() {
        paletteControl.selectedSegmentIndex = settings.paletteKind.rawValue
        tintControl.selectedSegmentIndex = settings.tint.rawValue
        combinationControl.selectedSegmentIndex = settings.combination.rawValue
        appearanceControl.selectedSegmentIndex = settings.appearance.rawValue
        strengthSlider.value = Float(settings.strength)
        activeSwitch.isOn = true
    }

    @objc private func settingsChanged() {
        settings.paletteKind =
            DemoSettings.PaletteKind(rawValue: paletteControl.selectedSegmentIndex) ?? .glow
        settings.tint = DemoSettings.Tint(rawValue: tintControl.selectedSegmentIndex) ?? .none
        settings.combination =
            DemoSettings.Combination(rawValue: combinationControl.selectedSegmentIndex) ?? .cool
        settings.appearance =
            DemoSettings.Appearance(rawValue: appearanceControl.selectedSegmentIndex) ?? .system
        settings.strength = Double(strengthSlider.value)
        applySettings()
    }

    private func applySettings() {
        // Overridden on the window rather than this view, so the navigation bar and the list behind it
        // follow too. `AuroraView` re-resolves `.auto` against its own traits either way.
        view.window?.overrideUserInterfaceStyle = settings.appearance.interfaceStyle
        appearanceNote.text = settings.appearance.note
        // Each case needs different extra input, so only the relevant row stays on screen.
        paletteNote.text = settings.paletteKind.note
        tintRow.isHidden = settings.paletteKind != .tinted
        combinationRow.isHidden = settings.paletteKind != .multiColor
        strengthValue.text = settings.strength.formatted(.number.precision(.fractionLength(2)))

        // `underline` follows the caret instead of the switch, so the switch would be lying.
        let focusDriven = preset.size == .underline
        activeSwitch.isEnabled = !focusDriven
        activationNote.text =
            focusDriven
            ? "Driven by editing state. Tap the field above to fade the glow in."
            : "Toggling fades rather than cutting, in both directions."

        glow?.configuration = settings.style.configuration(
            preset.size,
            in: preset.shape,
            showsBorder: preset.showsBorder
        )
        if !focusDriven {
            glow?.isActive = activeSwitch.isOn
        }
    }
}

extension PresetDetailViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        glow?.isActive = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        glow?.isActive = false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
