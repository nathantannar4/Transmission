//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that presents the view in a full screen sheet
@available(iOS 14.0, *)
open class SlidePresentationController: InteractivePresentationController {

    public var edge: Edge

    public override var edges: Edge.Set {
        get { Edge.Set(edge) }
        set { }
    }

    open override var wantsInteractiveDismissal: Bool {
        return false
    }

    open override var presentationStyle: UIModalPresentationStyle {
        .overFullScreen
    }

    public init(
        edge: Edge = .bottom,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        return .identity
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        presentingViewController.view.isHidden = presentedViewController.presentedViewController != nil
    }
}

/// An interactive transition built for the ``SlidePresentationController``.
///
/// ```
/// func animationController(
///     forPresented presented: UIViewController,
///     presenting: UIViewController,
///     source: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     let transition = SlidePresentationControllerTransition(
///         edge: options.edge,
///         prefersScaleEffect: options.prefersScaleEffect,
///         preferredCornerRadius: options.preferredCornerRadius,
///         presentationBackgroundColor: options.options.preferredPresentationBackgroundUIColor,
///         isPresenting: true,
///         animation: animation
///     )
///     transition.wantsInteractiveStart = false
///     return transition
/// }
///
/// func animationController(
///     forDismissed dismissed: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     guard let presentationController = dismissed.presentationController as? SlidePresentationController else {
///         return nil
///     }
///     let transition = SlidePresentationControllerTransition(
///         edge: options.edge,
///         prefersScaleEffect: options.prefersScaleEffect,
///         preferredCornerRadius: options.preferredCornerRadius,
///         presentationBackgroundColor: options.options.preferredPresentationBackgroundUIColor,
///         isPresenting: false,
///         animation: animation
///     )
///     transition.wantsInteractiveStart = options.options.isInteractive && presentationController.wantsInteractiveTransition
///     presentationController.transition(with: transition)
///     return transition
/// }
///
/// func interactionControllerForDismissal(
///     using animator: UIViewControllerAnimatedTransitioning
/// ) -> UIViewControllerInteractiveTransitioning? {
///     return animator as? SlidePresentationControllerTransition
/// }
/// ```
///
@available(iOS 14.0, *)
open class SlidePresentationControllerTransition: PresentationControllerTransition {

    public var edge: Edge
    public var prefersScaleEffect: Bool
    public var preferredCornerRadius: CGFloat?
    public var presentationBackgroundColor: UIColor?

    static let displayCornerRadius: CGFloat = {
        #if targetEnvironment(macCatalyst)
        return 12
        #else
        return max(UIScreen.main.displayCornerRadius, 12)
        #endif
    }()

    public init(
        edge: Edge,
        prefersScaleEffect: Bool = true,
        preferredCornerRadius: CGFloat? = nil,
        presentationBackgroundColor: UIColor? = nil,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        self.prefersScaleEffect = prefersScaleEffect
        self.preferredCornerRadius = preferredCornerRadius
        self.presentationBackgroundColor = presentationBackgroundColor
        super.init(isPresenting: isPresenting, animation: animation)
    }

    public override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let isPresenting = isPresenting
        let animator = UIViewPropertyAnimator(animation: animation) ?? UIViewPropertyAnimator(duration: duration, curve: completionCurve)

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        let frame = transitionContext.finalFrame(for: presented)
        #if targetEnvironment(macCatalyst)
        let isScaleEnabled = false
        #else
        let isTranslucentBackground = presentationBackgroundColor?.isTranslucent ?? false
        let isScaleEnabled = prefersScaleEffect && !isTranslucentBackground && presenting.view.convert(presenting.view.frame.origin, to: nil).y == 0 &&
            frame.origin.y == 0
        #endif
        let safeAreaInsets = transitionContext.containerView.safeAreaInsets
        let cornerRadius = preferredCornerRadius ?? Self.displayCornerRadius

        var dzTransform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        switch edge {
        case .top:
            dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.bottom / 2)
        case .bottom:
            dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.top / 2)
        case .leading:
            switch presented.traitCollection.layoutDirection {
            case .rightToLeft:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.left / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.right / 2)
            }
        case .trailing:
            switch presented.traitCollection.layoutDirection {
            case .leftToRight:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.right / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.left / 2)
            }
        }

        presented.view.layer.masksToBounds = true
        presented.view.layer.cornerCurve = .continuous

        presenting.view.layer.masksToBounds = true
        presenting.view.layer.cornerCurve = .continuous

        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = frame
            presented.view.transform = presentationTransform(
                presented: presented,
                frame: frame
            )
        } else {
            presented.view.layer.cornerRadius = cornerRadius
            #if !targetEnvironment(macCatalyst)
            if isScaleEnabled {
                presenting.view.transform = dzTransform
                presenting.view.layer.cornerRadius = cornerRadius
            }
            #endif
        }

        let presentedTransform = isPresenting ? .identity : presentationTransform(
            presented: presented,
            frame: frame
        )
        let presentingTransform = isPresenting && isScaleEnabled ? dzTransform : .identity
        animator.addAnimations {
            presented.view.transform = presentedTransform
            presented.view.layer.cornerRadius = isPresenting ? cornerRadius : 0
            presenting.view.transform = presentingTransform
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = isPresenting ? cornerRadius : 0
            }
        }
        animator.addCompletion { animatingPosition in

            if presented.view.frame.origin.y == 0 {
                presented.view.layer.cornerRadius = 0
            }

            if isScaleEnabled {
                presenting.view.layer.cornerRadius = 0
                presenting.view.transform = .identity
            }

            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        return animator
    }

    private func presentationTransform(
        presented: UIViewController,
        frame: CGRect
    ) -> CGAffineTransform {
        switch edge {
        case .top:
            return CGAffineTransform(translationX: 0, y: -frame.maxY)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: frame.maxY)
        case .leading:
            switch presented.traitCollection.layoutDirection {
            case .rightToLeft:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        case .trailing:
            switch presented.traitCollection.layoutDirection {
            case .leftToRight:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        }
    }
}

#endif
