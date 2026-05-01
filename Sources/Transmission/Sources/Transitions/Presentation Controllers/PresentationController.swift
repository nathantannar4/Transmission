//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller base class
@available(iOS 14.0, *)
open class PresentationController: DelegatedPresentationController, PercentDrivenInteractivePresentationController {

    public var isTransitioningSize: Bool {
        sizeTransitionCoordinator != nil
    }
    private weak var sizeTransitionCoordinator: UIViewControllerTransitionCoordinator?

    public private(set) var isTransitioningKeyboard = false
    public private(set) var keyboardHeight: CGFloat = 0

    public let dimmingView: DimmingView = {
        let view = DimmingView()
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    public class ShadowView: UIView {
        public weak var preferredSourceView: UIView?
    }
    public let shadowView = ShadowView()

    open var shouldAutoLayoutPresentedView: Bool {
        if isTransitioningKeyboard {
            return true
        }
        return transition == nil
            && !isTransitioningSize
            && !presentedViewController.isBeingPresented
            && !presentedViewController.isBeingDismissed
    }

    /// The interactive transition driving the presentation or dismissal animation
    public weak var transition: UIPercentDrivenInteractiveTransition?

    open var wantsInteractiveTransition: Bool {
        return false
    }

    public var shouldIgnoreContainerViewTouches: Bool {
        get { containerView?.value(forKey: "ignoreDirectTouchEvents") as? Bool ?? false }
        set { containerView?.setValue(newValue, forKey: "ignoreDirectTouchEvents") }
    }

    public var presentedViewShadow: ShadowOptions = .clear {
        didSet {
            guard !presentedViewController.isBeingPresented, !presentedViewController.isBeingDismissed else { return }
            updateShadow(progress: 1)
        }
    }

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    open func preferredDefaultAnimation() -> Animation? {
        return nil
    }

    open func attach(to transition: UIPercentDrivenInteractiveTransition) {
        if let transition = transition as? ViewControllerTransition {
            if transition.animation == .default, let preferredDefaultAnimation = preferredDefaultAnimation() {
                transition.animation = preferredDefaultAnimation
            }
        }
        transition.wantsInteractiveStart = transition.wantsInteractiveStart && wantsInteractiveTransition
        self.transition = transition
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        shouldIgnoreContainerViewTouches = true

        containerView?.addSubview(dimmingView)
        dimmingView.frame = containerView?.bounds ?? .zero
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectBackground))
        )
        shadowView.isUserInteractionEnabled = false
        containerView?.addSubview(shadowView)
        if let presentedView {
            containerView?.addSubview(presentedView)
        }
        updateShadow(progress: 0)

        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(onKeyboardChange(_:)),
                name: UIResponder.keyboardWillChangeFrameNotification,
                object: nil
            )

        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(onKeyboardChange(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated {
            transitionCoordinator.animate { _ in
                self.transitionAlongsidePresentation(progress: 1)
            }
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            transitionAlongsidePresentation(progress: 1)
        } else {
            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillChangeFrameNotification,
                    object: nil
                )

            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )

            transitionAlongsidePresentation(progress: 0)
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        dimmingView.isUserInteractionEnabled = false
        updateShadow(progress: 1)

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated {
            transitionCoordinator.animate { _ in
                self.transitionAlongsidePresentation(progress: 0)
            }
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            transitionAlongsidePresentation(progress: 0)

            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillChangeFrameNotification,
                    object: nil
                )

            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )
        } else {
            dimmingView.isUserInteractionEnabled = true
            transitionAlongsidePresentation(progress: 1)
        }
    }

    open func transitionAlongsidePresentation(progress: CGFloat) {
        dimmingView.alpha = progress
        layoutBackgroundViews()
        updateShadow(progress: progress)
    }

    open func transitionAlongsideRotation() {
        let frame = frameOfPresentedViewInContainerView
        layoutPresentedView(frame: frame)
    }

    open func updateShadow(progress: Double) {
        if presentedViewShadow == .clear {
            shadowView.isHidden = true
        } else {
            shadowView.isHidden = false
            var shadow = presentedViewShadow
            shadow.shadowOpacity *= Float(progress)
            shadow.apply(to: shadowView.layer)
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if shouldAutoLayoutPresentedView {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
        }
    }

    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        sizeTransitionCoordinator = coordinator
        super.viewWillTransition(to: size, with: coordinator)
        if keyboardHeight > 0 {
            keyboardHeight = size.height / 2
        }
        coordinator.animateAlongsideTransition(in: containerView) { _ in
            self.transitionAlongsideRotation()
        } completion: { _ in
            self.sizeTransitionCoordinator = nil
        }
    }

    open func layoutPresentedView(frame: CGRect) {
        presentedView?.setFramePreservingTransform(frame)
        presentedView?.layoutIfNeeded()
        layoutBackgroundViews()
    }

    open func layoutBackgroundViews() {
        layoutDimmingView()
        layoutShadowView()
    }

    open func layoutDimmingView() {
        if !(presentedViewController.view.backgroundColor?.isTranslucent ?? true),
            let presentationController = presentingViewController._activePresentationController
        {
            let frame = presentationController.presentedView?.frame ?? presentationController.frameOfPresentedViewInContainerView
            let dimmingViewFrame = presentingViewController.view.convert(
                presentingViewController.view.convert(
                    frame,
                    from: presentationController.containerView
                ),
                to: containerView
            )
            dimmingView.frame = dimmingViewFrame.rounded(scale: containerView?.window?.screen.scale ?? 1)
            if let presentedView = presentationController.presentedView ?? presentationController.presentedViewController.view {
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *) {
                    dimmingView.cornerConfiguration = presentedView.cornerConfiguration
                }
                #endif
                dimmingView.layer.cornerRadius = presentedView.layer.cornerRadius
                dimmingView.layer.cornerCurve = presentedView.layer.cornerCurve
                dimmingView.layer.maskedCorners = presentedView.layer.maskedCorners
            }
        } else {
            dimmingView.frame = containerView?.bounds ?? .zero
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                dimmingView.cornerConfiguration = .corners(topLeftRadius: nil, topRightRadius: nil, bottomLeftRadius: nil, bottomRightRadius: nil)
            }
            #endif
            dimmingView.layer.cornerRadius = 0
            dimmingView.layer.cornerCurve = .circular
            dimmingView.layer.maskedCorners = .all
        }
    }

    open func layoutShadowView() {
        guard let sourceView = shadowView.preferredSourceView ?? presentedView else { return }
        guard !shadowView.isHidden else { return }
        shadowView.transform = sourceView.transform
        shadowView.bounds = sourceView.bounds
        shadowView.center = sourceView.center
        shadowView.layer.shadowPath = CGPath(
            roundedRect: sourceView.bounds,
            cornerWidth: sourceView.layer.cornerRadius,
            cornerHeight: sourceView.layer.cornerRadius,
            transform: nil
        )
    }

    open func keyboardHeightDidChange() {
    }

    open func keyboardOverlapInContainerView(
        of frame: CGRect,
        keyboardHeight: CGFloat
    ) -> CGFloat {
        guard let containerView else { return 0 }
        let maxHeight = isTransitioningSize ? containerView.frame.width : containerView.frame.height
        let dy = min(0, maxHeight - (isTransitioningSize ? frame.maxX : frame.maxY)) - keyboardHeight
        if dy < 0 {
            return abs(dy)
        }
        return 0
    }

    @objc
    private func onKeyboardChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool != false
        else {
            return
        }

        let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let dy = notification.name == UIResponder.keyboardWillHideNotification ? 0 : (endFrame?.size.height ?? 0)

        guard keyboardHeight != dy, !(isTransitioningSize && dy == 0) else { return }
        keyboardHeight = dy
        isTransitioningKeyboard = true
        guard shouldAutoLayoutPresentedView, let containerView else {
            keyboardHeightDidChange()
            isTransitioningKeyboard = false
            return
        }
        containerView.setNeedsLayout()

        guard
            let duration = sizeTransitionCoordinator?.transitionDuration ?? userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            duration > 0,
            let curve = sizeTransitionCoordinator?.completionCurve.rawValue ?? userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        else {
            keyboardHeightDidChange()
            containerView.layoutIfNeeded()
            isTransitioningKeyboard = false
            return
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [
                UIView.AnimationOptions(curve: curve),
                .beginFromCurrentState,
            ]
        ) {
            self.keyboardHeightDidChange()
            containerView.layoutIfNeeded()
        } completion: { _ in
            self.isTransitioningKeyboard = false
        }
    }

    @objc
    private func didSelectBackground() {
        if presentedViewController.isBeingPresented {
            if let transition {
                let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
                if shouldDismiss {
                    delegate?.presentationControllerWillDismiss?(self)
                    transition.pause()
                    transition.cancel()
                    self.transition = nil
                    dimmingView.isUserInteractionEnabled = false
                }
            }
        } else if let next = presentedViewController.presentedViewController,
            let presentationController = next._activePresentationController as? PresentationController
        {
            presentationController.didSelectBackground()
        } else {
            let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
            if shouldDismiss {
                presentedViewController.dismiss(animated: true)
            }
        }
    }
}

#endif
