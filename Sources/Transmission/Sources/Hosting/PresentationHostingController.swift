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

    public weak var sourceViewController: AnyHostingController?

    private func getPresentationController() -> UIPresentationController? {
        var ancestor = parent ?? self
        while let parent = ancestor.parent {
            ancestor = parent
        }
        return ancestor._activePresentationController
    }

    private var didRelayoutDuringPresentation = false

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
    }

    open override func viewDidLayoutSubviews() {
        var isAnimated = transaction?.isAnimated ?? false

        super.viewDidLayoutSubviews()

        if let sourceViewController, sourceViewController.shouldRenderForContentUpdate {
            // Render so the modifier that controls the presentation of this hosting controller
            // can run and update.
            sourceViewController.render()
        }

        guard view.superview != nil, !isBeingDismissed else {
            return
        }

        if isBeingPresented, didRelayoutDuringPresentation, !tracksContentSize || (tracksContentSize && preferredContentSize != .zero) {
            return
        }

        isAnimated = !isBeingPresented && (isAnimated || transitionCoordinator?.isAnimated ?? true)

        if tracksContentSize, #available(iOS 15.0, *),
            presentingViewController != nil,
            let sheetPresentationController = getPresentationController() as? UISheetPresentationController,
            sheetPresentationController.presentedViewController == self,
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
            guard
                panGesture == nil || (panGesture?.isInteracting == false && panGesture?.state != .ended),
                let maximumDetentValue = sheetPresentationController.maximumDetentValue
            else {
                return
            }

            let resolvedDetentHeight = detent.resolvedValue(
                containerTraitCollection: sheetPresentationController.traitCollection,
                maximumDetentValue: maximumDetentValue
            )
            let height = view.frame.height - (view.safeAreaInsets.top + view.safeAreaInsets.bottom)
            guard let resolvedDetentHeight, abs(resolvedDetentHeight - height) > 1e-5 else {
                return
            }
            didRelayoutDuringPresentation = true

            func performTransition(animated: Bool, completion: (() -> Void)? = nil) {
                if animated {
                    let duration = transitionCoordinator?.transitionDuration ?? 0.35
                    let curve = transitionCoordinator?.completionCurve ?? .easeInOut
                    UIView.transition(
                        with: containerView,
                        duration: duration,
                        options: [
                            .beginFromCurrentState,
                            UIView.AnimationOptions(rawValue: UInt(curve.rawValue << 16)),
                        ]
                    ) {
                        sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
                        containerView.layoutIfNeeded()
                    } completion: { _ in
                        completion?()
                    }
                } else {
                    sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
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
                    let contentSize = CGRect(
                        origin: .zero,
                        size: view.preferredContentSize(for: containerView.bounds.width + (popoverPresentationController.popoverLayoutMargins.left + popoverPresentationController.popoverLayoutMargins.right))
                    ).inset(by: view.safeAreaInsets).size
                    guard !preferredContentSize.isApproximatelyEqual(to: contentSize) else { return }
                    didRelayoutDuringPresentation = true

                    let oldSize = preferredContentSize
                    if oldSize == .zero || oldSize == CGSize(width: 10_000, height: 10_000) || !isAnimated {
                        UIView.performWithoutAnimation {
                            self.preferredContentSize = contentSize
                        }
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
                    let frame = presentationController.frameOfPresentedViewInContainerView
                    guard !view.frame.size.isApproximatelyEqual(to: frame.size) else { return }
                    didRelayoutDuringPresentation = true
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
                } else if let containerView = presentationController?.containerView {
                    let contentSize = CGRect(origin: .zero, size: view.preferredContentSize(for: containerView.bounds.width)).inset(by: view.safeAreaInsets).size
                    preferredContentSize = contentSize
                } else {
                    let contentSize = CGRect(origin: .zero, size: view.intrinsicContentSize).inset(by: view.safeAreaInsets).size
                    preferredContentSize = contentSize
                }
            } else {
                let contentSize = CGRect(origin: .zero, size: view.intrinsicContentSize).inset(by: view.safeAreaInsets).size
                preferredContentSize = contentSize
            }
        }
    }
}

#endif
