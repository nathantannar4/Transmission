//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 14.0, *)
open class PresentationController: UIPresentationController {

    public private(set) var isTransitioningSize = false
    public private(set) var keyboardHeight: CGFloat = 0

    open var shouldAutoLayoutPresentedView: Bool {
        !isTransitioningSize
            && presentedView?.transform == .identity
            && !presentedViewController.isBeingPresented
            && !presentedViewController.isBeingDismissed
    }

    open var shouldAutomaticallyAdjustFrameForKeyboard: Bool = true {
        didSet {
            guard oldValue != shouldAutomaticallyAdjustFrameForKeyboard else { return }
            containerView?.setNeedsLayout()
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        let frame = super.frameOfPresentedViewInContainerView
        if shouldAutomaticallyAdjustFrameForKeyboard, keyboardHeight > 0 {
            let dy = keyboardOverlapInContainerView(of: frame)
            return CGRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: frame.size.width,
                height: frame.size.height - dy
            )
        }
        return frame
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate { _ in
                self.transitionAlongsidePresentation(isPresented: true)
            }
        } else {
            transitionAlongsidePresentation(isPresented: true)
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
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
        } else {
            transitionAlongsidePresentation(isPresented: false)
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        delegate?.presentationControllerWillDismiss?(self)

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate { _ in
                self.transitionAlongsidePresentation(isPresented: false)
            }
        } else {
            transitionAlongsidePresentation(isPresented: false)
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            delegate?.presentationControllerDidDismiss?(self)

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
            transitionAlongsidePresentation(isPresented: true)
            delegate?.presentationControllerDidAttemptToDismiss?(self)
        }
    }

    open func transitionAlongsidePresentation(isPresented: Bool) {

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
        isTransitioningSize = true
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: containerView) { _ in
            let frame = self.frameOfPresentedViewInContainerView
            self.layoutPresentedView(frame: frame)
        } completion: { _ in
            self.isTransitioningSize = false
        }
    }

    open func layoutPresentedView(frame: CGRect) {
        presentedView?.frame = frame
    }

    open func keyboardOverlapInContainerView(of frame: CGRect) -> CGFloat {
        guard let containerView, !isTransitioningSize else { return 0 }
        let maxHeight = containerView.frame.height
        let dy = maxHeight - keyboardHeight - frame.maxY
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

        guard keyboardHeight != dy else { return }
        keyboardHeight = dy
        guard shouldAutoLayoutPresentedView else { return }
        containerView?.setNeedsLayout()

        guard
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            containerView?.layoutIfNeeded()
            return
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [
                .init(rawValue: curve << 16),
                .beginFromCurrentState,
            ]
        ) { [weak self] in
            self?.containerView?.layoutIfNeeded()
        }
    }
}

#endif
