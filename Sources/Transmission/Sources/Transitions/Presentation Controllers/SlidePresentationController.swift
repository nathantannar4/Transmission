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
            dimmingView.isHidden = !prefersScaleEffect
            updatePortalView()
        }
    }

    public var preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle?

    public var preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?

    open override var presentationStyle: UIModalPresentationStyle {
        .overFullScreen
    }

    private var portalView: UIView?

    public init(
        edge: Edge = .bottom,
        prefersScaleEffect: Bool,
        preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        self.prefersScaleEffect = prefersScaleEffect
        self.preferredFromCornerRadius = preferredFromCornerRadius
        self.preferredToCornerRadius = preferredToCornerRadius
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        dimmingView.isHidden = !prefersScaleEffect
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        updatePortalView()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedView?.layer.cornerRadius = 0
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        if let presentedView {
            let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)
            toCornerRadius.apply(to: presentedView)
        }
    }

    open override func transitionAlongsidePresentation(progress: CGFloat) {
        super.transitionAlongsidePresentation(progress: progress)
        if let presentedView {
            if presentedViewController.isBeingPresented {
                let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)
                toCornerRadius.apply(to: presentedView)
            } else if presentedViewController.isBeingDismissed {
                let fromCornerRadius = preferredToCornerRadius ?? .identity
                fromCornerRadius.apply(to: presentedView)
            }
        }
        portalView?.transform = portalViewTransform(progress: progress)
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        if transform.isIdentity {
            presentedViewController.view.layer.cornerRadius = 0
            updateShadow(progress: 0)
        } else {
            if let presentedView {
                let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)
                toCornerRadius.apply(to: presentedView)
            }
            let progress = max(0, min(transform.d, 1))
            updateShadow(progress: progress)
        }
    }


    open override func transitionAlongsideRotation() {
        super.transitionAlongsideRotation()
        portalView?.frame = containerView?.bounds ?? .zero
        portalView?.transform = portalViewTransform(progress: 1)
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        portalView?.setFramePreservingTransform(containerView?.bounds ?? .zero)
    }

    private func updatePortalView() {
        if prefersScaleEffect, portalView == nil {
            if let portalView = PortalView(sourceView: presentingViewController.view) {
                portalView.hidesSourceView = true
                portalView.layer.cornerCurve = .continuous
                portalView.layer.masksToBounds = true
                portalView.layer.cornerRadius = UIScreen.main.displayCornerRadius()
                containerView?.insertSubview(portalView, at: 0)
                self.portalView = portalView
            }
        } else if !prefersScaleEffect {
            portalView?.removeFromSuperview()
        }
    }

    private func portalViewTransform(progress: CGFloat) -> CGAffineTransform {
        var dzTransform = CGAffineTransform(scaleX: 1 - (0.08 * progress), y: 1 - (0.08 * progress))
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        switch edge {
        case .top:
            dzTransform = dzTransform.translatedBy(x: 0, y: progress * safeAreaInsets.bottom / 2)
        case .bottom:
            dzTransform = dzTransform.translatedBy(x: 0, y: progress * safeAreaInsets.top / 2)
        case .leading:
            switch traitCollection.layoutDirection {
            case .rightToLeft:
                dzTransform = dzTransform.translatedBy(x: 0, y: progress * safeAreaInsets.left / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: progress * safeAreaInsets.right / 2)
            }
        case .trailing:
            switch traitCollection.layoutDirection {
            case .leftToRight:
                dzTransform = dzTransform.translatedBy(x: 0, y: progress * safeAreaInsets.right / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: progress * safeAreaInsets.left / 2)
            }
        }
        return dzTransform
    }
}

/// An interactive transition built for the ``SlidePresentationController``.
@available(iOS 14.0, *)
open class SlidePresentationControllerTransition: PresentationControllerTransition {

    public var edge: Edge

    public init(
        edge: Edge,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentingView = transitionContext.view(forKey: isPresenting ? .from : .to) ?? presenting.view
        else {
            transitionContext.completeTransition(false)
            return
        }

        if isPresenting {
            presentedView.alpha = 0
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView,
                presentedFrame: &presentedFrame
            )

            let transform = presentationTransform(
                presented: presented,
                frame: presentedFrame
            )
            presentedView.transform = transform
            presentedView.alpha = 1
            animator.addAnimations {
                presentedView.transform = .identity
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            let transform = presentationTransform(
                presented: presented,
                frame: presentedView.frame
            )
            presentedView.layoutIfNeeded()

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView
            )

            animator.addAnimations {
                presentedView.transform = transform
            }
        }
        animator.addCompletion { animatingPosition in
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
