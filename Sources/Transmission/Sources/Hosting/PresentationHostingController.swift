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
        }
    }

    private func getPresentationController() -> UIPresentationController? {
        var parent = parent
        while let next = parent?.parent {
            parent = next
        }
        return (parent ?? self)._activePresentationController
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

        let isAnimated = transitionCoordinator?.isAnimated ?? true

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
            guard let resolvedDetentHeight, abs(resolvedDetentHeight - height) > 1e-5 else {
                return
            }
            let isAnimated = isAnimated && !isBeingPresented

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
                performTransition(animated: isAnimated) { [weak self] in
                    self?.allowUIKitAnimationsForNextUpdate = false
                }
            } else {
                withCATransaction {
                    performTransition(animated: isAnimated)
                }
            }

        } else if tracksContentSize {
            if #available(iOS 16.0, *), presentingViewController != nil {
                let presentationController = getPresentationController()
                if let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    popoverPresentationController.presentedViewController == self,
                    let containerView = popoverPresentationController.containerView
                {
                    let contentSize = CGRect(origin: .zero, size: view.idealSize).inset(by: view.safeAreaInsets).size
                    guard preferredContentSize != contentSize else { return }

                    let isAnimated = isAnimated && !isBeingPresented
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
                        ) { [weak self] in
                            self?.preferredContentSize = contentSize
                        } completion: { [weak self] _ in
                            self?.allowUIKitAnimationsForNextUpdate = false
                        }
                    }
                } else if let presentationController = presentationController as? PresentationController {
                    guard presentationController.shouldAutoLayoutPresentedView else { return }
                    if let interactivePresentationController = presentationController as? InteractivePresentationController {
                        guard interactivePresentationController.panGesture.state != .changed else { return }
                    }
                    let frame = presentationController.frameOfPresentedViewInContainerView
                    guard !view.frame.size.isApproximatelyEqual(to: frame.size) else { return }
                    if isAnimated {
                        self.allowUIKitAnimationsForNextUpdate = true
                        if let transitionCoordinator {
                            transitionCoordinator.animate { _ in
                                presentationController.layoutPresentedView(frame: frame)
                            } completion: { [weak self] _ in
                                self?.allowUIKitAnimationsForNextUpdate = false
                            }
                        } else {
                            UIView.animate(
                                withDuration: 0.35,
                                delay: 0,
                                options: [
                                    .beginFromCurrentState,
                                    .curveEaseInOut
                                ]
                            ) {
                                presentationController.layoutPresentedView(frame: frame)
                            } completion: { [weak self] _ in
                                self?.allowUIKitAnimationsForNextUpdate = false
                            }
                        }
                    } else {
                        presentationController.layoutPresentedView(frame: frame)
                    }
                } else {
                    let contentSize = CGRect(origin: .zero, size: view.idealSize).inset(by: view.safeAreaInsets).size
                    preferredContentSize = contentSize
                }
            } else {
                let contentSize = CGRect(origin: .zero, size: view.idealSize).inset(by: view.safeAreaInsets).size
                preferredContentSize = contentSize
            }
        }
    }
}

#endif
