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

    public var prefersScaleEffect: Bool {
        didSet {
            guard oldValue != prefersScaleEffect else { return }
            prefersScaleEffectDidChange()
        }
    }


    open override var wantsInteractiveDismissal: Bool {
        return prefersInteractiveDismissal
    }

    open override var presentationStyle: UIModalPresentationStyle {
        .overFullScreen
    }

    public init(
        edge: Edge = .bottom,
        prefersScaleEffect: Bool,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        self.prefersScaleEffect = prefersScaleEffect
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        dimmingView.isHidden = false
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        if prefersInteractiveDismissal {
            return super.presentedViewTransform(for: translation)
        }
        return .identity
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        if transform.isIdentity {
            presentedViewController.view.layer.cornerRadius = 0
            updateShadow(progress: 0)
        } else {
            presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius()
            let progress = max(0, min(transform.d, 1))
            updateShadow(progress: progress)
        }
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.layer.cornerCurve = .continuous
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentingViewController.view.isHidden = false
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        presentingViewController.view.isHidden = false
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        prefersScaleEffectDidChange()
    }

    private func prefersScaleEffectDidChange() {
        let didScale = prefersScaleEffect && (presentingViewController.view.backgroundColor?.isTranslucent ?? true)
        if didScale, let nextPresentedViewController = presentedViewController.presentedViewController {
            presentingViewController.view.isHidden = !nextPresentedViewController.isBeingDismissed
        } else {
            presentingViewController.view.isHidden = false
        }
    }
}

/// An interactive transition built for the ``SlidePresentationController``.
@available(iOS 14.0, *)
open class SlidePresentationControllerTransition: PresentationControllerTransition {

    public var edge: Edge
    public var prefersScaleEffect: Bool
    public var preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle?
    public var preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?

    public init(
        edge: Edge,
        prefersScaleEffect: Bool = true,
        preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        self.prefersScaleEffect = prefersScaleEffect
        self.preferredFromCornerRadius = preferredFromCornerRadius
        self.preferredToCornerRadius = preferredToCornerRadius
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        let isPresenting = isPresenting
        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let frame = transitionContext.finalFrame(for: presented)
        #if targetEnvironment(macCatalyst)
        let isScaleEnabled = false
        let toCornerRadius = preferredToCornerRadius ?? .identity
        let fromCornerRadius = preferredFromCornerRadius ?? .identity
        #else
        let isTranslucentBackground = presented.view.backgroundColor?.isTranslucent ?? false
        var isScaleEnabled = prefersScaleEffect && !isTranslucentBackground && presenting.view.convert(presenting.view.frame.origin, to: nil).y == 0 &&
            frame.origin.y == 0
        if isScaleEnabled, #available(iOS 18.0, *) {
            isScaleEnabled = presenting.preferredTransition == nil
        }
        let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)
        let fromCornerRadius = preferredFromCornerRadius ?? preferredToCornerRadius ?? .screen()
        #endif
        let safeAreaInsets = transitionContext.containerView.safeAreaInsets

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

        #if !targetEnvironment(macCatalyst)
        if isScaleEnabled {
            presenting.view.layer.cornerCurve = .continuous
            presenting.view.layer.masksToBounds = true
        }
        #endif

        if isPresenting {
            if presented.view.superview == nil {
                transitionContext.containerView.addSubview(presented.view)
            }
            presented.view.frame = frame
            presented.view.transform = presentationTransform(
                presented: presented,
                frame: frame
            )
            fromCornerRadius.apply(to: presented.view.layer)
        } else {
            #if !targetEnvironment(macCatalyst)
            if isScaleEnabled {
                presenting.view.transform = dzTransform
                presenting.view.layer.cornerRadius = UIScreen.main.displayCornerRadius()
            }
            #endif
            toCornerRadius.apply(to: presented.view.layer)
        }

        presented.view.layoutIfNeeded()

        let presentedTransform = isPresenting ? .identity : presentationTransform(
            presented: presented,
            frame: frame
        )
        let presentingTransform = isPresenting && isScaleEnabled ? dzTransform : .identity
        animator.addAnimations {
            presented.view.transform = presentedTransform
            presenting.view.transform = presentingTransform
            (isPresenting ? toCornerRadius : fromCornerRadius).apply(to: presented.view.layer)
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = isPresenting ? UIScreen.main.displayCornerRadius() : 0
            }
        }
        animator.addCompletion { animatingPosition in
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = 0
                presenting.view.layer.masksToBounds = true
                presenting.view.transform = .identity
            }
            presented.view.layer.cornerRadius = 0
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
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
