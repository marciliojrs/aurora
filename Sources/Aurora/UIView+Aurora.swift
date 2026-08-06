#if canImport(UIKit)

import AuroraCore
import UIKit

extension UIView {
    /// Adds an animated aurora around this view, in place.
    ///
    /// The UIKit counterpart to `View.aurora(_:in:)`, and the one-liner worth reaching for:
    ///
    /// ```swift
    /// button.addAurora(.compact, in: .capsule)
    /// field.addAurora(.underline, in: .rounded(cornerRadius: 14))
    /// ```
    ///
    /// UIKit has no environment to inherit a look from, so pass an ``AuroraStyle`` when the app has one.
    /// Holding a single style somewhere and handing it to each call is the UIKit equivalent of setting
    /// `auroraStyle` once near the root.
    ///
    /// - Parameters:
    ///   - size: Which preset to draw. See ``AuroraSize``.
    ///   - shape: The outline this view is clipped to. Name the same shape you gave
    ///     `layer.cornerRadius`; ``AuroraShape/capsule`` needs no arithmetic and stays right as the view
    ///     resizes.
    ///   - showsBorder: Draws this view's outline under the glow and lets the effect light it. Saves
    ///     setting `layer.borderColor` and re-resolving it on every trait change.
    ///   - style: Palette, appearance, intensity and tempo. Defaults to ``AuroraStyle/standard``.
    ///   - isActive: Fades the glow in and out.
    /// - Returns: The wrapper, now in this view's former place, or `nil` if the view has no superview to
    ///   be wrapped inside.
    @discardableResult
    @MainActor
    public func addAurora(
        _ size: AuroraSize = .regular,
        in shape: AuroraShape = .preset,
        showsBorder: Bool = false,
        style: AuroraStyle = .standard,
        isActive: Bool = true
    ) -> AuroraView? {
        wrapInAurora(
            style.configuration(size, in: shape, showsBorder: showsBorder),
            isActive: isActive
        )
    }

    /// Wraps this view in a ``AuroraView`` in place, keeping its position in the hierarchy
    /// and the constraints that referenced it.
    ///
    /// The value-based form. Prefer ``addAurora(_:in:style:isActive:)`` unless the configuration is
    /// computed or held elsewhere.
    ///
    /// ```swift
    /// let glow = card.wrapInAurora(
    ///     AuroraConfiguration(size: .regular, shape: .rounded(cornerRadius: 20))
    /// )
    /// glow?.isActive = viewModel.isProcessing
    /// ```
    ///
    /// Use either of these when a view is already installed and re-parenting it by hand would mean
    /// rebuilding its constraints. When building a hierarchy from scratch, prefer
    /// `AuroraView(contentView:)` — it reads better than a mutation.
    ///
    /// - Returns: The wrapper, now in this view's former place, or `nil` if the view has no
    ///   superview to be wrapped inside.
    @discardableResult
    @MainActor
    public func wrapInAurora(
        _ configuration: AuroraConfiguration = AuroraConfiguration(),
        isActive: Bool = true
    ) -> AuroraView? {
        guard let superview else { return nil }

        let index = superview.subviews.firstIndex(of: self)
        // Constraints pinning this view to its siblings die with the re-parenting, so they are
        // captured first and re-pointed at the wrapper below. Without this the view would come
        // back unconstrained and collapse to zero size.
        let externalConstraints = superview.constraints.filter { constraint in
            constraint.firstItem === self || constraint.secondItem === self
        }
        NSLayoutConstraint.deactivate(externalConstraints)
        removeFromSuperview()

        let wrapper = AuroraView(
            contentView: self,
            configuration: configuration,
            isActive: isActive
        )
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        if let index {
            superview.insertSubview(wrapper, at: index)
        } else {
            superview.addSubview(wrapper)
        }

        NSLayoutConstraint.activate(
            externalConstraints.compactMap { $0.retargeted(from: self, to: wrapper) }
        )
        return wrapper
    }
}

extension NSLayoutConstraint {
    /// Returns a copy of this constraint with `old` swapped for `new` on either end.
    ///
    /// A constraint's items are read-only, so re-parenting a view means rebuilding every
    /// constraint that mentioned it rather than reassigning them. Returns `nil` if the first item
    /// has gone away, since a constraint without one cannot be recreated.
    fileprivate func retargeted(from old: AnyObject, to new: AnyObject) -> NSLayoutConstraint? {
        guard let currentFirst = firstItem else { return nil }
        let first: AnyObject = currentFirst === old ? new : currentFirst
        let second: AnyObject? = secondItem === old ? new : secondItem

        let copy = NSLayoutConstraint(
            item: first,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: second,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant
        )
        copy.priority = priority
        copy.identifier = identifier
        return copy
    }
}

#endif
