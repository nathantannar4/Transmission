//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

@available(iOS 14.0, *)
open class InteractivePresentationController: PresentationController {

    /// The edges the presented view can be interactively dismissed towards.
    open var edges: Edge.Set = [.bottom]

    public private(set) weak var transition: UIPercentDrivenInteractiveTransition?
    public private(set) lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))

    private var translationOffset: CGPoint = .zero
    private var lastTranslation: CGPoint = .zero

    open var wantsInteractiveTransition: Bool {
        let isInteracting = panGesture.state != .possible
        return isInteracting
    }

    open override var shouldAutoLayoutPresentedView: Bool {
        transition == nil && panGesture.state == .possible && super.shouldAutoLayoutPresentedView
    }

    public func transition(with transition: UIPercentDrivenInteractiveTransition) {
        self.transition = transition
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
        delta: CGPoint
    ) -> Bool {
        if edges.contains(.bottom), translation.y > 0 {
            return true
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
        return true
    }

    open func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let dy = frictionCurve(translation.y)
        return CGAffineTransform(
            translationX: 0,
            y: dy
        )
    }

    open func transformPresentedView(transform: CGAffineTransform) {
        let frame = frameOfPresentedViewInContainerView.applying(transform)
        layoutPresentedView(frame: frame)
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
                percentage = max(percentage, abs(translation.y) / frameOfPresentedView.height)
            }
            if edges.contains(.bottom) {
                percentage = max(percentage, abs(translation.y) / frameOfPresentedView.height)
            }
            if edges.contains(.leading) {
                if let scrollView {
                    translation.x += max(0, scrollView.contentSize.width + scrollView.adjustedContentInset.left - scrollView.bounds.width)
                }
                percentage = max(percentage, abs(translation.x) / frameOfPresentedView.width)
            }
            if edges.contains(.trailing) {
                percentage = max(percentage, abs(translation.x) / frameOfPresentedView.width)
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
                let shouldFinish = (percentage > 0.5 && magnitude > 0) || magnitude >= 1000
                if shouldFinish, gestureRecognizer.state == .ended {
                    transition.finish()
                } else {
                    transition.completionSpeed = 1 - percentage
                    transition.cancel()
                }
                self.transition = nil
                translationOffset = .zero
                lastTranslation = .zero

            default:
                break
            }
        } else {
            let isScrollViewAtTop = scrollView.map({ isAtTop(scrollView: $0) }) ?? true
            guard isScrollViewAtTop else { return }

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
                    canStart = firstResponder.resignFirstResponder()
                } else {
                    canStart = true
                }
            } else {
                canStart = true
            }
            #endif
            guard canStart else { return }

            let shouldDismiss = (delegate?.presentationControllerShouldDismiss?(self) ?? false)
                && dismissalTransitionShouldBegin(translation: translation, delta: delta)
            if shouldDismiss {
                presentedViewController.dismiss(animated: true)
            } else {
                switch panGesture.state {
                case .began, .changed:
                    let transform = presentedViewTransform(for: translation)
                    transformPresentedView(transform: transform)

                case .ended:
                    UIView.animate(
                        withDuration: 0.35,
                        delay: 0,
                        usingSpringWithDamping: 1.0,
                        initialSpringVelocity: 0
                    ) {
                        self.transformPresentedView(transform: .identity)
                        self.presentedView?.layoutIfNeeded()
                    }
                    lastTranslation = .zero

                default:
                    transformPresentedView(transform: .identity)
                    lastTranslation = .zero
                }
            }
        }
    }

    private func isAtTop(scrollView: UIScrollView) -> Bool {
        let frame = scrollView.frame
        let size = scrollView.contentSize
        let canScrollVertically = size.height > frame.size.height
        let canScrollHorizontally = size.width > frame.size.width

        let isAtVerticalTop = {
            if edges.contains(.top) || edges.contains(.bottom) {
                if canScrollHorizontally && !canScrollVertically {
                    return false
                }

                let dy = scrollView.contentOffset.y + scrollView.contentInset.top
                if edges.contains(.bottom) {
                    return dy <= 0
                } else {
                    return dy >= size.height - frame.height
                }
            }
            return true
        }()

        let isAtHorizontalTop = {
            if edges.contains(.leading) || edges.contains(.trailing) {
                if canScrollVertically && !canScrollHorizontally {
                    return false
                }

                let dx = scrollView.contentOffset.x + scrollView.contentInset.left
                if edges.contains(.trailing) {
                    return dx <= 0
                } else {
                    return dx >= size.width - frame.width
                }
            }
            return true
        }()

        return isAtVerticalTop && isAtHorizontalTop
    }
}

// MARK: - UIGestureRecognizerDelegate

@available(iOS 14.0, *)
extension InteractivePresentationController: UIGestureRecognizerDelegate {

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
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            guard otherGestureRecognizer.isSimultaneousWithTransition else {
                // Cancel
                gestureRecognizer.isEnabled = false; gestureRecognizer.isEnabled = true
                return true
            }
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(onPanGesture(_:)))
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
        return false
    }
}

#endif
