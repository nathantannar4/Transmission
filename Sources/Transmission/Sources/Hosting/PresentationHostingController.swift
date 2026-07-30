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
            if isBeingPresented {
                didRelayoutDuringPresentation = true
            }

            func performTransition(animated: Bool, completion: (() -> Void)? = nil) {
                let changes: () -> Void = {
                    sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
                    containerView.layoutIfNeeded()
                }
                if animated {
                    if let transitionCoordinator {
                        transitionCoordinator.animate { _ in
                            changes()
                        } completion: { _ in
                            completion?()
                        }
                    } else {
                        animator?.stopAnimation(true)
                        animator = UIViewPropertyAnimator(animation: rootView.transaction.animation ?? .default)
                        animator?.addAnimations {
                            changes()
                        }
                        animator?.addCompletion { [weak self] _ in
                            completion?()
                            self?.animator = nil
                        }
                        animator?.startAnimation()
                    }
                } else {
                    changes()
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
                    if isBeingPresented {
                        didRelayoutDuringPresentation = true
                    }

                    let oldSize = preferredContentSize
                    let changes: () -> Void = { [weak self] in
                        self?.preferredContentSize = contentSize
                    }
                    if oldSize == .zero || oldSize == CGSize(width: 10_000, height: 10_000) || !isAnimated {
                        changes()
                    } else {
                        allowUIKitAnimationsForNextUpdate = isAnimated
                        if let transitionCoordinator {
                            transitionCoordinator.animate { _ in
                                changes()
                            } completion: { [weak self] _ in
                                self?.allowUIKitAnimationsForNextUpdate = false
                            }
                        } else {
                            changes()
                        }
                    }
                } else if let presentationController = presentationController as? PresentationController {
                    guard presentationController.shouldAutoLayoutPresentedView || isBeingPresented else { return }
                    let frame = presentationController.frameOfPresentedViewInContainerView
                    guard !view.frame.size.isApproximatelyEqual(to: frame.size) else { return }
                    if isBeingPresented {
                        didRelayoutDuringPresentation = true
                    }
                    let changes: () -> Void = {
                        presentationController.layoutPresentedView(frame: frame)
                    }
                    if isAnimated {
                        self.allowUIKitAnimationsForNextUpdate = true
                        let completion: () -> Void = { [weak self] in
                            self?.allowUIKitAnimationsForNextUpdate = false
                        }
                        if let transitionCoordinator {
                            transitionCoordinator.animate { _ in
                                changes()
                            } completion: { _ in
                                completion()
                            }
                        } else {
                            animator?.stopAnimation(true)
                            animator = UIViewPropertyAnimator(animation: rootView.transaction.animation ?? .default)
                            animator?.addAnimations {
                                changes()
                            }
                            animator?.addCompletion { [weak self] _ in
                                completion()
                                self?.animator = nil
                            }
                            animator?.startAnimation()
                        }
                    } else {
                        changes()
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
}

#endif
