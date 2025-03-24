    //
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

open class PresentationHostingController<
    Content: View
>: HostingController<Content> {

    public var tracksContentSize: Bool = false {
        didSet {
            guard tracksContentSize != oldValue else { return }
            view.setNeedsLayout()
            if tracksContentSize {
                preferredContentSize = CGRect(origin: .zero, size: view.idealSize).inset(by: view.safeAreaInsets).size
            } else {
                preferredContentSize = .zero
            }
        }
    }

    private func getPresentationController() -> UIPresentationController? {
        var parent = parent
        while let next = parent?.parent {
            parent = next
        }
        return (parent ?? self).presentationController
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard view.superview != nil, !isBeingDismissed else {
            return
        }

        let isAnimated = isBeingPresented ? false : transitionCoordinator?.isAnimated ?? true

        if tracksContentSize, #available(iOS 15.0, *),
            presentingViewController != nil,
            let sheetPresentationController = getPresentationController() as? UISheetPresentationController,
            let presentedView = sheetPresentationController.presentedView,
            let containerView = sheetPresentationController.containerView
        {
            guard
                let selectedIdentifier = sheetPresentationController.selectedDetentIdentifier,
                let detent = sheetPresentationController.detents.first(where: { $0.id == selectedIdentifier.rawValue && $0.isDynamic })
            else {
                return
            }

            let panGesture = presentedView.gestureRecognizers?.first(where: { $0.isSheetDismissPanGesture })
            guard panGesture == nil || panGesture?.state == .possible || panGesture?.state == .failed else {
                return
            }

            // This seems to match the `maximumDetentValue` computed by UIKit
            let maximumDetentValue = containerView.frame.inset(by: containerView.safeAreaInsets).height - 10
            let resolvedDetentHeight = detent.resolvedValue(
                containerTraitCollection: sheetPresentationController.traitCollection,
                maximumDetentValue: maximumDetentValue
            )
            let height = presentedView.frame.height - (presentedView.safeAreaInsets.top + presentedView.safeAreaInsets.bottom)
            guard let resolvedDetentHeight, resolvedDetentHeight != height else {
                return
            }

            func performTransition(animated: Bool, completion: (() -> Void)? = nil) {
                if #available(iOS 16.0, *) {
                    sheetPresentationController.invalidateDetents()
                } else {
                    sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
                }
                if animated {
                    let duration = transitionCoordinator?.transitionDuration ?? 0.35
                    let curve = transitionCoordinator?.completionCurve ?? .easeInOut
                    UIView.transition(
                        with: containerView,
                        duration: duration,
                        options: [
                            .beginFromCurrentState,
                            UIView.AnimationOptions(rawValue: UInt(curve.rawValue << 16))
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
            let contentSize = CGRect(origin: .zero, size: view.idealSize).inset(by: view.safeAreaInsets).size
            guard preferredContentSize != contentSize else { return }
            if #available(iOS 16.0, *), presentingViewController != nil {
                let presentationController = getPresentationController()
                if let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    popoverPresentationController.presentedViewController == self,
                    let containerView = popoverPresentationController.containerView
                {
                    let oldSize = preferredContentSize
                    if oldSize == .zero || oldSize == CGSize(width: 10_000, height: 10_000) || !isAnimated {
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
                } else if let presentationController = presentationController as? PresentationController {
                    preferredContentSize = contentSize
                    let frame = presentationController.frameOfPresentedViewInContainerView
                    if isAnimated {
                        self.allowUIKitAnimationsForNextUpdate = true
                        UIView.animate(
                            withDuration: 0.35,
                            delay: 0,
                            options: [
                                .beginFromCurrentState,
                                .curveEaseInOut
                            ]
                        ) {
                            presentationController.layoutPresentedView(frame: frame)
                            presentationController.containerView?.layoutIfNeeded()
                        } completion: { _ in
                            self.allowUIKitAnimationsForNextUpdate = false
                        }
                    } else {
                        presentationController.layoutPresentedView(frame: frame)
                    }
                } else {
                    preferredContentSize = contentSize
                }
            } else {
                preferredContentSize = contentSize
            }
        }
    }
}

#endif
