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
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
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
                let portalView = PortalView(sourceView: presented.view)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        #if targetEnvironment(macCatalyst)
        var isScaleEnabled = false
        #else
        let isTranslucentBackground = presented.view.backgroundColor?.isTranslucent ?? false
        var isScaleEnabled = prefersScaleEffect && !isTranslucentBackground && presenting.view.convert(presenting.view.frame.origin, to: nil).y == 0 &&
            (isPresenting ? transitionContext.finalFrame(for: presenting).origin.y : transitionContext.initialFrame(for: presenting).origin.y) == 0
        if isScaleEnabled, #available(iOS 18.0, *) {
            isScaleEnabled = presenting.preferredTransition == nil
        }
        #endif

        lazy var presentingPortalView: PortalView? = {
            let sourceView = sourceView?.viewController?.view ?? presenting.view!
            for subview in transitionContext.containerView.subviews {
                if let portalView = subview as? PortalView, portalView.sourceView == sourceView {
                    return portalView
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
            : (presented.view.transform.isIdentity ? presented.view.frame : transitionContext.initialFrame(for: presented))

        let fromCornerRadius = preferredFromCornerRadius ?? .rounded(cornerRadius: 0)
        let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)

        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            fromCornerRadius.apply(to: presented.view.layer, height: sourceFrame.height)

            sourceView?.alpha = 1 - initialOpacity

            if prefersZoomEffect {
                presented.view.frame = presentedFrame
                presented.view.layoutIfNeeded()
                if let presentedPortalView {
                    transitionContext.containerView.addSubview(presentedPortalView)
                }
                presentedPortalView?.frame = presentedFrame
                presentedPortalView?.alpha = initialOpacity
                presentedPortalView?.transform = CGAffineTransform(to: presentedFrame, from: sourceFrame)
                if let presentationController = presented._activePresentationController as? PresentationController {
                    presentationController.shadowView.preferredSourceView = presentedPortalView
                }

            } else {
                presented.view.frame = sourceFrame
                presented.view.alpha = initialOpacity
                presented.view.layoutIfNeeded()
                hostingController?.render()

                if let transitionReaderCoordinator = presented.transitionReaderCoordinator {
                    transitionReaderCoordinator.update(isPresented: true)

                    presented.view.setNeedsLayout()
                    presented.view.layoutIfNeeded()

                    if let presentationController = presented._activePresentationController as? PresentationController {
                        presentedFrame = presentationController.frameOfPresentedViewInContainerView
                    }

                    transitionReaderCoordinator.update(isPresented: false)
                    presented.view.setNeedsLayout()
                    presented.view.layoutIfNeeded()
                    transitionReaderCoordinator.update(isPresented: true)
                }
            }

        } else {
            if presented.view.layer.cornerRadius == 0 {
                toCornerRadius.apply(to: presented.view.layer)
            }
            presented.view.layoutIfNeeded()
            hostingController?.render()

            presented.transitionReaderCoordinator?.update(isPresented: false)

            if presenting.view.superview == nil {
                transitionContext.containerView.insertSubview(presenting.view, belowSubview: presented.view)
            }

            sourceView?.alpha = initialOpacity
        }


        if !isPresenting, isScaleEnabled {
            presentingPortalView?.transform = scaleEffect
        }

        if !isPresenting, prefersZoomEffect, let presentedPortalView {
            transitionContext.containerView.addSubview(presentedPortalView)
            presentedPortalView.frame = presentedFrame
            presentedPortalView.transform = presented.view.transform
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
                toCornerRadius.apply(to: presented.view.layer)
            } else {
                fromCornerRadius.apply(to: presented.view.layer, height: sourceFrame.height)
            }

            if prefersZoomEffect {
                presentedPortalView?.transform = isPresenting ? .identity : CGAffineTransform(to: presentedFrame, from: sourceFrame)
            } else {
                presented.view.frame = isPresenting ? presentedFrame : sourceFrame
                presented.view.layoutIfNeeded()
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
                presented.view.alpha = isPresenting ? 1 : initialOpacity
            }
        }, delayFactor: isPresenting ? 0 : 0.25)

        animator.addCompletion { animatingPosition in
            Task { @MainActor in
                hostingController?.disableSafeArea = disableSafeArea
                presentedPortalView?.removeFromSuperview()
                if !isPresenting {
                    presentingPortalView?.removeFromSuperview()
                }
                sourceView?.alpha = isPresenting ? 0 : 1
                presented.view.layer.cornerRadius = 0
                switch animatingPosition {
                case .end:
                    transitionContext.completeTransition(true)
                default:
                    transitionContext.completeTransition(false)
                }
            }
        }
    }
}

#endif
