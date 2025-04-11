//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

/// An interactive based presentation controller base class
@available(iOS 14.0, *)
open class InteractivePresentationController: PresentationController, UIGestureRecognizerDelegate {

    /// The edges the presented view can be interactively dismissed towards.
    open var edges: Edge.Set = [.bottom]

    public private(set) weak var transition: UIPercentDrivenInteractiveTransition?
    public private(set) lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
    private weak var trackingScrollView: UIScrollView?

    private var translationOffset: CGPoint = .zero
    private var lastTranslation: CGPoint = .zero
    var keyboardOffset: CGFloat = 0

    /// When true, custom view controller presentation animators should be set to want an interactive start
    open var wantsInteractiveTransition: Bool {
        func isInteracting(gesture: UIGestureRecognizer?) -> Bool {
            guard let gesture else { return false }
            let isInteracting = gesture.state == .began || gesture.state == .changed
            return isInteracting
        }
        return isInteracting(gesture: trackingScrollView?.panGestureRecognizer) || isInteracting(gesture: panGesture)
    }

    /// When true, dismissal of the presented view controller will be deferred until the pan gesture ends
    open var wantsInteractiveDismissal: Bool {
        if keyboardOffset > 0 {
            return true
        }
        if prefersInteractiveDismissal {
            return true
        }
        return false
    }

    public var prefersInteractiveDismissal: Bool = false

    open override var shouldAutoLayoutPresentedView: Bool {
        transition == nil && panGesture.state == .possible && super.shouldAutoLayoutPresentedView
    }

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    /// Links an interactive transition to the pan gesture of the presentation controller
    public func transition(with transition: UIPercentDrivenInteractiveTransition) {
        self.transition = transition
    }

    open func preferredDefaultAnimation() -> Animation? {
        guard panGesture.state == .ended else { return nil }
        let velocity = panGesture.velocity(in: panGesture.view)
        let initialVelocity = min(abs(velocity.y) / presentedViewController.view.frame.height, 1)
        return Animation.interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: initialVelocity)
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        presentedViewController.additionalSafeAreaInsets = presentedViewAdditionalSafeAreaInsets()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            panGesture.delegate = self
            panGesture.allowedScrollTypesMask = .all
            presentedView?.addGestureRecognizer(panGesture)
        }
    }

    open func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        if edges.contains(.bottom), translation.y > 0 {
            return abs(delta.y) >= abs(delta.x)
        }
        if edges.contains(.top), translation.y < 0 {
            return abs(delta.y) >= abs(delta.x)
        }
        if edges.contains(.leading), translation.x < 0 {
            return abs(delta.x) >= abs(delta.y)
        }
        if edges.contains(.trailing), translation.x > 0 {
            return abs(delta.x) >= abs(delta.y)
        }
        return false
    }

    open func dismissalTransitionShouldCancel(
        translation: CGPoint,
        delta: CGPoint
    ) -> Bool {
        if edges.contains(.bottom), translation.y >= 0 {
            return false
        }
        if edges.contains(.top), translation.y <= 0 {
            return false
        }
        if edges.contains(.leading), translation.x <= 0 {
            return false
        }
        if edges.contains(.trailing), translation.x >= 0 {
            return false
        }
        return true
    }

    open func dismissalTransitionDidCancel() {

    }

    open func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        if wantsInteractiveDismissal, translation.y >= 0 {
            return CGAffineTransform(translationX: 0, y: translation.y)
        }
        let dy = frictionCurve(translation.y)
        return CGAffineTransform(translationX: 0, y: dy)
    }

    open func transformPresentedView(transform: CGAffineTransform) {
        let scale = presentedViewController.view.window?.screen.scale ?? 1
        var frame = frameOfPresentedViewInContainerView.applying(transform)
        frame.origin.y -= keyboardOffset
        frame.origin.x = frame.origin.x.rounded(scale: scale)
        frame.origin.y = frame.origin.y.rounded(scale: scale)
        frame.size.width = frame.size.width.rounded(scale: scale)
        frame.size.height = frame.size.height.rounded(scale: scale)
        layoutPresentedView(frame: frame)
    }

    open func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        // SwiftUI automatically reduces safe area during a view transform,
        // which causes layout changes. Add back the difference so it stays
        // consistent.
        guard let presentedView, presentedView.frame != .zero else { return .zero }
        let frameOfPresentedViewInContainerView = frameOfPresentedViewInContainerView
        let frame = presentedViewController.view.frame
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        let dyTop = frame.origin.y - frameOfPresentedViewInContainerView.origin.y
        let dyBottom = -dyTop + frameOfPresentedViewInContainerView.size.height - frame.size.height
        let overlapsTopSafeArea = frameOfPresentedViewInContainerView.origin.y <= safeAreaInsets.top
        let overlapsBottomSafeArea = (containerView?.frame.height ?? 0) - frameOfPresentedViewInContainerView.maxY <= safeAreaInsets.bottom
        let additionalSafeAreaInsets = UIEdgeInsets(
            top: overlapsTopSafeArea ? max(0, min(dyTop, safeAreaInsets.top)) : 0,
            left: 0,
            bottom: overlapsBottomSafeArea ? max(0, min(dyBottom, safeAreaInsets.bottom)) : 0,
            right: 0
        )
        return additionalSafeAreaInsets
    }

    open override func layoutPresentedView(frame: CGRect) {
        super.layoutPresentedView(frame: frame)
        presentedViewController.additionalSafeAreaInsets = presentedViewAdditionalSafeAreaInsets()
    }

    @objc
    private func didTapBackground() {
        let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
        if shouldDismiss {
            presentedViewController.dismiss(animated: true)
        }
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let presentedView else { return }
        let scrollView = gestureRecognizer.view as? UIScrollView ?? trackingScrollView
        let gestureTranslation = gestureRecognizer.translation(in: presentedView)
        let delta = CGPoint(
            x: gestureTranslation.x - lastTranslation.x,
            y: gestureTranslation.y - lastTranslation.y
        )
        lastTranslation = gestureTranslation
        var translation = CGPoint(
            x: gestureTranslation.x - translationOffset.x,
            y: gestureTranslation.y - translationOffset.y
        )

        if transition != nil {
            let shouldCancel = dismissalTransitionShouldCancel(
                translation: gestureTranslation,
                delta: delta
            )
            if shouldCancel {
                transition?.cancel()
                transition = nil
            }
        }

        if let transition {
            let frameOfPresentedView = frameOfPresentedViewInContainerView
            var percentage: CGFloat = 0
            if edges.contains(.top) {
                if let scrollView {
                    translation.y += max(0, scrollView.contentSize.height + scrollView.adjustedContentInset.top - scrollView.bounds.height)
                }
                percentage = max(percentage, -translation.y / frameOfPresentedView.height)
            }
            if edges.contains(.bottom) {
                percentage = max(percentage, translation.y / frameOfPresentedView.height)
            }
            if edges.contains(.leading) {
                if let scrollView {
                    translation.x += max(0, scrollView.contentSize.width + scrollView.adjustedContentInset.left - scrollView.bounds.width)
                }
                percentage = max(percentage, -translation.x / frameOfPresentedView.width)
            }
            if edges.contains(.trailing) {
                percentage = max(percentage, translation.x / frameOfPresentedView.width)
            }

            switch gestureRecognizer.state {
            case .began, .changed:
                if let scrollView {
                    if edges.contains(.top), translation.y < 0 {
                        scrollView.contentOffset.y = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height + scrollView.adjustedContentInset.top - scrollView.frame.height)
                    }

                    if edges.contains(.bottom), translation.y > 0 {
                        scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
                    }

                    if edges.contains(.leading), translation.x < 0 {
                        scrollView.contentOffset.x = max(-scrollView.adjustedContentInset.left, scrollView.contentSize.width + scrollView.adjustedContentInset.left - scrollView.frame.width)
                    }

                    if edges.contains(.trailing), translation.x > 0 {
                        scrollView.contentOffset.x = -scrollView.adjustedContentInset.right
                    }
                }
                transition.update(percentage)

            case .ended, .cancelled, .failed:
                // Dismiss if:
                // - Drag over 50% and not moving up
                // - Large enough down vector
                let gestureVelocity = gestureRecognizer.velocity(in: presentedView)
                var velocity: CGPoint = .zero
                if edges.contains(.top) || edges.contains(.bottom) {
                    velocity.y = abs(gestureVelocity.y)
                }
                if edges.contains(.leading) || edges.contains(.trailing) {
                    velocity.x = abs(gestureVelocity.x)
                }
                let magnitude = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
                let shouldFinish = (percentage >= 0.5 && magnitude > 0) || (percentage > 0 && magnitude >= 1000)
                if shouldFinish, gestureRecognizer.state == .ended {
                    transition.finish()
                } else {
                    transition.completionSpeed = max(percentage, 0.1)
                    transition.cancel()
                }
                self.transition = nil
                panGestureDidEnd()

            default:
                break
            }
        } else {
            func dismissIfNeeded() -> Bool {
                let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
                if shouldDismiss {
                    #if targetEnvironment(macCatalyst)
                    let canStart = true
                    #else
                    let canStart: Bool
                    if keyboardHeight > 0 {
                        var views = gestureRecognizer.view.map { [$0] } ?? []
                        var firstResponder: UIView?
                        var index = 0
                        repeat {
                            let view = views[index]
                            if view.isFirstResponder {
                                firstResponder = view
                            } else {
                                views.append(contentsOf: view.subviews)
                                index += 1
                            }
                        } while index < views.count && firstResponder == nil
                        if let firstResponder {
                            let keyboardHeight = keyboardHeight
                            canStart = firstResponder.resignFirstResponder()
                            keyboardOffset = keyboardOverlapInContainerView(
                                of: frameOfPresentedViewInContainerView,
                                keyboardHeight: keyboardHeight
                            )
                        } else {
                            canStart = true
                        }
                    } else {
                        canStart = true
                    }
                    #endif
                    guard canStart else { return false }
                    presentedViewController.dismiss(animated: true)
                    return true
                }
                return false
            }

            let isScrollViewAtTop = scrollView.map({
                isAtTop(scrollView: $0, delta: delta, translation: gestureTranslation)
            }) ?? true
            let gestureVelocity = gestureRecognizer.velocity(in: presentedView)

            switch gestureRecognizer.state {
            case .began, .changed:
                if isScrollViewAtTop,
                    !wantsInteractiveDismissal,
                    panGestureDismissalShouldBegin(translation: translation, delta: delta, velocity: gestureVelocity),
                    dismissIfNeeded()
                {
                    lastTranslation = .zero
                    keyboardOffset = 0
                } else if gestureRecognizer.state == .changed,
                    isScrollViewAtTop || trackingScrollView?.isTracking == false
                {
                    if wantsInteractiveDismissal, let scrollView = trackingScrollView {
                        scrollView.isScrollEnabled = false
                        scrollView.isScrollEnabled = true
                        let showsVerticalScrollIndicator = scrollView.showsVerticalScrollIndicator
                        scrollView.showsVerticalScrollIndicator = false
                        scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
                        let showsHorizontalScrollIndicator = scrollView.showsHorizontalScrollIndicator
                        scrollView.showsHorizontalScrollIndicator = false
                        scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
                        trackingScrollView = nil
                    }
                    if wantsInteractiveDismissal,
                       panGestureDismissalShouldBegin(translation: translation, delta: delta, velocity: gestureVelocity),
                       dismissIfNeeded()
                    {
                        panGestureDidEnd()
                    } else {
                        let transform = presentedViewTransform(for: gestureTranslation)
                        transformPresentedView(transform: transform)
                    }
                }

            case .ended:
                if wantsInteractiveDismissal,
                    isScrollViewAtTop,
                    panGestureDismissalShouldBegin(translation: translation, delta: delta, velocity: gestureVelocity),
                    dismissIfNeeded()
                {
                    panGestureDidEnd()
                } else {
                    UIView.animate(
                        withDuration: 0.35,
                        delay: 0,
                        usingSpringWithDamping: 1.0,
                        initialSpringVelocity: gestureVelocity.y / 800
                    ) {
                        self.transformPresentedView(transform: .identity)
                        self.presentedView?.layoutIfNeeded()
                    } completion: { _ in
                        self.panGestureDidEnd()
                    }
                }

            default:
                transformPresentedView(transform: .identity)
                panGestureDidEnd()
            }
        }
    }

    private func panGestureDismissalShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        let shouldBegin = dismissalTransitionShouldBegin(translation: translation, delta: delta, velocity: velocity)
        if prefersInteractiveDismissal, shouldBegin {
            return panGesture.state != .began && panGesture.state != .changed
        }
        return shouldBegin
    }

    private func panGestureDidEnd() {
        translationOffset = .zero
        lastTranslation = .zero
        trackingScrollView = nil
        keyboardOffset = 0
        dismissalTransitionDidCancel()
    }

    private func isAtTop(
        scrollView: UIScrollView,
        delta: CGPoint,
        translation: CGPoint
    ) -> Bool {
        let frame = scrollView.frame
        let size = scrollView.contentSize
        let canScrollVertically = size.height > frame.size.height
        let canScrollHorizontally = size.width > frame.size.width

        let isAtVerticalTop = {
            if edges.contains(.top) || edges.contains(.bottom) {
                if canScrollHorizontally && !canScrollVertically {
                    return true
                }

                let dy = scrollView.contentOffset.y - delta.y
                if edges.contains(.bottom), (dy + scrollView.adjustedContentInset.top) <= 0 {
                    return true
                } else if edges.contains(.top) {
                    return (dy - scrollView.adjustedContentInset.bottom) >= size.height - frame.height
                }
                return false
            }
            return true
        }()

        let isAtHorizontalTop = {
            if edges.contains(.leading) || edges.contains(.trailing) {
                if canScrollVertically && !canScrollHorizontally {
                    return true
                }

                let dx = scrollView.contentOffset.x - delta.x
                if edges.contains(.trailing), (dx + scrollView.adjustedContentInset.left) <= 0 {
                    return true
                } else if edges.contains(.leading) {
                    return (dx - scrollView.adjustedContentInset.right) >= size.width - frame.width
                }
                return false
            }
            return true
        }()

        if isAtHorizontalTop, edges.contains(.top) || edges.contains(.bottom) {
            return isAtVerticalTop || (abs(translation.x) > abs(translation.y))
        }
        if isAtVerticalTop, edges.contains(.leading) || edges.contains(.trailing) {
            return isAtHorizontalTop || (abs(translation.y) > abs(translation.x))
        }
        return isAtVerticalTop && isAtHorizontalTop
    }

    // MARK: - UIGestureRecognizerDelegate

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self)
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if trackingScrollView == nil,
            otherGestureRecognizer.state != .failed,
            otherGestureRecognizer.state != .cancelled,
            let scrollView = otherGestureRecognizer.view as? UIScrollView
        {
            guard otherGestureRecognizer.isSimultaneousWithTransition else {
                // Cancel
                gestureRecognizer.isEnabled = false; gestureRecognizer.isEnabled = true
                return true
            }
            trackingScrollView = scrollView
            translationOffset = scrollView.contentOffset
            if edges.contains(.bottom) || edges.contains(.top) {
                translationOffset.y += scrollView.adjustedContentInset.top
            } else if edges.contains(.top) {
                translationOffset.y -= scrollView.adjustedContentInset.bottom
            }
            if edges.contains(.leading) || edges.contains(.trailing) {
                translationOffset.x += scrollView.adjustedContentInset.left
            } else if edges.contains(.trailing) {
                translationOffset.x += scrollView.adjustedContentInset.right
            }
            return true
        }
        return trackingScrollView != nil
    }
}

#endif
