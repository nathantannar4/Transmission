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
        let sourceViewController = sourceView?.viewController
        let prefersScaleEffect = prefersScaleEffect
        let prefersZoomEffect = prefersZoomEffect
        let initialOpacity = initialOpacity
        let isPresenting = isPresenting

        lazy var hostingController: AnyHostingController? = {
            if prefersZoomEffect {
                return nil
            }
            return presented as? AnyHostingController
        }()

        lazy var portalView: PortalView? = {
            if prefersZoomEffect {
                let portalView = PortalView(sourceView: presented.view)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        lazy var window: UIWindow? = {
            if prefersScaleEffect {
                if sourceViewController?.parent == nil {
                    if let window = sourceViewController?.view.window {
                        return window
                    }
                }
            }
            return nil
        }()

        let scaleEffect = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if prefersScaleEffect, !isPresenting {
            sourceViewController?.view.transform = .identity
            sourceViewController?.view.layer.cornerRadius = UIScreen.main.displayCornerRadius()
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

        if prefersScaleEffect {
            sourceViewController?.view.layer.masksToBounds = true
            if window?.backgroundColor == nil {
                window?.backgroundColor = sourceViewController?.view.backgroundColor
            }
        }

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame

        var presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
            : (presented.view.transform.isIdentity ? presented.view.frame : transitionContext.initialFrame(for: presented))

        if prefersScaleEffect, !isPresenting {
            sourceViewController?.view.transform = scaleEffect
        }

        let fromCornerRadius = preferredFromCornerRadius ?? .rounded(cornerRadius: 0)
        let toCornerRadius = preferredToCornerRadius ?? .screen(min: 0)

        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            fromCornerRadius.apply(to: presented.view.layer, height: sourceFrame.height)

            sourceView?.alpha = 1 - initialOpacity

            if prefersZoomEffect {
                presented.view.frame = presentedFrame
                presented.view.layoutIfNeeded()
                if let portalView {
                    transitionContext.containerView.addSubview(portalView)
                }
                portalView?.frame = presentedFrame
                portalView?.alpha = initialOpacity
                portalView?.transform = CGAffineTransform(to: presentedFrame, from: sourceFrame)
                if let presentationController = presented._activePresentationController as? PresentationController {
                    presentationController.shadowView.preferredSourceView = portalView
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


        if !isPresenting, prefersScaleEffect {
            sourceViewController?.view.transform = scaleEffect
        }

        if !isPresenting, prefersZoomEffect, let portalView {
            transitionContext.containerView.addSubview(portalView)
            portalView.frame = presentedFrame
            portalView.transform = presented.view.transform
            if let presentationController = presented._activePresentationController as? PresentationController {
                presentationController.shadowView.preferredSourceView = portalView
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
                portalView?.transform = isPresenting ? .identity : CGAffineTransform(to: presentedFrame, from: sourceFrame)
            } else {
                presented.view.frame = isPresenting ? presentedFrame : sourceFrame
                presented.view.layoutIfNeeded()
            }

            if prefersScaleEffect {
                sourceViewController?.view.layer.cornerRadius = isPresenting ? UIScreen.main.displayCornerRadius() : 0
                sourceViewController?.view.transform = isPresenting ? scaleEffect : .identity
            }
        }
        animator.addAnimations({
            sourceView?.alpha = isPresenting ? 0 : 1 - initialOpacity
            if prefersZoomEffect {
                portalView?.alpha = isPresenting ? 1 : initialOpacity
            } else {
                presented.view.alpha = isPresenting ? 1 : initialOpacity
            }
        }, delayFactor: isPresenting ? 0 : 0.25)

        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = disableSafeArea
            portalView?.removeFromSuperview()
            sourceView?.alpha = isPresenting ? 0 : 1
            if prefersScaleEffect, !isPresenting {
                sourceViewController?.view.layer.masksToBounds = false
                window?.backgroundColor = nil
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
}

#endif
