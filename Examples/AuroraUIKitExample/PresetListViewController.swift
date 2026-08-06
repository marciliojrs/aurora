import Aurora
import UIKit

/// The demo's root screen: the five presets as an inset-grouped table, each pushing its own screen.
///
/// Demo code, deliberately not part of the library. For previews of the component itself, see
/// `Sources/AuroraUIKit/Previews.swift`.
///
/// One preset per screen rather than all five on one scroll. Each preset gets a host that suits it —
/// `underline` wraps a real `UITextField` and glows while it holds the caret — and only one glow
/// animates at a time, which is how you would ship it.
final class PresetListViewController: UITableViewController {
    private let settings = DemoSettings()

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unused — this screen is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Aurora"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
    }

    /// Reapplied on every appearance because the pushed screen owns the appearance override while it is
    /// on top; coming back, this screen has to reassert it or the list snaps to the device setting.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.window?.overrideUserInterfaceStyle = settings.appearance.interfaceStyle
        tableView.reloadData()
    }

    // MARK: Table

    private static let cellID = "preset"

    private static let notes = [
        "Reduce Motion holds the effect at a settled frame rather than hiding it.",
        "Aurora never intercepts touches. It draws behind or above, never in front.",
    ]

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? Preset.all.count : Self.notes.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
        var content = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
            let preset = Preset.all[indexPath.row]
            content.text = preset.name
            content.textProperties.font = .monospacedSystemFont(
                ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
                weight: .regular
            )
            content.secondaryText = preset.blurb
            content.image = UIImage(systemName: preset.symbol)
            content.imageProperties.tintColor = view.tintColor
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else {
            content.text = Self.notes[indexPath.row]
            content.textProperties.font = .preferredFont(forTextStyle: .footnote)
            content.textProperties.color = .secondaryLabel
            content.textProperties.numberOfLines = 0
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        cell.contentConfiguration = content
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        section == 0 ? "Presets" : "Worth knowing"
    }

    override func tableView(
        _ tableView: UITableView,
        titleForFooterInSection section: Int
    ) -> String? {
        guard section == 0 else { return nil }
        return """
            Palette, tint, intensity and appearance are shared across all five, so a setting picked on \
            one screen survives going back.
            """
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }
        navigationController?.pushViewController(
            PresetDetailViewController(preset: Preset.all[indexPath.row], settings: settings),
            animated: true
        )
    }
}
