//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class MatchedGeometryViewControllerTransition: ViewControllerTransition {

    public let prefersScaleEffect: Bool
    public let prefersZoomEffect: Bool
    public let preferredFromCornerRadius: CornerRadiusOptions?
    public let preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?
    public let initialOpacity: CGFloat
    public weak var sourceView: UIView?

    public init(
        sourceView: UIView?,
        prefersScaleEffect: Bool,
        prefersZoomEffect: Bool,
        preferredFromCornerRadius: CornerRadiusOptions?,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        initialOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.prefersScaleEffect = prefersScaleEffect
        self.prefersZoomEffect = prefersZoomEffect
        self.preferredFromCornerRadius = preferredFromCornerRadius
        self.preferredToCornerRadius = preferredToCornerRadius
        self.initialOpacity = initialOpacity
        super.init(isPresenting: isPresenting, animation: animation)
        self.sourceView = sourceView
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

        let sourceView = sourceView
        let sourceViewController = sourceView?.viewController
        let prefersZoomEffect = prefersZoomEffect
        let initialOpacity = initialOpacity
        let isPresenting = isPresenting

        let presentedPortalView: PortalView? = {
            if prefersZoomEffect {
                let portalView = PortalView(sourceView: presentedView)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        let hostingController: AnyHostingController? = {
            if presentedPortalView != nil {
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
            if prefersScaleEffect, let sourceView {
                let portalView = PortalView(sourceView: sourceView)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame

        if let sourceViewPortalView {
            transitionContext.containerView.insertSubview(sourceViewPortalView, at: 0)
            sourceViewPortalView.frame = sourceFrame
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

            if let sourceViewPortalView {
                sourceViewPortalView.alpha = 1 - initialOpacity
                sourceView?.alpha = 0
            } else {
                sourceView?.alpha = 1 - initialOpacity
            }

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

        } else {
            if presentedView.layer.cornerRadius == 0 {
                toCornerRadius.apply(to: presentedPortalView ?? presentedView)
            }
            presentedView.layoutIfNeeded()
            hostingController?.render()

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView
            )

            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, belowSubview: presentedView)
            }

            if let sourceViewPortalView {
                sourceViewPortalView.alpha = initialOpacity
                sourceView?.alpha = 0
            } else {
                sourceView?.alpha = 1 - initialOpacity
            }
        }


        if !isPresenting {
            if isScaleEnabled {
                presentingPortalView?.transform = scaleEffect
            }
            sourceViewPortalView?.transform = CGAffineTransform(to: sourceFrame, from: presentedFrame, preserveAspectRatio: true)
        }

        if !isPresenting, prefersZoomEffect, let presentedPortalView {
            transitionContext.containerView.addSubview(presentedPortalView)
            presentedPortalView.frame = presentedFrame
            presentedPortalView.transform = presentedView.transform
            if let presentationController = presented._activePresentationController as? PresentationController {
                presentationController.shadowView.preferredSourceView = presentedPortalView
            }
        }

        animator.addAnimations {
            (sourceViewPortalView ?? sourceView)?.alpha = isPresenting ? 0 : 1 - initialOpacity
            if prefersZoomEffect {
                presentedPortalView?.alpha = isPresenting ? 1 : initialOpacity
            } else {
                presentedView.alpha = isPresenting ? 1 : initialOpacity
            }

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
            } else {
                fromCornerRadius.apply(to: (presentedPortalView ?? presentedView).layer, height: sourceFrame.height)
            }

            (presentedPortalView ?? presentedView).frame = isPresenting ? presentedFrame : sourceFrame
            (presentedPortalView ?? presentedView).layoutIfNeeded()

            if !isPresenting {
                presentingPortalView?.layer.cornerRadius = 0
            }
            presentingPortalView?.transform = isPresenting ? scaleEffect : .identity
            sourceViewPortalView?.transform = isPresenting ? CGAffineTransform(to: sourceFrame, from: presentedFrame, preserveAspectRatio: true) : .identity
        }

        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = disableSafeArea
            presentedPortalView?.removeFromSuperview()
            sourceViewPortalView?.removeFromSuperview()
            if !isPresenting {
                presentingPortalView?.removeFromSuperview()
            }
            sourceView?.alpha = isPresenting ? 0 : 1
            presentedView.layer.cornerRadius = 0
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
