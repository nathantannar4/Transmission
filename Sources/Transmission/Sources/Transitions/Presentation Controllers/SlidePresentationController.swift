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
        dimmingView.isHidden = false
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        updatePortalView()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed, let presentedView {
            CornerRadiusOptions.RoundedRectangle.identity.apply(to: presentedView)
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if !completed, let presentedView {
            CornerRadiusOptions.RoundedRectangle.identity.apply(to: presentedView)
        }
    }

    open override func transitionAlongsidePresentation(progress: CGFloat) {
        super.transitionAlongsidePresentation(progress: progress)
        if let presentedView {
            if (presentedViewController.isBeingPresented && progress == 1) || (presentedViewController.isBeingDismissed && progress == 0) {
                let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)
                toCornerRadius.apply(to: presentedView)
            } else if (presentedViewController.isBeingDismissed && progress == 1) || (presentedViewController.isBeingPresented && progress == 0) {
                let fromCornerRadius = preferredFromCornerRadius ?? .screen(min: 0)
                fromCornerRadius.apply(to: presentedView)
            }
        }
        portalView?.transform = portalViewTransform(progress: progress)
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        if transform.isIdentity {
            if let presentedView, panGesture.state == .possible {
                CornerRadiusOptions.RoundedRectangle.identity.apply(to: presentedView)
            }
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
            let fromPresentationController = presentingViewController._presentationController
            if fromPresentationController is SlidePresentationController || fromPresentationController == nil {
                if let portalView = PortalView(sourceView: presentingViewController.view) {
                    portalView.hidesSourceView = true
                    portalView.matchesAlpha = true
                    portalView.layer.cornerCurve = .circular
                    portalView.layer.masksToBounds = true
                    portalView.layer.cornerRadius = UIScreen.main.displayCornerRadius()
                    containerView?.insertSubview(portalView, at: 0)
                    self.portalView = portalView
                }
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
    public var initialOpacity: CGFloat

    public init(
        edge: Edge,
        initialOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        self.initialOpacity = initialOpacity
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        let transition = SlideTransitionAnimator(
            edge: edge,
            initialOpacity: initialOpacity,
            animatedViews: [.to]
        )
        transition.animateTransition(with: animator, using: transitionContext, isPresenting: isPresenting)
    }
}

#endif
