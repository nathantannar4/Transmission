//
//  HeroMoveTransition.swift
//  Example
//
//  Created by Nathan Tannar on 2022-12-06.
//

import SwiftUI

import Transmission

extension PresentationLinkTransition {
    static let heroMove: PresentationLinkTransition = .custom(HeroMoveTransition())
}

struct HeroMoveTransition: PresentationLinkTransitionRepresentable {

    func makeUIPresentationController(
        context: Context,
        presented: UIViewController,
        presenting: UIViewController?
    ) -> HeroMovePresentationController {
        HeroMovePresentationController(
            sourceView: context.sourceView,
            presentedViewController: presented,
            presenting: presenting
        )
    }

    func updateUIPresentationController(
        presentationController: HeroMovePresentationController,
        context: Context
    ) {

    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let presentationController = presented.presentationController as? HeroMovePresentationController else {
            return nil
        }
        let transition = HeroMoveInteractiveTransition(
            sourceView: presentationController.sourceView,
            isPresenting: true
        )
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let presentationController = dismissed.presentationController as? HeroMovePresentationController else {
            return nil
        }
        let transition = HeroMoveInteractiveTransition(
            sourceView: presentationController.sourceView,
            isPresenting: false
        )
        presentationController.beginTransition(with: transition)
        return transition
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // swiftlint:disable force_cast
        animator as! HeroMoveInteractiveTransition
    }
}

class HeroMovePresentationController: UIPresentationController {

    private(set) weak var sourceView: UIView?
    private weak var transition: HeroMoveInteractiveTransition?

    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))

    private var isPanGestureActive = false
    private var dyOffset: CGFloat = 0

    override var shouldPresentInFullscreen: Bool { true }

    override var presentationStyle: UIModalPresentationStyle { .overFullScreen }

    init(
        sourceView: UIView? = nil,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.sourceView = sourceView
    }

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

    func beginTransition(with transition: HeroMoveInteractiveTransition) {
        self.transition = transition

        transition.wantsInteractiveStart = isPanGestureActive
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let scrollView = gestureRecognizer.view as? UIScrollView
        guard let containerView = scrollView ?? containerView else {
            return
        }

        var translation = gestureRecognizer.translation(in: containerView)
        translation.y -= dyOffset
        let percentage = translation.y / containerView.bounds.height

        let shouldStart = scrollView.map({ isAtTop(scrollView: $0) }) ?? true

        guard isPanGestureActive else {
            if !presentedViewController.isBeingDismissed, shouldStart, translation.y > 1 {
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
            containerView.transform = .identity
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

extension HeroMovePresentationController: UIGestureRecognizerDelegate {
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

class HeroMoveInteractiveTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    weak var sourceView: UIView?
    let isPresenting: Bool

    var animator: UIViewPropertyAnimator?
    var onInteractionEnded: (() -> Void)?

    init(
        sourceView: UIView?,
        isPresenting: Bool
    ) {
        self.sourceView = sourceView
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
        onInteractionEnded = nil
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
        //let options: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: UInt(completionCurve.rawValue << 16))
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

        func findHostingView(of view: UIView?) -> UIView? {
            guard let view = view else {
                return nil
            }
            if view is AnyHostingView || view is UIScrollView {
                return view
            }
            return findHostingView(of: view.superview)
        }

        let hostingView = findHostingView(of: sourceView)

        let snapshotFrame = sourceView.map { $0.convert($0.frame, to: hostingView) } ?? presenting.view.frame
        let sourceFrame = sourceView.map { $0.convert($0.frame, to: transitionContext.containerView) } ??
        (isPresenting ? transitionContext.initialFrame(for: presenting) : transitionContext.finalFrame(for: presenting))

        let presentedFrame = (isPresenting ? transitionContext.finalFrame(for: presented) : transitionContext.initialFrame(for: presented))

        func convertToSourceAspectRatio(frame: CGRect) -> CGRect {
            let scale = min(frame.size.height / max(snapshotFrame.size.height, 1), frame.size.width / max(snapshotFrame.size.width, 1))
            let width = snapshotFrame.size.width * scale
            let height = snapshotFrame.size.height * scale
            return CGRectIntegral(
                CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y,
                    width: width,
                    height: height
                )
            )
        }

        func convertToDestinationAspectRatio(frame: CGRect) -> CGRect {
            let destinationFrame = presentedFrame
            let scale = max(frame.size.height / max(destinationFrame.size.height, 1), frame.size.width / max(destinationFrame.size.width, 1))
            let width = destinationFrame.size.width * scale
            let height = destinationFrame.size.height * scale
            return CGRectIntegral(
                CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y,
                    width: width,
                    height: height
                )
            )
        }

        let safeAreaInsets = hostingView?.superview?.safeAreaInsets ?? presented.view.safeAreaInsets

        let presentedSnapshot = presented.view.snapshotView(afterScreenUpdates: true)
        let presentingSnapshot = hostingView?.resizableSnapshotView(from: snapshotFrame, afterScreenUpdates: true, withCapInsets: .zero)

        if let snapshot = presentingSnapshot {
            transitionContext.containerView.addSubview(snapshot)
            if isPresenting {
                snapshot.frame = sourceFrame
            } else {
                snapshot.frame = convertToSourceAspectRatio(frame: presentedFrame.inset(by: safeAreaInsets))
            }
        }

        if let snapshot = presentedSnapshot {
            transitionContext.containerView.addSubview(snapshot)
            if isPresenting {
                snapshot.frame = convertToDestinationAspectRatio(frame: sourceFrame)
                    .offsetBy(dx: 0, dy: -presented.view.safeAreaInsets.top - 8)
            } else {
                snapshot.frame = convertToDestinationAspectRatio(frame: presentedFrame)
            }
        }

        // Inverted Mask
        if let hostingView {
            let maskLayer = CAShapeLayer()
            let path = CGMutablePath()
            path.addRect(hostingView.bounds)
            path.addRect(sourceView!.convert(sourceView!.frame, to: hostingView))
            maskLayer.path = path
            maskLayer.fillRule = .evenOdd
            hostingView.layer.mask = maskLayer
        }

        presented.view.isHidden = true
        presentedSnapshot?.alpha = isPresenting ? 0 : 1
        let transition: () -> Void = {
            presentedSnapshot?.alpha = isPresenting ? 1 : 0
        }

        if transitionContext.isInteractive {
            onInteractionEnded = transition
        } else {
            presentingSnapshot?.alpha = isPresenting ? 1 : 0
        }

        animator.addAnimations {
            if isPresenting {
                presentedSnapshot?.frame = presentedFrame
                presentingSnapshot?.frame = convertToSourceAspectRatio(frame: presentedFrame.inset(by: safeAreaInsets))
            } else {
                presentedSnapshot?.frame = convertToDestinationAspectRatio(frame: sourceFrame)
                    .offsetBy(dx: 0, dy: -presented.view.safeAreaInsets.top - 8)
                presentingSnapshot?.frame = sourceFrame
            }
            if !transitionContext.isInteractive {
                transition()
                presentingSnapshot?.alpha = isPresenting ? 0 : 1
            }
        }
        animator.addCompletion { animatingPosition in

            presented.view.isHidden = false
            hostingView?.layer.mask = nil
            presentedSnapshot?.removeFromSuperview()
            presentingSnapshot?.removeFromSuperview()

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

    override func finish() {
        super.finish()
        UIView.animate(withDuration: 0.1) {
            self.onInteractionEnded?()
        }
    }
}

