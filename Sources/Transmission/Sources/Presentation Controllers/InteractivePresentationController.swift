//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

@available(iOS 14.0, *)
open class InteractivePresentationController: PresentationController, UIGestureRecognizerDelegate {

    /// The edges the presented view can be interactively dismissed towards.
    open var edges: Edge.Set = [.bottom]

    public private(set) weak var transition: UIPercentDrivenInteractiveTransition?
    public private(set) lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
    private weak var scrollViewPanGestureRecognizer: UIPanGestureRecognizer?

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
        return isInteracting(gesture: scrollViewPanGestureRecognizer) || isInteracting(gesture: panGesture)
    }

    /// When true, dismissal of the presented view controller will be deferred until the pan gesture ends
    open var wantsInteractiveDismissal: Bool {
        return keyboardOffset > 0
    }

    open override var shouldAutoLayoutPresentedView: Bool {
        transition == nil && panGesture.state == .possible && super.shouldAutoLayoutPresentedView
    }

    /// Links an interactive transition to the pan gesture of the presentation controller
    public func transition(with transition: UIPercentDrivenInteractiveTransition) {
        self.transition = transition
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
        let scrollView = gestureRecognizer.view as? UIScrollView
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
                let shouldFinish = (percentage >= 0.5 && magnitude > 0) || magnitude >= 1000
                if shouldFinish, gestureRecognizer.state == .ended {
                    transition.finish()
                } else {
                    transition.completionSpeed = 1 - percentage
                    transition.cancel()
                }
                self.transition = nil
                panGestureDidEnd()

            default:
                break
            }
        } else {
            lazy var isScrollViewAtTop = scrollView.map({ isAtTop(scrollView: $0) }) ?? true
            guard gestureRecognizer.state == .ended || isScrollViewAtTop else {
                return
            }

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
            guard canStart || gestureRecognizer.state == .ended else { return }

            func dismissIfNeeded() -> Bool {
                let shouldDismiss = (delegate?.presentationControllerShouldDismiss?(self) ?? false)
                if shouldDismiss {
                    presentedViewController.dismiss(animated: true)
                }
                return shouldDismiss
            }

            let gestureVelocity = gestureRecognizer.velocity(in: presentedView)

            switch gestureRecognizer.state {
            case .began, .changed:
                if !wantsInteractiveDismissal, 
                    dismissalTransitionShouldBegin(translation: translation, delta: delta, velocity: gestureVelocity),
                    dismissIfNeeded()
                {
                    lastTranslation = .zero
                    keyboardOffset = 0
                } else {
                    let transform = presentedViewTransform(for: translation)
                    transformPresentedView(transform: transform)
                }

            case .ended:
                if wantsInteractiveDismissal,
                    isScrollViewAtTop,
                    dismissalTransitionShouldBegin(translation: translation, delta: delta, velocity: gestureVelocity),
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

    private func panGestureDidEnd() {
        translationOffset = .zero
        lastTranslation = .zero
        scrollViewPanGestureRecognizer?.removeTarget(self, action: #selector(onPanGesture(_:)))
        scrollViewPanGestureRecognizer = nil
        keyboardOffset = 0
    }

    private func isAtTop(scrollView: UIScrollView) -> Bool {
        let frame = scrollView.frame
        let size = scrollView.contentSize
        let canScrollVertically = size.height > frame.size.height
        let canScrollHorizontally = size.width > frame.size.width

        let isAtVerticalTop = {
            if edges.contains(.top) || edges.contains(.bottom) {
                if canScrollHorizontally && !canScrollVertically {
                    return true
                }

                let dy = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                if edges.contains(.bottom) {
                    return dy <= 0
                } else {
                    return dy >= size.height - frame.height - scrollView.adjustedContentInset.bottom
                }
            }
            return true
        }()

        let isAtHorizontalTop = {
            if edges.contains(.leading) || edges.contains(.trailing) {
                if canScrollVertically && !canScrollHorizontally {
                    return true
                }

                let dx = scrollView.contentOffset.x + scrollView.adjustedContentInset.left
                if edges.contains(.trailing) {
                    return dx <= 0
                } else {
                    return dx >= size.width - frame.width - scrollView.adjustedContentInset.right
                }
            }
            return true
        }()

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
        if scrollViewPanGestureRecognizer == nil,
            let scrollView = otherGestureRecognizer.view as? UIScrollView
        {
            guard otherGestureRecognizer.isSimultaneousWithTransition else {
                // Cancel
                gestureRecognizer.isEnabled = false; gestureRecognizer.isEnabled = true
                return true
            }
            guard !wantsInteractiveDismissal else {
                // Cancel
                otherGestureRecognizer.isEnabled = false; otherGestureRecognizer.isEnabled = true
                return true
            }
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(onPanGesture(_:)))
            scrollViewPanGestureRecognizer = scrollView.panGestureRecognizer
            translationOffset = scrollView.contentOffset
            if edges.contains(.bottom) || edges.contains(.top) {
                translationOffset.y += scrollView.adjustedContentInset.top
            }
            if edges.contains(.top) {
                translationOffset.y -= scrollView.adjustedContentInset.bottom
            }
            if edges.contains(.leading) || edges.contains(.trailing) {
                translationOffset.x += scrollView.adjustedContentInset.left
            }
            if edges.contains(.trailing) {
                translationOffset.x += scrollView.adjustedContentInset.right
            }
            return false
        }
        return scrollViewPanGestureRecognizer != nil
    }
}

#endif
