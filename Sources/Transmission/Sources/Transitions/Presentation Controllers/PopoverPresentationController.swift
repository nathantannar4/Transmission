//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

open class PopoverPresentationController: UIPopoverPresentationController {

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
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        let hasTranslucentBackground = backgroundColor?.isTranslucent == true
        presentedView?.subviews.first?.isHidden = hasTranslucentBackground
        presentedView?.subviews.last?.subviews.first?.isHidden = hasTranslucentBackground
    }
}

#endif
