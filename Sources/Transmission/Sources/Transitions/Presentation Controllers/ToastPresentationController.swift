//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that presents the view in its ideal size at the top or bottom
@available(iOS 14.0, *)
open class ToastPresentationController: InteractivePresentationController {

    public var edge: Edge {
        didSet {
            guard edge != oldValue else { return }
            switch edge {
            case .top, .leading:
                edges = .top
            case .bottom, .trailing:
                edges = .bottom
            }
            containerView?.setNeedsLayout()
        }
    }

    public var preferredCornerRadius: CornerRadiusOptions? {
        didSet {
            guard oldValue != preferredCornerRadius else { return }
            setCornerRadius()
        }
    }

    public var preferredSafeAreaInsets: UIEdgeInsets? {
        didSet {
            guard oldValue != preferredSafeAreaInsets else { return }
            containerView?.setNeedsLayout()
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        var insets = preferredSafeAreaInsets ?? containerView?.layoutMargins ?? .zero
        insets.bottom = max(insets.bottom, keyboardHeight + (insets.bottom - ((preferredSafeAreaInsets ?? containerView?.safeAreaInsets)?.bottom ?? 0)))
        var frame = super.frameOfPresentedViewInContainerView
            .inset(by: insets)

        var sizeThatFits = presentedView?.idealSize(for: frame.width) ?? .zero
        if sizeThatFits == .zero {
            sizeThatFits = presentedViewController.view.idealSize(for: frame.width)
        }
        sizeThatFits.height = min(sizeThatFits.height, frame.height)
        frame.origin.x = frame.midX - sizeThatFits.width / 2
        switch edge {
        case .top, .leading:
            break
        case .bottom, .trailing:
            frame.origin.y = frame.maxY - sizeThatFits.height
        }
        frame.size = sizeThatFits
        return frame
    }

    public init(
        edge: Edge = .top,
        preferredCornerRadius: CornerRadiusOptions? = nil,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        self.preferredCornerRadius = preferredCornerRadius
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        edges = Edge.Set(edge)
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        setCornerRadius()
    }

    open override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        .zero
    }

    private func setCornerRadius() {
        guard let presentedView else { return }
        let cornerRadius = preferredCornerRadius ?? .identity
        cornerRadius.apply(to: presentedView.layer, height: presentedView.bounds.height)
    }
}

/// An interactive transition built for the ``ToastPresentationController``.
@available(iOS 14.0, *)
open class ToastPresentationControllerTransition: PresentationControllerTransition {

    public let edge: Edge

    public init(
        edge: Edge,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view
        else {
            transitionContext.completeTransition(false)
            return
        }

        if isPresenting {
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()

            (presented as? AnyHostingController)?.render()

            if let transitionReaderCoordinator = presented.transitionReaderCoordinator {
                transitionReaderCoordinator.update(isPresented: true)

                presentedView.setNeedsLayout()
                presentedView.layoutIfNeeded()

                if let presentationController = presented.presentationController as? PresentationController {
                    presentedFrame = presentationController.frameOfPresentedViewInContainerView
                }

                transitionReaderCoordinator.update(isPresented: false)
                presentedView.setNeedsLayout()
                presentedView.layoutIfNeeded()
                transitionReaderCoordinator.update(isPresented: true)
            }

            switch edge {
            case .top, .leading:
                let transform = CGAffineTransform(
                    translationX: 0,
                    y: -presentedView.frame.maxY
                )
                presentedView.frame = presentedFrame.applying(transform)
            case .bottom, .trailing:
                let transform = CGAffineTransform(
                    translationX: 0,
                    y: transitionContext.containerView.frame.height - presentedFrame.minY
                )
                presentedView.frame = presentedFrame.applying(transform)
            }
            animator.addAnimations {
                presentedView.frame = presentedFrame
            }
        } else {
            presentedView.layoutIfNeeded()

            let finalFrame: CGRect
            switch edge {
            case .top, .leading:
                let transform = CGAffineTransform(translationX: 0, y: -presentedView.frame.maxY)
                finalFrame = presentedView.frame.applying(transform)
            case .bottom, .trailing:
                let transform = CGAffineTransform(
                    translationX: 0,
                    y: transitionContext.containerView.frame.height - presentedView.frame.minY
                )
                finalFrame = presentedView.frame.applying(transform)
            }
            animator.addAnimations {
                presentedView.frame = finalFrame
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
    }
}

#endif
