//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

@available(iOS 14.0, *)
open class InteractivePresentationController: PresentationController {

    public private(set) lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))

    private var translationOffset: CGPoint = .zero
    private var transition: InteractivePresentationControllerTransition?

    open override var shouldAutoLayoutPresentedView: Bool {
        transition == nil && super.shouldAutoLayoutPresentedView
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            panGesture.delegate = self
            panGesture.allowedScrollTypesMask = .all
            presentedView?.addGestureRecognizer(panGesture)
        }
    }

    public func animationController(
        isPresenting: Bool
    ) -> InteractivePresentationControllerTransition? {
        let isInteracting = panGesture.state == .began || panGesture.state == .changed
        if isInteracting {
            let transition = InteractivePresentationControllerTransition(
                isPresenting: isPresenting
            )
            transition.wantsInteractiveStart = true
            self.transition = transition
            return transition
        }
        return nil
    }

    open func transformPresentedView(transform: CGAffineTransform) {
        presentedView?.transform = transform
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let scrollView = gestureRecognizer.view as? UIScrollView
        guard let presentedView else {
            return
        }

        let gestureTranslation = gestureRecognizer.translation(in: presentedView)
        let offset = CGPoint(
            x: gestureTranslation.x - translationOffset.x,
            y: gestureTranslation.y - translationOffset.y
        )
        let translation = offset.y

        if let transition {
            guard translation >= 0 else {
                transition.cancel()
                self.transition = nil
                return
            }
            let percentage = abs(translation / presentedView.bounds.height)
            switch gestureRecognizer.state {
            case .began, .changed:
                if let scrollView {
                    scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
                }
                transition.update(percentage)

            case .ended, .cancelled, .failed:
                // Dismiss if:
                // - Drag over 50% and not moving up
                // - Large enough down vector
                let velocity = gestureRecognizer.velocity(in: presentedView).y
                let shouldFinish = (percentage > 0.5 && velocity > 0) || velocity >= 1000
                if shouldFinish, gestureRecognizer.state != .failed {
                    transition.finish()
                } else {
                    transition.completionSpeed = 1 - percentage
                    transition.cancel()
                }
                self.transition = nil
                translationOffset = .zero

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
                    if canStart {
                        let point = gestureRecognizer.location(in: presentedView)
                        gestureRecognizer.setTranslation(
                            CGPoint(
                                x: gestureTranslation.x,
                                y: gestureTranslation.y + point.y
                            ),
                            in: gestureRecognizer.view
                        )
                    }
                } else {
                    canStart = true
                }
            } else {
                canStart = true
            }
            #endif
            guard canStart else { return }

            let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? false
            if shouldDismiss, translation >= 0 {
                presentedViewController.dismiss(animated: true)
            } else {
                let dy = frictionCurve(translation)
                let transform = CGAffineTransform(
                    translationX: 0,
                    y: dy
                )
                switch gestureRecognizer.state {
                case .began, .changed:
                    transformPresentedView(transform: transform)

                case .ended:
                    UIView.animate(
                        withDuration: 0.35,
                        delay: 0,
                        usingSpringWithDamping: 1.0,
                        initialSpringVelocity: 0
                    ) {
                        self.transformPresentedView(transform: .identity)
                        presentedView.layoutIfNeeded()
                    }

                default:
                    transformPresentedView(transform: .identity)
                }
            }
        }
    }

    private func isAtTop(scrollView: UIScrollView) -> Bool {
        let frame = scrollView.frame
        let size = scrollView.contentSize
        let canScrollVertically = size.height > frame.size.height
        let canScrollHorizontally = size.width > frame.size.width

        if canScrollHorizontally && !canScrollVertically {
            return false
        }
        let dy = scrollView.contentOffset.y + scrollView.contentInset.top
        return dy <= 0
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
            translationOffset = CGPoint(
                x: scrollView.contentOffset.x + scrollView.adjustedContentInset.left,
                y: scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            )
            return false
        }
        return false
    }
}

@available(iOS 14.0, *)
public class InteractivePresentationControllerTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    private let isPresenting: Bool
    private var animator: UIViewPropertyAnimator?

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        transitionContext?.isAnimated == true ? 0.35 : 0
    }

    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        let animator = makeAnimatorIfNeeded(using: transitionContext)
        animator.startAnimation()

        if !transitionContext.isAnimated {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    public func animationEnded(_ transitionCompleted: Bool) {
        wantsInteractiveStart = false
        animator = nil
    }

    public func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        let animator = makeAnimatorIfNeeded(using: transitionContext)
        return animator
    }

    private func makeAnimatorIfNeeded(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {
        if let animator = animator {
            return animator
        }

        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: completionCurve
        )
        self.animator = animator

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        if isPresenting {
            let frame = transitionContext.finalFrame(for: presented)
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = frame
            let transform = CGAffineTransform(
                translationX: 0,
                y: frame.size.height
            )
            presented.view.transform = transform
            animator.addAnimations {
                presented.view.transform = .identity
            }
        } else {
            let frame = transitionContext.finalFrame(for: presented)
            let dy = transitionContext.containerView.frame.height - frame.origin.y
            let transform = CGAffineTransform(
                translationX: 0,
                y: dy
            )
            animator.addAnimations {
                presented.view.transform = transform
            }
        }
        animator.addCompletion { animatingPosition in
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        return animator
    }
}

#endif
