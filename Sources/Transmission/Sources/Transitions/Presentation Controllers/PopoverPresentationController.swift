//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

open class PopoverPresentationController: UIPopoverPresentationController {

    public let dimmingView: DimmingView = {
        let view = DimmingView()
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()

    open override var passthroughViews: [UIView]? {
        didSet {
            let isHidden = !(passthroughViews?.isEmpty ?? true)
            dimmingView.backgroundColor = isHidden ? .clear : DimmingView.backgroundColor
        }
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            presentedViewController.view.superview?.clipsToBounds = false
            presentedViewController.view.superview?.cornerConfiguration = .corners(
                topLeftRadius: nil,
                topRightRadius: nil,
                bottomLeftRadius: nil,
                bottomRightRadius: nil
            )
        }
        #endif

        containerView?.insertSubview(dimmingView, at: 0)
        dimmingView.frame = containerView?.bounds ?? .zero

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated
        {
            transitionCoordinator.animate { _ in
                self.dimmingView.alpha = 1
            }
        } else {
            dimmingView.alpha = 1
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if !completed {
            dimmingView.alpha = 0
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated
        {
            transitionCoordinator.animate { _ in
                self.dimmingView.alpha = 0
            }
        } else {
            dimmingView.alpha = 0
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if !completed {
            dimmingView.alpha = 1
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        let hasTranslucentBackground = backgroundColor?.isTranslucent == true
        presentedView?.subviews.first?.isHidden = hasTranslucentBackground
        presentedView?.subviews.last?.subviews.first?.isHidden = hasTranslucentBackground
    }
}

#endif
