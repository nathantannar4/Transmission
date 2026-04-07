//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that adapts to device rotations intended for full scren presentations
@available(iOS 14.0, *)
open class FullScreenPresentationController: DelegatedPresentationController {

    open override var shouldPresentInFullscreen: Bool {
        return true
    }

    open override var shouldRemovePresentersView: Bool {
        return true
    }

    open var shouldAutoLayoutPresentedView: Bool {
        !presentedViewController.isBeingPresented && !presentedViewController.isBeingDismissed
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if shouldAutoLayoutPresentedView {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
        }
    }

    open func layoutPresentedView(frame: CGRect) {
        presentedView?.setFramePreservingTransform(frame)
    }
}

#endif
