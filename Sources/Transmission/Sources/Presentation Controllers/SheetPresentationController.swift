//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

#if targetEnvironment(macCatalyst)
@available(iOS 15.0, *)
typealias SheetPresentationController = MacSheetPresentationController

@available(iOS 15.0, *)
final class MacSheetTransition: SlidePresentationControllerTransition {

}

@available(iOS 15.0, *)
final class MacSheetPresentationController: SlidePresentationController {

    var preferredCornerRadius: CGFloat? {
        didSet {
            presentedViewController.viewIfLoaded?.layer.cornerRadius = preferredCornerRadius ?? SlidePresentationControllerTransition.displayCornerRadius
        }
    }

    var detent: PresentationLinkTransition.SheetTransitionOptions.Detent = .large {
        didSet {
            dimmingView.isHidden = largestUndimmedDetentIdentifier == detent.identifier
        }
    }

    var selected: Binding<PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?>?
    var largestUndimmedDetentIdentifier: PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?

    private var prevPresentationController: MacSheetPresentationController? {
        presentingViewController.presentationController as? MacSheetPresentationController
    }

    private var depth = 0 {
        didSet {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
            dimmingView.alpha = depth > 0 ? 0 : 1
        }
    }

    private func push() {
        prevPresentationController?.depth += 1
        prevPresentationController?.prevPresentationController?.depth += 1
    }

    private func pop() {
        prevPresentationController?.depth -= 1
        prevPresentationController?.prevPresentationController?.depth -= 1
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let frame = super.frameOfPresentedViewInContainerView.inset(by: containerView?.safeAreaInsets ?? .zero)
        let isPinnedToEdges = frame.size.height > (1.5 * frame.size.width)
        let targetRect: CGRect = {
            if isPinnedToEdges {
                let height = (frame.size.height * 0.95).rounded(.up)
                return CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y + (frame.size.height - height),
                    width: frame.size.width,
                    height: height
                )
            } else {
                let width = (frame.size.width * 0.85).rounded(.up)
                let height = (frame.size.height * 0.85).rounded(.up)
                return CGRect(
                    x: frame.origin.x + (frame.size.width - width) / 2,
                    y: frame.origin.y + (frame.size.height - height) / 2,
                    width: width,
                    height: height
                )
            }
        }()
        switch detent.identifier {
        case .large:
            return targetRect

        case .medium:
            let height = (frame.size.height / 2).rounded(.up)
            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - height : targetRect.origin.y + (targetRect.size.height - height) / 2,
                width: targetRect.width,
                height: height
            )

        case .ideal:
            let fittingSize = CGSize(
                width: targetRect.width,
                height: .infinity
            )
            let targetHeight = min(
                targetRect.height,
                presentedViewController.view.systemLayoutSizeFitting(
                    fittingSize,
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .defaultLow
                ).height.rounded(.up)
            )

            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - targetHeight : targetRect.origin.y + (targetRect.size.height - targetHeight) / 2,
                width: targetRect.width,
                height: targetHeight
            )

        default:
            let height: CGFloat
            if let constant = detent.height {
                height = min(constant, targetRect.size.height)
            } else if let resolution = detent.resolution {
                height = resolution(
                    .init(
                        containerTraitCollection: traitCollection,
                        maximumDetentValue: targetRect.size.height,
                        idealDetentValue: { [weak presentedViewController] in
                            guard let presentedViewController else { return 0 }
                            let fittingSize = CGSize(
                                width: targetRect.width,
                                height: .infinity
                            )
                            let targetHeight = min(
                                targetRect.height,
                                presentedViewController.view.systemLayoutSizeFitting(
                                    fittingSize,
                                    withHorizontalFittingPriority: .required,
                                    verticalFittingPriority: .defaultLow
                                ).height.rounded(.up)
                            )
                            return targetHeight
                        }
                    )
                ) ?? targetRect.size.height
            } else {
                return targetRect
            }
            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - height : targetRect.origin.y + (targetRect.size.height - height) / 2,
                width: targetRect.width,
                height: height
            )
        }
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        selected?.wrappedValue = detent.identifier

        presentedViewController.view.layer.cornerCurve = .continuous
        presentedViewController.view.layer.cornerRadius = preferredCornerRadius ?? SlidePresentationControllerTransition.displayCornerRadius

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.push()
            }, completion: { [unowned self] ctx in
                if ctx.isCancelled {
                    self.pop()
                }
            })
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if !completed {
            selected?.wrappedValue = nil
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.pop()
            }, completion: { [unowned self] ctx in
                if ctx.isCancelled {
                    self.push()
                }
            })
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            selected?.wrappedValue = nil
        }
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        if let presentedView = presentedView {
            let isPinnedToEdges = presentedView.frame.size.height > (1.5 * presentedView.frame.size.width)
            presentedView.layer.maskedCorners = isPinnedToEdges
                ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                : [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }

    override func layoutPresentedView(frame: CGRect) {
        presentedView?.transform = .identity
        super.layoutPresentedView(frame: frame)
        if depth > 0 {
            let scale: CGFloat = pow(0.92, CGFloat(depth))
            presentedView?.transform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: 0, y: (frame.height * -0.08))
        } else {
            presentedView?.transform = .identity
        }
    }
}
#else
@available(iOS 15.0, *)
open class SheetPresentationController: UISheetPresentationController {

    public var preferredBackgroundColor: UIColor? {
        didSet {
            updateBackgroundColor()
        }
    }

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        updateBackgroundColor()
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        updateBackgroundColor()
    }

    private func updateBackgroundColor() {
        presentedView?.backgroundColor = preferredBackgroundColor
        if let preferredBackgroundColor {
            containerView?.subviews.last?.layer.shadowColor = preferredBackgroundColor.cgColor
        }
    }
}
#endif

@available(iOS 15.0, *)
extension PresentationLinkTransition.SheetTransitionOptions {
    static func update(
        presentationController: SheetPresentationController,
        animated isAnimated: Bool,
        from oldValue: Self,
        to newValue: Self
    ) {
        let detents = newValue.detents
        #if targetEnvironment(macCatalyst)
        let cornerRadius = newValue.preferredCornerRadius
        let hasChanges: Bool = {
            if presentationController.presentedViewController.view.layer.cornerRadius != cornerRadius {
                return true
            } else if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = newValue.selected,
                presentationController.detent.identifier != selected.wrappedValue
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            return false
        }()
        #else
        presentationController.preferredBackgroundColor = newValue.options.preferredPresentationBackgroundUIColor
        let selectedDetentIdentifier = newValue.selected?.wrappedValue?.toUIKit()
        let hasChanges: Bool = {
            if oldValue.preferredCornerRadius != newValue.preferredCornerRadius {
                return true
            } else if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = selectedDetentIdentifier,
                      presentationController.selectedDetentIdentifier != selected
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            return false
        }()
        #endif
        if hasChanges {
            func applyConfiguration() {
                #if targetEnvironment(macCatalyst)
                presentationController.preferredCornerRadius = cornerRadius
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier
                presentationController.selected = newValue.selected
                let selected = newValue.selected?.wrappedValue
                presentationController.detent = detents.first(where: { $0.identifier == selected }) ?? detents.first ?? .large
                #else
                presentationController.detents = detents.map { $0.toUIKit(in: presentationController) }
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier?.toUIKit()
                if let selected = newValue.selected {
                    presentationController.selectedDetentIdentifier = selected.wrappedValue?.toUIKit()
                }
                presentationController.preferredCornerRadius = newValue.preferredCornerRadius
                #endif
            }
            if isAnimated {
                withCATransaction {
                    #if targetEnvironment(macCatalyst)
                    UIView.animate(withDuration: 0.35) {
                        applyConfiguration()
                    }
                    #else
                    presentationController.animateChanges {
                        applyConfiguration()
                    }
                    #endif
                }
            } else {
                applyConfiguration()
            }
        }
    }
}

#endif
