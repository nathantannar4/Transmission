//
//  ToastTransition.swift
//  Example
//
//  Created by Nathan Tannar on 2024-05-01.
//

import SwiftUI

import Transmission

extension PresentationLinkTransition {
    static let toast: PresentationLinkTransition = .custom(
        options: Options(preferredPresentationBackgroundColor: .clear),
        ToastTransition()
    )
}

struct ToastTransition: PresentationLinkTransitionRepresentable {
    func makeUIPresentationController(
        context: Context,
        presented: UIViewController,
        presenting: UIViewController?
    ) -> ToastPresentationController {
        ToastPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
    }

    func updateUIPresentationController(
        presentationController: ToastPresentationController,
        context: Context
    ) {

    }
}

class ToastPresentationController: InteractivePresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView,
              let presentedView = presentedView else { return .zero }

        let inset: CGFloat = 16

        // Make sure to account for the safe area insets
        let safeAreaFrame = containerView.bounds
            .inset(by: containerView.safeAreaInsets)

        let targetWidth = safeAreaFrame.width - 2 * inset
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        let sizeThatFits = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )

        var frame = safeAreaFrame
        frame.origin.x = (containerView.bounds.width - sizeThatFits.width) / 2
        frame.origin.y += frame.size.height - sizeThatFits.height - inset
        frame.size = sizeThatFits
        return frame
    }
}
