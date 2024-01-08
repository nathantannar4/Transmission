//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Turbocharger

open class PresentationHostingController<
    Content: View
>: HostingController<Content> {

    public var tracksContentSize: Bool = false {
        didSet {
            view.setNeedsLayout()
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard view.superview != nil, !isBeingDismissed else {
            return
        }

        let isAnimated = isBeingPresented ? false : transitionCoordinator?.isAnimated ?? true

        if tracksContentSize, #available(iOS 15.0, *),
            presentingViewController != nil,
            let sheetPresentationController = presentationController as? UISheetPresentationController,
            sheetPresentationController.presentedViewController == self,
            let containerView = sheetPresentationController.containerView
        {
            guard
                let selectedIdentifier = sheetPresentationController.selectedDetentIdentifier,
                let detent = sheetPresentationController.detents.first(where: { $0.id == selectedIdentifier.rawValue && $0.isDynamic })
            else {
                return
            }

            let resolvedDetentHeight = detent.resolvedValue(
                containerTraitCollection: sheetPresentationController.traitCollection,
                maximumDetentValue: containerView.frame.height
            )
            guard let resolvedDetentHeight,
                resolvedDetentHeight != view.frame.height - (view.safeAreaInsets.top + view.safeAreaInsets.bottom)
            else {
                return
            }

            func performTransition(animated: Bool, completion: (() -> Void)? = nil) {
                if #available(iOS 16.0, *) {
                    sheetPresentationController.invalidateDetents()
                } else {
                    sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
                }
                if animated {
                    UIView.transition(
                        with: containerView,
                        duration: 0.35,
                        options: [.beginFromCurrentState, .curveEaseInOut]
                    ) {
                        containerView.layoutIfNeeded()
                    } completion: { _ in
                        completion?()
                    }
                } else {
                    containerView.layoutIfNeeded()
                    completion?()
                }
            }

            if #available(iOS 16.0, *) {
                try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", isAnimated, view)
                performTransition(animated: isAnimated) {
                    try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", false, self.view)
                }
            } else {
                withCATransaction {
                    performTransition(animated: isAnimated)
                }
            }

        } else if tracksContentSize {
            if #available(iOS 16.0, *) {
                if presentingViewController != nil,
                    let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    popoverPresentationController.presentedViewController == self,
                    let containerView = popoverPresentationController.containerView
                {
                    var newSize = view.systemLayoutSizeFitting(
                        UIView.layoutFittingExpandedSize
                    )
                    // Arrow Height
                    switch popoverPresentationController.arrowDirection {
                    case .up, .down:
                        newSize.height += 6
                    case .left, .right:
                        newSize.width += 6
                    default:
                        break
                    }
                    let oldSize = preferredContentSize
                    if oldSize == .zero || !isAnimated {
                        preferredContentSize = newSize
                    } else if oldSize != newSize {
                        let dz = (newSize.width * newSize.height) - (oldSize.width * oldSize.height)
                        try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", isAnimated, view)
                        UIView.transition(
                            with: containerView,
                            duration: 0.35 + (dz > 0 ? 0.15 : -0.05),
                            options: [.beginFromCurrentState, .curveEaseInOut]
                        ) {
                            self.preferredContentSize = newSize
                        } completion: { _ in
                            try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", false, self.view)
                        }
                    }
                }
            } else {
                preferredContentSize = view.systemLayoutSizeFitting(
                    UIView.layoutFittingExpandedSize
                )
            }
        }
    }
}

#endif
