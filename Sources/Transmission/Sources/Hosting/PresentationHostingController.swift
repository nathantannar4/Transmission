    //
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
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

    private var didRelayoutDuringPresentation = false
    private var animator: UIViewPropertyAnimator?

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let sourceViewController, sourceViewController.shouldRenderForContentUpdate {
            // Render so the modifier that controls the presentation of this hosting controller
            // can run and update.
            withCATransaction { [weak sourceViewController] in
                sourceViewController?.render()
            }
        }

        if !isBeingDismissed {
            didRelayoutDuringPresentation = false
        }

        guard view.superview != nil, !isBeingDismissed else {
            return
        }

        if isBeingPresented, didRelayoutDuringPresentation, !tracksContentSize || (tracksContentSize && preferredContentSize != .zero) {
            return
        }

        let isAnimated = (!isBeingPresented || transitionCoordinator?.isAnimated == true) && rootView.transaction.isAnimated

        if tracksContentSize, #available(iOS 15.0, *),
            presentingViewController != nil,
            let sheetPresentationController = _presentationController as? UISheetPresentationController,
            sheetPresentationController.presentedViewController == self,
            let presentedView = sheetPresentationController.presentedView,
            let containerView = sheetPresentationController.containerView
        {
            if isBeingPresented, didRelayoutDuringPresentation, tracksContentSize {
                return
            }

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
            let height = view.frame.height - (disableSafeArea ? containerView.safeAreaInsets.bottom : view.safeAreaInsets.bottom)
            guard let resolvedDetentHeight, abs(resolvedDetentHeight - height) > 1e-5 else {
                return
            }
            if #available(iOS 16.0, *) {
                layoutIntrinsicContentSizeChange(
                    isAnimated: isAnimated,
                    sheetPresentationController: sheetPresentationController
                )
            } else {
                withCATransaction { [weak self, weak sheetPresentationController] in
                    guard let self, let sheetPresentationController else { return }
                    layoutIntrinsicContentSizeChange(
                        isAnimated: isAnimated,
                        sheetPresentationController: sheetPresentationController
                    )
                }
            }

        } else if tracksContentSize {
            if #available(iOS 16.0, *), presentingViewController != nil {
                let presentationController = _presentationController
                if let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    popoverPresentationController.presentedViewController == self,
                    let containerView = popoverPresentationController.containerView
                {
                    let contentSize = CGRect(
                        origin: .zero,
                        size: view.preferredContentSize(for: containerView.bounds.width)
                    ).inset(by: view.safeAreaInsets).size
                    guard !preferredContentSize.isApproximatelyEqual(to: contentSize) else { return }

                    let oldSize = preferredContentSize
                    let changes: @MainActor () -> Void = { [weak self] in
                        self?.preferredContentSize = contentSize
                    }
                    if oldSize == .zero || oldSize == CGSize(width: 10_000, height: 10_000) || !isAnimated {
                        changes()
                    } else {
                        layoutIntrinsicContentSizeChange(
                            isAnimated: isAnimated,
                            changes: changes
                        )
                        allowUIKitAnimationsForNextUpdate = isAnimated
                    }
                } else if let presentationController = presentationController as? PresentationController {
                    guard presentationController.shouldAutoLayoutPresentedView || isBeingPresented else { return }
                    let frame = presentationController.frameOfPresentedViewInContainerView
                    guard !view.frame.size.isApproximatelyEqual(to: frame.size) else { return }
                    layoutIntrinsicContentSizeChange(
                        isAnimated: isAnimated
                    ) {
                        presentationController.layoutPresentedView(frame: frame)
                    }
                } else if let containerView = presentationController?.containerView {
                    let contentSize = CGRect(
                        origin: .zero,
                        size: view.preferredContentSize(for: containerView.bounds.inset(by: containerView.layoutMargins).width)
                    ).inset(by: view.safeAreaInsets).size
                    preferredContentSize = contentSize
                } else {
                    let contentSize = CGRect(
                        origin: .zero,
                        size: view.intrinsicContentSize
                    ).inset(by: view.safeAreaInsets).size
                    preferredContentSize = contentSize
                }
            } else {
                let contentSize = CGRect(
                    origin: .zero,
                    size: view.intrinsicContentSize
                ).inset(by: view.safeAreaInsets).size
                preferredContentSize = contentSize
            }
        }
    }

    @available(iOS 15.0, *)
    private func layoutIntrinsicContentSizeChange(
        isAnimated: Bool,
        sheetPresentationController: UISheetPresentationController
    ) {
        layoutIntrinsicContentSizeChange(isAnimated: isAnimated) {
            sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
            sheetPresentationController.containerView?.layoutIfNeeded()
        }
    }

    private func layoutIntrinsicContentSizeChange(
        isAnimated: Bool,
        changes: @MainActor @escaping () -> Void
    ) {
        if isBeingPresented {
            didRelayoutDuringPresentation = true
        }
        if #available(iOS 18.1, *) {
            allowUIKitAnimations += 1
        } else if #available(iOS 16.0, *) {
            allowUIKitAnimationsForNextUpdate = isAnimated
        }
        let completion: () -> Void = { [weak self] in
            if #unavailable(iOS 18.1) {
                if #available(iOS 16.0, *) {
                    self?.allowUIKitAnimationsForNextUpdate = false
                }
            }
        }
        animator?.stopAnimation(true)
        if isAnimated {
            if let transitionCoordinator {
                transitionCoordinator.animate { _ in
                    changes()
                } completion: { _ in
                    completion()
                }
            } else {
                animator = UIViewPropertyAnimator(animation: rootView.transaction.animation ?? .default)
                animator?.addAnimations {
                    changes()
                }
                animator?.addCompletion { _ in
                    completion()
                }
                animator?.startAnimation()
            }
        } else {
            changes()
            completion()
        }
    }

    open override func accessibilityPerformEscape() -> Bool {
        var canDismiss = !isModalInPresentation
        if canDismiss, let presentationController = _presentationController {
            if let shouldDismiss = presentationController.delegate?.presentationControllerShouldDismiss?(presentationController) {
                canDismiss = shouldDismiss
            }
        }
        if canDismiss {
            dismiss(animated: true)
            return true
        }
        return super.accessibilityPerformEscape()
    }
}

#endif
