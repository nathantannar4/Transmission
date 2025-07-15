//
//  DynamicIslandTransition.swift
//  Example
//
//  Created by Nathan Tannar on 2024-05-21.
//

import UIKit
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

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> DynamicIslandPresentationControllerTransition? {
        DynamicIslandPresentationControllerTransition(
            isPresenting: true,
            animation: context.transaction.animation
        )
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
        transition.wantsInteractiveStart = false
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
        let dy = frictionCurve(translation.y, coefficient: 0.1)
        let frame = frameOfPresentedViewInContainerView
        let scale = 1 + (dy / 600)
        return CGAffineTransform(
            scaleX: scale,
            y: scale
        )
        .translatedBy(
            x: (1 - scale) * 0.5 * frame.size.width,
            y: 0
        )
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        presentedView?.layer.cornerCurve = .continuous
        presentedView?.layer.cornerRadius = max(UIScreen.main._displayCornerRadius - 11, 0)
    }

    override func layoutPresentedView(frame: CGRect) {
        super.layoutPresentedView(frame: frame)

        presentedView?.layer.cornerRadius = min(frame.size.height / 2, max(UIScreen.main._displayCornerRadius - 11, 0))
    }
}

class DynamicIslandPresentationControllerTransition: PresentationControllerTransition {

    override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let dynamicIslandFrame = CGRect(x: 135, y: 11, width: 123, height: 36)
        let hostingController = presented as? AnyHostingController
        let oldValue = hostingController?.disableSafeArea ?? false
        hostingController?.disableSafeArea = true
        let cornerRadius = presented.view.layer.cornerRadius

        if isPresenting {
            let finalFrame = transitionContext.finalFrame(for: presented)
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = dynamicIslandFrame
            presented.view.layer.cornerRadius = dynamicIslandFrame.height / 2
            presented.view.clipsToBounds = true
            presented.view.layoutIfNeeded()
            hostingController?.render()
            animator.addAnimations {
                presented.view.frame = finalFrame
                presented.view.layer.cornerRadius = min(finalFrame.size.height / 2, cornerRadius)
                hostingController?.disableSafeArea = oldValue
                presented.view.layoutIfNeeded()
            }
        } else {
            let initialFrame = transitionContext.initialFrame(for: presented)
            presented.view.frame = initialFrame
            presented.view.clipsToBounds = true
            animator.addAnimations {
                presented.view.frame = dynamicIslandFrame
                presented.view.layer.cornerRadius = dynamicIslandFrame.height / 2
                presented.view.layoutIfNeeded()
            }
        }
        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = oldValue
            presented.view.layoutIfNeeded()
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
