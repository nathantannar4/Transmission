//
//  FullscreenSheetTransition.swift
//  Example
//
//  Created by Nathan Tannar on 2022-12-06.
//

import SwiftUI

import Transmission

extension PresentationLinkTransition {
    static let fullscreenSheet: PresentationLinkTransition = .custom(FullscreenSheetTransition())
}

struct FullscreenSheetTransition: PresentationLinkCustomTransition {

    func presentationController(
        sourceView: UIView,
        presented: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationController {
        FullscreenSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        FullscreenSheetInteractiveTransition(
            isPresenting: true
        )
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let presentationController = dismissed.presentationController as? FullscreenSheetPresentationController else {
            return nil
        }
        let animator = FullscreenSheetInteractiveTransition(
            isPresenting: false
        )
        presentationController.beginTransition(with: animator)
        return animator
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // swiftlint:disable force_cast
        animator as! FullscreenSheetInteractiveTransition
    }
}

class FullscreenSheetInteractiveTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    let isPresenting: Bool

    let isScaleEnabled = true
    var animator: UIViewPropertyAnimator?

    init(
        isPresenting: Bool
    ) {
        self.isPresenting = isPresenting
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        transitionContext?.isAnimated == true ? 0.35 : 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let animator = makeAnimatorIfNeeded(using: transitionContext)

        animator.startAnimation()

        if !transitionContext.isAnimated {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    func animationEnded(_ transitionCompleted: Bool) {
        wantsInteractiveStart = false
        animator = nil
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        let animator = makeAnimatorIfNeeded(using: transitionContext)
        return animator
    }

    func makeAnimatorIfNeeded(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        if let animator = animator {
            return animator
        }

        let isPresenting = isPresenting
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: completionCurve
        )

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        presented.view.layer.masksToBounds = true
        presented.view.layer.cornerCurve = .continuous

        presenting.view.layer.masksToBounds = true
        presenting.view.layer.cornerCurve = .continuous

        if isPresenting {
            presented.view.transform = CGAffineTransform(translationX: 0, y: transitionContext.finalFrame(for: presented).height)
            presented.view.layer.cornerRadius = Constants.displayCornerRadius
        } else {
            presented.view.layer.cornerRadius = Constants.displayCornerRadius
            presenting.view.transform = isScaleEnabled ? CGAffineTransform(scaleX: 0.9, y: 0.9) : .identity
            presenting.view.layer.cornerRadius = isScaleEnabled ? Constants.displayCornerRadius : 0
        }

        let frame = transitionContext.finalFrame(for: presented)
        let presentedTransform = isPresenting ? .identity : CGAffineTransform(translationX: 0, y: frame.height)
        let presentingTransform = isPresenting && isScaleEnabled ? CGAffineTransform(scaleX: 0.9, y: 0.9) : .identity
        let cornerRadius = isPresenting && isScaleEnabled ? Constants.displayCornerRadius : 0
        animator.addAnimations {
            presented.view.transform = presentedTransform
            presenting.view.transform = presentingTransform
            presenting.view.layer.cornerRadius = cornerRadius
        }
        animator.addCompletion { animatingPosition in

            presented.view.layer.cornerRadius = 0
            presenting.view.layer.cornerRadius = 0
            presenting.view.transform = .identity

            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        self.animator = animator
        return animator
    }
}

class FullscreenSheetPresentationController: UIPresentationController {

    private weak var transition: FullscreenSheetInteractiveTransition?

    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))

    private var isPanGestureActive = false
    private var dyOffset: CGFloat = 0

    override var shouldPresentInFullscreen: Bool { true }

    override var presentationStyle: UIModalPresentationStyle { .overFullScreen }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let containerView = containerView else {
            return
        }

        containerView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = frameOfPresentedViewInContainerView
        presentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        setupPresentedViewConstraints(containerView: containerView)
    }

    func setupPresentedViewConstraints(containerView: UIView) {
        NSLayoutConstraint.activate([
            presentedViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            presentedViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            presentedViewController.view.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            presentedViewController.view.rightAnchor.constraint(equalTo: containerView.rightAnchor),
        ])
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        guard completed else {
            return
        }

        panGesture.delegate = self
        panGesture.allowedScrollTypesMask = .all
        containerView?.addGestureRecognizer(panGesture)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        delegate?.presentationControllerWillDismiss?(self)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            delegate?.presentationControllerDidDismiss?(self)
        } else {
            delegate?.presentationControllerDidAttemptToDismiss?(self)
        }
    }

    func beginTransition(with transition: FullscreenSheetInteractiveTransition) {
        self.transition = transition

        transition.wantsInteractiveStart = isPanGestureActive
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let scrollView = gestureRecognizer.view as? UIScrollView
        guard let containerView = scrollView ?? containerView else {
            return
        }

        let translation = gestureRecognizer.translation(in: containerView).y - dyOffset
        let percentage = translation / containerView.bounds.height

        let shouldStart = scrollView.map({ isAtTop(scrollView: $0) }) ?? true

        guard isPanGestureActive else {
            if !presentedViewController.isBeingDismissed, shouldStart, translation > 1 {
#if targetEnvironment(macCatalyst)
                let canStart = true
#else
                var views = presentedViewController.view.map { [$0] } ?? []
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
                let canStart = firstResponder == nil
#endif
                if canStart {
                    isPanGestureActive = true
                    presentedViewController.dismiss(animated: true)
                }
            }
            return
        }

        if !shouldStart, percentage < 0 {
            transition?.cancel()
            isPanGestureActive = false
            return
        }

        switch gestureRecognizer.state {
        case .began, .changed:
            if let scrollView = scrollView {
                scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
            }

            transition?.update(percentage)

        case .ended, .cancelled:
            // Dismiss if:
            // - Drag over 50% and not moving up
            // - Large enough down vector
            let velocity = gestureRecognizer.velocity(in: containerView)
            let shouldDismiss = percentage > 0.5 && velocity.y > 0 || velocity.y > 1000
            if shouldDismiss {
                transition?.finish()
            } else {
                transition?.cancel()
            }
            isPanGestureActive = false
            dyOffset = 0

        default:
            break
        }
    }

    func isAtTop(scrollView: UIScrollView) -> Bool {
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

extension FullscreenSheetPresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(onPanGesture(_:)))
            dyOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            return false
        }
        return false
    }
}

struct Constants {
    static var displayCornerRadius: Double = {
        max(12, UIScreen.main.displayCornerRadius - 1)
    }()
}

extension UIScreen {
    var displayCornerRadius: CGFloat {
        let key = String("suidaRrenroCyalpsid_".reversed())
        return value(forKey: key) as? CGFloat ?? 0
    }
}
