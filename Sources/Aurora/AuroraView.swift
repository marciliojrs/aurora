#if canImport(UIKit)

import Aurora
import AuroraCore
import SwiftUI
import UIKit

/// A `UIView` that draws an animated aurora around a content view.
///
/// ```swift
/// let card = CardView()
/// let glow = AuroraView(
///     contentView: card,
///     configuration: AuroraConfiguration(size: .pulseOutward, theme: .auto, shape: .rounded(cornerRadius: 20))
/// )
/// view.addSubview(glow)
/// ```
///
/// Add it to a hierarchy like any other view. It sizes itself to `contentView` and stays out of
/// the way of touches.
///
/// ### How this is rendered
///
/// The glow's pixels come from the same renderer the SwiftUI ``Aurora`` uses, hosted inside
/// this view. That is a deliberate choice rather than a shortcut: the effect needs a real
/// Gaussian blur per layer, and `CALayer.filters` is unavailable to app code on iOS — so a
/// "pure UIKit" version would have to push every blurred layer through Core Image each frame,
/// which is slower *and* a second rendering path to keep in step with the first. Sharing one
/// renderer means the two surfaces cannot drift apart visually.
///
/// Nothing about that leaks into the API: the public surface is entirely UIKit, and callers need
/// not import SwiftUI.
///
/// ### `pulseOutward` and clipping
///
/// That preset paints outside the view's bounds on purpose. Any ancestor with
/// `clipsToBounds = true` will cut the halo off. The other presets stay inside their bounds and
/// are unaffected.
@MainActor
public final class AuroraView: UIView {
    /// The glow's appearance. Assigning re-renders it.
    public var configuration: AuroraConfiguration {
        didSet {
            guard configuration != oldValue else { return }
            updateDecorations()
        }
    }

    /// Whether the glow is showing. Toggling fades it in or out rather than cutting.
    public var isActive: Bool {
        didSet {
            guard isActive != oldValue else { return }
            updateDecorations()
        }
    }

    /// Called once the fade-in finishes.
    public var onActivate: (() -> Void)?
    /// Called once the fade-out finishes.
    public var onDeactivate: (() -> Void)?

    /// The view the glow decorates.
    ///
    /// Replacing it removes the previous content view and re-pins the new one, keeping the glow
    /// layers correctly ordered around it.
    public var contentView: UIView? {
        didSet {
            guard contentView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            installContentView()
        }
    }

    /// Renders the layers belonging behind the content — the outward halo.
    private let behindHost: UIHostingController<AuroraDecoration>
    /// Renders the layers belonging in front of the content — rings and hairlines.
    private let aboveHost: UIHostingController<AuroraDecoration>

    public init(
        contentView: UIView? = nil,
        configuration: AuroraConfiguration = AuroraConfiguration(),
        isActive: Bool = true
    ) {
        self.configuration = configuration
        self.isActive = isActive
        self.contentView = contentView
        self.behindHost = UIHostingController(
            rootView: AuroraDecoration(configuration: configuration, contentSize: .zero)
        )
        self.aboveHost = UIHostingController(
            rootView: AuroraDecoration(configuration: configuration, contentSize: .zero)
        )
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable, message: "AuroraView is created in code, not from a nib")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Layout

    /// Sizes itself to the content view, so the glow never changes the layout it decorates.
    public override var intrinsicContentSize: CGSize {
        contentView?.intrinsicContentSize ?? super.intrinsicContentSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        for host in [behindHost, aboveHost] {
            host.view.frame = bounds
        }
        updateDecorations()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        // Leaving the window is the UIKit signal matching SwiftUI's `onDisappear`: stop the clock
        // so an offscreen glow costs nothing.
        updateDecorations()
    }

    // MARK: Setup

    private func setUp() {
        backgroundColor = .clear
        for host in [behindHost, aboveHost] {
            host.view.backgroundColor = .clear
            // The glow is decoration: touches belong to the content view and to whatever sits
            // behind the halo.
            host.view.isUserInteractionEnabled = false
            host.view.isAccessibilityElement = false
            // Hosted content clips to its own bounds by default, which would crop the outward
            // halo before the scene's outset ever mattered.
            host.view.clipsToBounds = false
        }

        addSubview(behindHost.view)
        installContentView()
        addSubview(aboveHost.view)

        // Only the interface style matters, and only when `theme` is `.auto`. Registering for that one
        // trait is cheaper than the deprecated catch-all callback, which fired for size-class and
        // dynamic-type changes the glow does not care about.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateDecorations()
        }
        updateDecorations()
    }

    private func installContentView() {
        guard let contentView else {
            invalidateIntrinsicContentSize()
            return
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        // Above the halo host and below the ring host, which is what puts the outward glow behind
        // the card and the hairline on top of it.
        insertSubview(contentView, aboveSubview: behindHost.view)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        invalidateIntrinsicContentSize()
    }

    // MARK: Rendering

    /// Pushes the current state into both hosted decorations.
    private func updateDecorations() {
        let resolved = configurationForCurrentTraits()
        let size = bounds.size
        let isPaused = window == nil || isHidden

        behindHost.rootView = AuroraDecoration(
            configuration: resolved,
            contentSize: size,
            placement: .behindContent,
            isActive: isActive,
            isPaused: isPaused
        )
        // Callbacks go to one side only. Both decorations run the same ramp on the same clock, so
        // wiring both would report every activation twice.
        aboveHost.rootView = AuroraDecoration(
            configuration: resolved,
            contentSize: size,
            placement: .aboveContent,
            isActive: isActive,
            isPaused: isPaused,
            onActivate: { [weak self] in self?.onActivate?() },
            onDeactivate: { [weak self] in self?.onDeactivate?() }
        )
    }

    /// Collapses ``AuroraTheme/auto`` against this view's own traits.
    ///
    /// Resolved here rather than left to the hosted view's environment, because a `UIView` can
    /// sit under an ancestor that sets `overrideUserInterfaceStyle` — the glow has to match the
    /// surface it is drawn on, not the app-wide appearance.
    private func configurationForCurrentTraits() -> AuroraConfiguration {
        guard configuration.theme == .auto else { return configuration }
        var resolved = configuration
        resolved.theme = Appearance.isDark(traitCollection) ? .dark : .light
        return resolved
    }
}

#endif
