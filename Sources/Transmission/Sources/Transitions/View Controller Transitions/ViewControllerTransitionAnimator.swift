//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@MainActor @preconcurrency
public protocol ViewControllerTransitionAnimator {

    func animateTransition(
        with animator: UIViewPropertyAnimator,
        using transitionContext: UIViewControllerContextTransitioning,
        isPresenting: Bool
    )
}

extension ViewControllerTransitionAnimator {

    public func animateAlongsideTransitionReader(
        using transitionContext: UIViewControllerContextTransitioning,
        isPresenting: Bool,
        presentedFrame: inout CGRect
    ) {
        guard
            transitionContext.presentationStyle != .none,
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentationController = presented.presentationController,
            let hostingController = presented as? AnyHostingController
        else {
            return
        }

        presentedView.alpha = 0; defer { presentedView.alpha = 1 }

        hostingController.render()

        guard
            let transitionReaderCoordinator = presented.transitionReaderCoordinator
        else {
            return
        }

        transitionReaderCoordinator.update(isPresented: true)

        if presentationController.presentedViewController.preferredContentSize != .zero {
            presentationController.presentedViewController.preferredContentSize = .zero
        }

        presentedView.setNeedsLayout()
        presentedView.layoutIfNeeded()

        presentedFrame = presentationController.frameOfPresentedViewInContainerView

        transitionReaderCoordinator.update(isPresented: false)
        presentedView.setNeedsLayout()
        presentedView.layoutIfNeeded()
    }

}

#endif
