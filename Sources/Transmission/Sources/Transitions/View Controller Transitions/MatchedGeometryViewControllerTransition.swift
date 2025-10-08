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
        let prefersZoomEffect = prefersZoomEffect
        let initialOpacity = initialOpacity
        let isPresenting = isPresenting

        lazy var hostingController: AnyHostingController? = {
            if prefersZoomEffect {
                return nil
            }
            return presented as? AnyHostingController
        }()

        lazy var presentedPortalView: PortalView? = {
            if prefersZoomEffect {
                let portalView = PortalView(sourceView: presentedView)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        #if targetEnvironment(macCatalyst)
        var isScaleEnabled = false
        #else
        let isTranslucentBackground = presentedView.backgroundColor?.isTranslucent ?? false
        var isScaleEnabled = prefersScaleEffect && !isTranslucentBackground && presentingView.convert(presentingView.frame.origin, to: nil).y == 0 &&
            (isPresenting ? transitionContext.finalFrame(for: presenting).origin.y : transitionContext.initialFrame(for: presenting).origin.y) == 0
        if isScaleEnabled, #available(iOS 18.0, *) {
            isScaleEnabled = presenting.preferredTransition == nil
        }
        #endif

        lazy var presentingPortalView: PortalView? = {
            let sourceView = sourceView?.viewController?.view ?? presentingView
            for subview in transitionContext.containerView.subviews {
                if let portalView = subview as? PortalView, portalView.sourceView == sourceView {
                    portalView.removeFromSuperview()
                    break
                }
            }
            if isScaleEnabled {
                let portalView = PortalView(sourceView: sourceView)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()
        isScaleEnabled = presentingPortalView != nil

        let scaleEffect = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if isScaleEnabled, let presentingPortalView {
            if presentingPortalView.superview == nil {
                transitionContext.containerView.insertSubview(presentingPortalView, at: 0)
            }
            if isPresenting {
                presentingPortalView.frame = transitionContext.initialFrame(for: presenting)
            } else {
                presentingPortalView.frame = transitionContext.finalFrame(for: presenting)
            }
            presentingPortalView.layer.cornerRadius = UIScreen.main.displayCornerRadius()
            presentingPortalView.layer.masksToBounds = true
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

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame

        var presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
            : (presentedView.transform.isIdentity ? presentedView.frame : transitionContext.initialFrame(for: presented))

        let fromCornerRadius = preferredFromCornerRadius ?? .identity
        let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)

        if isPresenting {
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            fromCornerRadius.apply(to: presentedView.layer, height: sourceFrame.height)

            sourceView?.alpha = 1 - initialOpacity

            if prefersZoomEffect {
                presentedView.frame = presentedFrame
                presentedView.layoutIfNeeded()
                if let presentedPortalView {
                    transitionContext.containerView.addSubview(presentedPortalView)
                }
                presentedPortalView?.frame = presentedFrame
                presentedPortalView?.alpha = initialOpacity
                presentedPortalView?.transform = CGAffineTransform(to: presentedFrame, from: sourceFrame)

            } else {
                presentedView.frame = sourceFrame
                presentedView.alpha = initialOpacity
                presentedView.layoutIfNeeded()

                configureTransitionReaderCoordinator(
                    presented: presented,
                    presentedView: presentedView,
                    presentedFrame: &presentedFrame
                )
            }

        } else {
            if presentedView.layer.cornerRadius == 0 {
                toCornerRadius.apply(to: presentedView.layer)
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

            sourceView?.alpha = initialOpacity
        }


        if !isPresenting, isScaleEnabled {
            presentingPortalView?.transform = scaleEffect
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
                toCornerRadius.apply(to: presentedView.layer)
            } else {
                fromCornerRadius.apply(to: presentedView.layer, height: sourceFrame.height)
            }

            if prefersZoomEffect {
                presentedPortalView?.transform = isPresenting ? .identity : CGAffineTransform(to: presentedFrame, from: sourceFrame)
            } else {
                presentedView.frame = isPresenting ? presentedFrame : sourceFrame
                presentedView.layoutIfNeeded()
            }

            if isScaleEnabled {
                if !isPresenting {
                    presentingPortalView?.layer.cornerRadius = 0
                }
                presentingPortalView?.transform = isPresenting ? scaleEffect : .identity
            }
        }
        animator.addAnimations({
            sourceView?.alpha = isPresenting ? 0 : 1 - initialOpacity
            if prefersZoomEffect {
                presentedPortalView?.alpha = isPresenting ? 1 : initialOpacity
            } else {
                presentedView.alpha = isPresenting ? 1 : initialOpacity
            }
        }, delayFactor: isPresenting ? 0 : 0.25)

        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = disableSafeArea
            presentedPortalView?.removeFromSuperview()
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
