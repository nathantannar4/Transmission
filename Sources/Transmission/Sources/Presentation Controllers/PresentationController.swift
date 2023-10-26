//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine
import Turbocharger

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class PresentationController: UIPresentationController {

    open var shouldAutoLayoutPresentedView: Bool {
        presentedView?.transform == .identity
            && !presentedViewController.isBeingPresented
            && !presentedViewController.isBeingDismissed
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        delegate?.presentationControllerWillDismiss?(self)
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            delegate?.presentationControllerDidDismiss?(self)
        } else {
            delegate?.presentationControllerDidAttemptToDismiss?(self)
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if shouldAutoLayoutPresentedView {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
        }
    }

    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        let frame = frameOfPresentedViewInContainerView
        coordinator.animateAlongsideTransition(in: containerView) { _ in
            self.layoutPresentedView(frame: frame)
        }
    }

    open func layoutPresentedView(frame: CGRect) {
        presentedView?.frame = frame
    }
}

#endif
