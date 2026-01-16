//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class MatchedGeometryViewControllerTransition: ViewControllerTransition {

    public weak var sourceView: UIView?
    public let prefersScaleEffect: Bool
    public let prefersZoomEffect: Bool
    public let preferredFromCornerRadius: CornerRadiusOptions?
    public let preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?
    public let initialOpacity: CGFloat
    public let sourceViewFrameTransform: SourceViewFrameTransform?

    public init(
        sourceView: UIView?,
        prefersScaleEffect: Bool,
        prefersZoomEffect: Bool,
        preferredFromCornerRadius: CornerRadiusOptions?,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        initialOpacity: CGFloat,
        sourceViewFrameTransform: SourceViewFrameTransform? = nil,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.prefersScaleEffect = prefersScaleEffect
        self.prefersZoomEffect = prefersZoomEffect
        self.preferredFromCornerRadius = preferredFromCornerRadius
        self.preferredToCornerRadius = preferredToCornerRadius
        self.initialOpacity = initialOpacity
        self.sourceViewFrameTransform = sourceViewFrameTransform
        super.init(isPresenting: isPresenting, animation: animation)
        self.sourceView = sourceView
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let sourceView = sourceView,
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentingView = transitionContext.view(forKey: isPresenting ? .from : .to) ?? presenting.view
        else {
            super.configureTransitionAnimator(using: transitionContext, animator: animator)
            return
        }

        let sourceViewController = sourceView.viewController
        let prefersZoomEffect = prefersZoomEffect
        let initialOpacity = initialOpacity
        let isPresenting = isPresenting

        let presentedPortalView: PortalView? = {
            if prefersZoomEffect {
                let portalView = PortalView(sourceView: presentedView)
                portalView?.hidesSourceView = true
                portalView?.matchesTransform = true
                return portalView
            }
            return nil
        }()

        let hostingController: AnyHostingController? = {
            if prefersZoomEffect, isPresenting, presentedPortalView != nil {
                return nil
            }
            return presented as? AnyHostingController
        }()

        #if targetEnvironment(macCatalyst)
        var isScaleEnabled = false
        #else
        var isScaleEnabled = prefersScaleEffect &&
            presentingView.convert(presentingView.frame.origin, to: nil).y == 0 &&
            sourceViewController != presenting &&
            (isPresenting ? transitionContext.finalFrame(for: presenting).origin.y : transitionContext.initialFrame(for: presenting).origin.y) == 0
        if isScaleEnabled, #available(iOS 18.0, *) {
            isScaleEnabled = presenting.preferredTransition == nil
        }
        #endif

        let presentingPortalView: PortalView? = {
            for subview in transitionContext.containerView.subviews {
                if let portalView = subview as? PortalView,
                    portalView.sourceView?.isDescendant(of: presentingView) == true
                {
                    portalView.removeFromSuperview()
                    break
                }
            }
            if isScaleEnabled {
                let sourceView = (isScaleEnabled ? sourceViewController?.view : presentingView) ?? presentingView
                let portalView = PortalView(sourceView: sourceView)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        let sourceViewPortalView: PortalView? = {
            let portalView = PortalView(sourceView: sourceView)
            portalView?.hidesSourceView = true
            return portalView
        }()
        sourceViewPortalView?.isHidden = true

        var sourceFrame = sourceView.convert(sourceView.frame, to: transitionContext.containerView)
        sourceViewFrameTransform?(&sourceFrame)

        if let sourceViewPortalView {
            sourceViewPortalView.alpha = isPresenting ? 1 - initialOpacity : 1
            if let sourceViewContainer = sourceView.superview {
                sourceViewContainer.insertSubview(sourceViewPortalView, aboveSubview: sourceView)
                sourceViewPortalView.frame = sourceViewPortalView.convert(sourceFrame, from: transitionContext.containerView)
            } else {
                sourceViewPortalView.frame = sourceFrame
            }
        }

        let scaleEffect = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if let presentingPortalView {
            if presentingPortalView.superview == nil {
                transitionContext.containerView.insertSubview(presentingPortalView, at: 0)
            }
            if isScaleEnabled {
                if isPresenting {
                    presentingPortalView.frame = transitionContext.initialFrame(for: presenting)
                } else {
                    presentingPortalView.frame = transitionContext.finalFrame(for: presenting)
                }
                presentingPortalView.layer.cornerRadius = UIScreen.main.displayCornerRadius()
                presentingPortalView.layer.masksToBounds = true
            }
        }

        let disableSafeArea = hostingController?.disableSafeArea ?? false
        if isPresenting, !transitionContext.isInteractive {
            hostingController?.disableSafeArea = true
        } else {
            presented.transitionCoordinator?.notifyWhenInteractionChanges { ctx in
                guard !ctx.isCancelled else { return }
                hostingController?.disableSafeArea = true
            }
        }

        var presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
            : (presentedView.transform.isIdentity ? presentedView.frame : transitionContext.initialFrame(for: presented))

        let fromCornerRadius = preferredFromCornerRadius ?? .identity
        let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)

        if isPresenting {
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            fromCornerRadius.apply(to: presentedPortalView ?? presentedView, height: sourceFrame.height)


            if prefersZoomEffect {
                presentedView.frame = presentedFrame
                presentedView.layoutIfNeeded()
                if let presentedPortalView {
                    transitionContext.containerView.addSubview(presentedPortalView)
                }
                presentedPortalView?.frame = sourceFrame
                presentedPortalView?.alpha = initialOpacity

            } else {
                presentedView.frame = sourceFrame
                presentedView.alpha = initialOpacity
                presentedView.layoutIfNeeded()
            }

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView,
                presentedFrame: &presentedFrame
            )
            presented.transitionReaderCoordinator?.update(isPresented: true)

        } else {
            if presentedView.layer.cornerRadius == 0 {
                toCornerRadius.apply(to: presentedPortalView ?? presentedView)
            }
            presentedView.layoutIfNeeded()
            hostingController?.render()

            presented.transitionReaderCoordinator?.update(isPresented: false)

            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, belowSubview: presentedView)
            }
        }

        if !isPresenting {
            if isScaleEnabled {
                presentingPortalView?.transform = scaleEffect
            }
            if let sourceViewPortalView {
                sourceViewPortalView.transform = CGAffineTransform(to: sourceFrame, from: presentedFrame, preserveAspectRatio: true)
                if let preferredToCornerRadius {
                    preferredToCornerRadius.apply(to: sourceViewPortalView)
                } else {
                    sourceViewPortalView.applyCornerRadius(from: presentedView)
                }
            }
        }

        if !isPresenting, prefersZoomEffect, let presentedPortalView {
            transitionContext.containerView.addSubview(presentedPortalView)
            presentedPortalView.frame = presentedFrame
            presentedPortalView.transform = presentedView.transform
            if let preferredToCornerRadius {
                preferredToCornerRadius.apply(to: presentedPortalView)
            } else {
                presentedPortalView.applyCornerRadius(from: presentedView)
            }
            presentedView.frame = transitionContext.initialFrame(for: presented)
            presentedView.transform = CGAffineTransform(to: presentedView.frame, from: presentedFrame)
            if let presentationController = presented._activePresentationController as? PresentationController {
                presentationController.shadowView.preferredSourceView = presentedPortalView
            }
        }

        sourceViewPortalView?.isHidden = false
        let opacityAnimations: () -> Void = {
            if isPresenting {
                sourceViewPortalView?.alpha = 0
            }
            (presentedPortalView ?? presentedView).alpha = isPresenting ? 1 : 0
        }
        let animations: () -> Void = {
            if isPresenting {
                if !transitionContext.isInteractive {
                    hostingController?.disableSafeArea = disableSafeArea
                } else {
                    hostingController?.disableSafeArea = true
                }
            } else if !isPresenting, !transitionContext.isInteractive {
                hostingController?.disableSafeArea = true
            }

            if isPresenting {
                toCornerRadius.apply(to: presentedPortalView ?? presentedView)
                if let sourceViewPortalView {
                    toCornerRadius.apply(to: sourceViewPortalView)
                }
            } else {
                fromCornerRadius.apply(to: presentedPortalView ?? presentedView, height: sourceFrame.height)
                if let sourceViewPortalView {
                    fromCornerRadius.apply(to: sourceViewPortalView, height: sourceFrame.height)
                }
            }

            (presentedPortalView ?? presentedView).frame = isPresenting ? presentedFrame : sourceFrame
            (presentedPortalView ?? presentedView).layoutIfNeeded()

            presentedView.transform = .identity
            presentingPortalView?.transform = isPresenting ? scaleEffect : .identity
            sourceViewPortalView?.transform = isPresenting ? CGAffineTransform(to: sourceFrame, from: presentedFrame, preserveAspectRatio: true) : .identity
        }

        // Just for navigation transitions
        let shouldDelayAnimations = isPresenting && !prefersZoomEffect && presented.parent is UINavigationController
        let opacityAnimationDelay: TimeInterval = prefersZoomEffect ? (isPresenting ? 0.25 : 0.75) : 0
        if shouldDelayAnimations {
            withCATransaction {
                animator.addAnimations(animations)
                animator.addAnimations(opacityAnimations, delayFactor: opacityAnimationDelay)
            }
        } else {
            animator.addAnimations(animations)
            animator.addAnimations(opacityAnimations, delayFactor: opacityAnimationDelay)
        }
        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = disableSafeArea
            presentedPortalView?.removeFromSuperview()
            sourceViewPortalView?.removeFromSuperview()
            if !isPresenting {
                presentingPortalView?.removeFromSuperview()
            }
            sourceView.alpha = isPresenting ? 0 : 1
            if shouldDelayAnimations {
                presentedView.layer.removeAllAnimations()
            }
            CornerRadiusOptions.identity.apply(to: presentedView)
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
    }
}

#endif
