//
//  DynamicIslandTransition.swift
//  Example
//
//  Created by Nathan Tannar on 2024-05-21.
//

import UIKit
import SwiftUI
import Transmission

extension PresentationLinkTransition {
    static let dynamicIsland: PresentationLinkTransition = .custom(
        options: Options(
            modalPresentationCapturesStatusBarAppearance: true,
            preferredPresentationBackgroundColor: .black
        ),
        DynamicIslandTransition()
    )
}

struct DynamicIslandTransition: PresentationLinkTransitionRepresentable {

    func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> DynamicIslandPresentationController {
        DynamicIslandPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
    }

    func updateUIPresentationController(
        presentationController: DynamicIslandPresentationController,
        context: Context
    ) {

    }

    func updateHostingController<Content: View>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) {
        presenting.disableSafeArea = true
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> DynamicIslandPresentationControllerTransition? {
        let transition = DynamicIslandPresentationControllerTransition(
            isPresenting: true,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }

    func animationController(
        forDismissed dismissed: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> DynamicIslandPresentationControllerTransition? {
        let transition = DynamicIslandPresentationControllerTransition(
            isPresenting: false,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }
}

class DynamicIslandPresentationController: InteractivePresentationController {

    let dynamicIslandTopInset: CGFloat = 11

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let presentedView else { return .zero }
        var frame = super.frameOfPresentedViewInContainerView
        frame = frame.inset(
            by: UIEdgeInsets(
                top: dynamicIslandTopInset,
                left: dynamicIslandTopInset,
                bottom: 0,
                right: dynamicIslandTopInset
            )
        )
        let fittingSize = CGSize(
            width: frame.size.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let targetHeight = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height
        frame.size.height = max(targetHeight - presentedView.safeAreaInsets.top, 0)
        return frame
    }

    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        edges = [.top]
    }

    override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let dy = frictionCurve(translation.y, coefficient: 1)
        let frame = frameOfPresentedViewInContainerView
        let scale = 1 + (dy / 600)
        return CGAffineTransform(
            scaleX: 1,
            y: scale
        )
        .translatedBy(
            x: 0,
            y: -(1 - scale) * 0.5 * frame.size.height
        )
    }

    override func transformPresentedView(transform: CGAffineTransform) {
        presentedView?.transform = transform
    }

    override func transitionAlongsidePresentation(progress: CGFloat) {
        super.transitionAlongsidePresentation(progress: progress)
        updateCornerRadius()
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedView?.layer.cornerCurve = .continuous
        presentedView?.layer.cornerRadius = 37 / 2
    }

    override func layoutPresentedView(frame: CGRect) {
        super.layoutPresentedView(frame: frame)
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        let cornerRadius = (presentedView?.bounds.height ?? 0) / 2
        presentedView?.layer.cornerRadius = min(cornerRadius, UIScreen.main._displayCornerRadius - 11)
    }
}

class DynamicIslandPresentationControllerTransition: PresentationControllerTransition {

    override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentingView = transitionContext.view(forKey: isPresenting ? .from : .to) ?? presenting.view
        else {
            transitionContext.completeTransition(false)
            return
        }

        let dynamicIslandFrame = CGRect(
            x: (UIScreen.main.bounds.size.width - 126) / 2,
            y: 14,
            width: 126,
            height: 37
        )

        if isPresenting {
            presentedView.alpha = 0
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()
            presentedFrame = presentedView.frame

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView,
                presentedFrame: &presentedFrame
            )

            presentedView.frame = dynamicIslandFrame
            presentedView.alpha = 1
            animator.addAnimations {
                presentedView.frame = presentedFrame
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            presentedView.layoutIfNeeded()

            animator.addAnimations {
                presentedView.frame = dynamicIslandFrame
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

extension UISpringTimingParameters {
    convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
}
