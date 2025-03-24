//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

/// A presentation controller base class
@available(iOS 14.0, *)
open class PresentationController: UIPresentationController {

    public private(set) var isTransitioningSize = false
    public private(set) var keyboardHeight: CGFloat = 0

    public let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    public class ShadowView: UIView {
        public weak var preferredSourceView: UIView?
    }
    public let shadowView = ShadowView()

    open var shouldAutoLayoutPresentedView: Bool {
        !isTransitioningSize
            && !presentedViewController.isBeingPresented
            && !presentedViewController.isBeingDismissed
    }

    public var shouldIgnoreContainerViewTouches: Bool {
        get { containerView?.value(forKey: "ignoreDirectTouchEvents") as? Bool ?? false }
        set { containerView?.setValue(true, forKey: "ignoreDirectTouchEvents") }
    }

    public var shouldAutomaticallyAdjustFrameForKeyboard: Bool = false {
        didSet {
            guard oldValue != shouldAutomaticallyAdjustFrameForKeyboard else { return }
            containerView?.setNeedsLayout()
        }
    }

    public var presentedViewShadow: PresentationLinkTransition.Shadow = .clear {
        didSet {
            guard presentedViewController.isBeingPresented, presentedViewController.isBeingDismissed else { return }
            updateShadow(progress: 1)
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        let frame = super.frameOfPresentedViewInContainerView
        if shouldAutomaticallyAdjustFrameForKeyboard, keyboardHeight > 0 {
            let dy = keyboardOverlapInContainerView(
                of: frame,
                keyboardHeight: keyboardHeight
            )
            return CGRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: frame.size.width,
                height: frame.size.height - dy
            )
        }
        return frame
    }

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        shouldIgnoreContainerViewTouches = true

        containerView?.addSubview(dimmingView)
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectBackground))
        )
        containerView?.addSubview(shadowView)
        updateShadow(progress: 0)

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
            updateShadow(progress: 1)

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
        updateShadow(progress: 1)

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
            updateShadow(progress: 0)
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
        dimmingView.alpha = isPresented ? 1 : 0
        layoutShadowView()
        updateShadow(progress: isPresented ? 1 : 0)
    }

    open func updateShadow(progress: Double) {
        if presentedViewShadow == .clear {
            shadowView.isHidden = true
        } else {
            shadowView.isHidden = false
            presentedViewShadow.apply(to: shadowView, progress: progress)
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        if shouldAutoLayoutPresentedView {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
        } else {
            layoutShadowView()
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
        guard let presentedView else { return }
        // Set frame preserving transform
        let anchor = presentedView.layer.anchorPoint
        presentedView.bounds = CGRect(origin: .zero, size: frame.size)
        presentedView.center = CGPoint(
            x: frame.minX + (frame.width * anchor.x),
            y: frame.minY + (frame.height * anchor.y)
        )
        layoutShadowView()
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

    open func keyboardOverlapInContainerView(
        of frame: CGRect,
        keyboardHeight: CGFloat
    ) -> CGFloat {
        guard let containerView else { return 0 }
        let maxHeight = isTransitioningSize ? containerView.frame.width : containerView.frame.height
        let dy = maxHeight - keyboardHeight - (isTransitioningSize ? frame.maxX : frame.maxY)
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
        guard shouldAutoLayoutPresentedView, let containerView else { return }
        containerView.setNeedsLayout()

        guard
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            duration > 0,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            containerView.layoutIfNeeded()
            return
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [
                .init(rawValue: curve << 16),
                .beginFromCurrentState,
            ]
        ) {
            containerView.layoutIfNeeded()
        }
    }

    @objc
    private func didSelectBackground() {
        let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
        if shouldDismiss {
            presentedViewController.dismiss(animated: true)
        }
    }
}

#endif
