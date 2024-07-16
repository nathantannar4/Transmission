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
            guard tracksContentSize != oldValue else { return }
            view.setNeedsLayout()
            if tracksContentSize {
                preferredContentSize = CGRect(
                    origin: .zero,
                    size: view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
                )
                .inset(by: view.safeAreaInsets).size
            }
        }
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
                        options: [
                            .beginFromCurrentState,
                            .curveEaseInOut
                        ]
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
                allowUIKitAnimationsForNextUpdate = true
                performTransition(animated: isAnimated) {
                    self.allowUIKitAnimationsForNextUpdate = false
                }
            } else {
                withCATransaction {
                    performTransition(animated: isAnimated)
                }
            }

        } else if tracksContentSize {
            let contentSize = CGRect(
                origin: .zero,
                size: view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
            ).inset(by: view.safeAreaInsets).size
            guard preferredContentSize != contentSize else { return }
            if #available(iOS 16.0, *) {
                if presentingViewController != nil,
                    let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    popoverPresentationController.presentedViewController == self,
                    let containerView = popoverPresentationController.containerView
                {
                    let oldSize = preferredContentSize
                    if oldSize == .zero || !isAnimated {
                        preferredContentSize = contentSize
                    } else {
                        allowUIKitAnimationsForNextUpdate = isAnimated
                        UIView.transition(
                            with: containerView,
                            duration: 0.35,
                            options: [
                                .beginFromCurrentState,
                                .curveEaseInOut
                            ]
                        ) {
                            self.preferredContentSize = contentSize
                        } completion: { _ in
                            self.allowUIKitAnimationsForNextUpdate = false
                        }
                    }
                }
            } else {
                preferredContentSize = contentSize
            }
        }
    }
}

#endif
