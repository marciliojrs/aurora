#if DEBUG && canImport(UIKit)

import AuroraCore
import SwiftUI
import UIKit

// Previews of the UIKit surface.
//
// In the shipping target for the same reason as the SwiftUI ones: a preview only renders when some
// scheme builds the file it sits in, and `Examples/` belongs to no package target. The interactive
// showcase is demo code and lives there instead.

/// An opaque card, since `.pulseOutward` draws its halo behind the content.
@MainActor
private func previewCard(
    title: String,
    subtitle: String,
    cornerRadius: Double = 20
) -> UIView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)

    let subtitleLabel = UILabel()
    subtitleLabel.text = subtitle
    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel

    let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    stack.axis = .vertical
    stack.spacing = 6
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 20, leading: 20, bottom: 20, trailing: 20
    )
    stack.backgroundColor = UIColor(white: 0.08, alpha: 1)
    stack.layer.cornerRadius = cornerRadius
    stack.layer.cornerCurve = .continuous
    stack.clipsToBounds = true
    return stack
}

/// Centres a view on a dark stage with room around it.
///
/// `clipsToBounds` stays off: `.pulseOutward` paints outside its bounds by design, and any clipping
/// ancestor cuts the halo off.
@MainActor
private func previewStage(_ subject: UIView, padding: Double = 48) -> UIView {
    let stage = UIView()
    stage.backgroundColor = .black
    stage.overrideUserInterfaceStyle = .dark
    stage.clipsToBounds = false

    subject.translatesAutoresizingMaskIntoConstraints = false
    stage.addSubview(subject)
    NSLayoutConstraint.activate([
        subject.centerYAnchor.constraint(equalTo: stage.centerYAnchor),
        subject.leadingAnchor.constraint(equalTo: stage.leadingAnchor, constant: padding),
        subject.trailingAnchor.constraint(equalTo: stage.trailingAnchor, constant: -padding),
    ])
    return stage
}

#Preview("regular — full border") {
    previewStage(
        AuroraView(
            contentView: previewCard(
                title: "Sync in progress",
                subtitle: "Last updated 2 minutes ago"
            ),
            configuration: AuroraConfiguration(size: .regular, shape: .rounded(cornerRadius: 20))
        )
    )
}

#Preview("pulseOutward — outward halo") {
    previewStage(
        AuroraView(
            contentView: previewCard(
                title: "Analysing",
                subtitle: "Working through 1,204 records"
            ),
            configuration: AuroraConfiguration(size: .pulseOutward, shape: .rounded(cornerRadius: 20))
        ),
        padding: 72
    )
}

/// The in-place wrapper, which is the path to use when a view is already constrained.
#Preview("wrapInAurora — in place") {
    let field = previewCard(
        title: "Search everything",
        subtitle: "Wrapped after layout",
        cornerRadius: 14
    )
    let stage = previewStage(field)
    field.wrapInAurora(AuroraConfiguration(size: .underline, shape: .rounded(cornerRadius: 14)))
    return stage
}

#endif
