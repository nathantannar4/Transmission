//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 14.0, *)
class MatchedGeometryPresentationController: InteractivePresentationController {

    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }

    override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        let bottomSafeArea = containerView?.safeAreaInsets.bottom ?? 0
        let scale = presentedViewController.view.window?.screen.scale ?? 1
        let dy = transform.ty.rounded(scale: scale)
        let bottomInset = min(-min(0, dy), bottomSafeArea)
        presentedViewController.additionalSafeAreaInsets.bottom = bottomInset
    }
}

@available(iOS 14.0, *)
class MatchedGeometryTransition: PresentationControllerTransition {

    weak var sourceView: UIView?

    init(sourceView: UIView, isPresenting: Bool) {
        super.init(isPresenting: isPresenting)
        self.sourceView = sourceView
    }

    override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: .easeInOut
        )

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        let isPresenting = isPresenting
        let hostingController = presented as? AnyHostingController

        let oldValue = hostingController?.disableSafeArea ?? false
        hostingController?.disableSafeArea = true

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame
        let presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
            : transitionContext.initialFrame(for: presented)
        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = sourceFrame
            presented.view.layoutIfNeeded()
            hostingController?.render()
        }

        animator.addAnimations {
            if isPresenting {
                hostingController?.disableSafeArea = oldValue
            }
            presented.view.frame = isPresenting ? presentedFrame : sourceFrame
            presented.view.layoutIfNeeded()
        }
        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = oldValue
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        return animator
    }
}

extension CGAffineTransform {
    init(from source: CGRect, to destination: CGRect) {
        self = CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }
}

#endif
