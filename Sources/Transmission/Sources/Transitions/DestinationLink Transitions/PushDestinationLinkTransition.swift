//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The push transition style.
    public static var push: DestinationLinkTransition {
        .push(.init())
    }

    /// The push transition style.
    public static func push(
        _ transitionOptions: PushDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init(
            prefersPanGesturePop: true
        )
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            PushDestinationLinkTransition(options: transitionOptions)
        )
    }

    /// The push transition style.
    public static func push(
        dimmingColor: Color? = nil,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredShadow: ShadowOptions? = nil,
        prefersPanGesturePop: Bool = true,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
    ) -> DestinationLinkTransition {
        .push(
            .init(
                dimmingColor: dimmingColor,
                preferredCornerRadius: preferredCornerRadius,
                preferredShadow: preferredShadow
            ),
            options: .init(
                isInteractive: isInteractive,
                prefersPanGesturePop: prefersPanGesturePop,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor,
                hapticsStyle: hapticsStyle
            )
        )
    }
}

@available(iOS 14.0, *)
public struct PushDestinationLinkTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a push transition.
    @frozen
    public struct Options {

        public var dimmingColor: Color?
        public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var preferredShadow: ShadowOptions?

        public init(
            dimmingColor: Color? = nil,
            preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredShadow: ShadowOptions? = nil
        ) {
            self.dimmingColor = dimmingColor
            self.preferredCornerRadius = preferredCornerRadius
            self.preferredShadow = preferredShadow
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> PushNavigationControllerTransition? {
        let transition = PushNavigationControllerTransition(
            dimmingColor: options.dimmingColor?.toUIColor(in: context.environment),
            preferredCornerRadius: options.preferredCornerRadius,
            preferredShadow: options.preferredShadow,
            isPresenting: true,
            animation: context.transaction.animation
        )
        return transition
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> PushNavigationControllerTransition? {
        let transition = PushNavigationControllerTransition(
            dimmingColor: options.dimmingColor?.toUIColor(in: context.environment),
            preferredCornerRadius: options.preferredCornerRadius,
            preferredShadow: options.preferredShadow,
            isPresenting: false,
            animation: context.transaction.animation
        )
        return transition
    }
}

@available(iOS 14.0, *)
open class PushNavigationControllerTransition: NavigationControllerTransition {

    public var dimmingColor: UIColor?
    public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?
    public var preferredShadow: ShadowOptions?

    weak var dimmingView: DimmingView?

    public init(
        dimmingColor: UIColor? = nil,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredShadow: ShadowOptions? = nil,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.dimmingColor = dimmingColor
        self.preferredCornerRadius = preferredCornerRadius
        self.preferredShadow = preferredShadow
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func finish() {
        super.finish()
        dimmingView?.isUserInteractionEnabled = false
    }

    open override func cancel() {
        super.cancel()
        dimmingView?.isUserInteractionEnabled = false
    }

    open override func animationEnded(_ transitionCompleted: Bool) {
        super.animationEnded(transitionCompleted)
        dimmingView?.removeFromSuperview()
        dimmingView = nil
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let presentedView = isPresenting ? toVC.view : fromVC.view,
            let presentingView = isPresenting ? fromVC.view : toVC.view
        else {
            transitionContext.completeTransition(false)
            return
        }

        let width = transitionContext.containerView.frame.width
        let offset = width * 0.3
        let isPresenting = isPresenting
        let preferredCornerRadius = preferredCornerRadius
        if isPresenting {
            transitionContext.containerView.addSubview(toVC.view)
        } else {
            transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        }

        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.layoutIfNeeded()

        var multiplier: CGFloat = 1
        if transitionContext.containerView.effectiveUserInterfaceLayoutDirection == .rightToLeft {
            multiplier = -1
        }
        let toVCTransform = CGAffineTransform(
            translationX: (isPresenting ? width : -offset) * multiplier,
            y: 0
        )
        let fromVCTransform = CGAffineTransform(
            translationX: (isPresenting ? -offset : width) * multiplier,
            y: 0
        )
        var dropShadowView: DropShadowView?

        if transitionContext.isAnimated {
            let dimmingView = DimmingView()
            if let dimmingColor {
                dimmingView.backgroundColor = dimmingColor
            }
            dimmingView.alpha = isPresenting ? 0 : 1
            dimmingView.isUserInteractionEnabled = isPresenting
            transitionContext.containerView.insertSubview(
                dimmingView,
                aboveSubview: presentingView
            )
            dimmingView.frame = transitionContext.containerView.frame
            self.dimmingView = dimmingView

            if !(presentedView.backgroundColor?.isTranslucent ?? true) || preferredShadow != nil {
                let shadowView = DropShadowView()
                shadowView.alpha = isPresenting ? 0 : 1
                if let preferredShadow {
                    shadowView.setShadow(preferredShadow)
                }
                transitionContext.containerView.insertSubview(
                    shadowView,
                    belowSubview: presentedView
                )
                shadowView.frame = presentedView.frame
                if isPresenting {
                    shadowView.transform = toVCTransform
                }
                dropShadowView = shadowView
            }
        }

        toVC.view.transform = toVCTransform
        let presentedVC = isPresenting ? toVC : fromVC
        if let preferredCornerRadius {
            preferredCornerRadius.setCornerRadius(to: presentedVC.view, prefersEffectiveMinimium: true)
            if let dropShadowView {
                preferredCornerRadius.setCornerRadius(to: dropShadowView, prefersEffectiveMinimium: true)
            }
        } else {
            let presentationController = transitionContext.viewController(forKey: isPresenting ? .from : .to)?._presentationController
            var presentedView = presentationController?.presentedView
            if let presentationController = presentationController as? UISheetPresentationController {
                presentedView = presentationController.presentedView?.subviews.last
            }
            #if XCODE_26
            if #available(iOS 26.0, *), let presentedView, presentedView.layer.cornerRadius > 0 || presentedView.cornerConfiguration != .identity {
                presentedVC.view.cornerConfiguration = presentedView.cornerConfiguration
                presentedVC.view.layer.cornerCurve = presentedView.layer.cornerCurve
                presentedVC.view.layer.masksToBounds = presentedView.layer.masksToBounds
                if let dropShadowView {
                    dropShadowView.cornerConfiguration = presentedView.cornerConfiguration
                    dropShadowView.layer.cornerCurve = presentedView.layer.cornerCurve
                }
            } else {
                let cornerRadius = CornerRadiusOptions.screen()
                cornerRadius.setCornerRadius(to: presentedVC.view, prefersEffectiveMinimium: true)
                if let dropShadowView {
                    cornerRadius.setCornerRadius(to: dropShadowView, prefersEffectiveMinimium: true)
                }
            }
            #else
            let cornerRadius = CornerRadiusOptions.screen()
            cornerRadius.setCornerRadius(to: presentedVC.view)
            if let dropShadowView {
                cornerRadius.setCornerRadius(to: dropShadowView)
            }
            #endif
        }

        let dimmingView = dimmingView
        animator.addAnimations {
            toVC.view.transform = .identity
            dropShadowView?.transform = isPresenting ? .identity : fromVCTransform
            dropShadowView?.alpha = isPresenting ? 1 : 0
            fromVC.view.transform = fromVCTransform
            dimmingView?.alpha = isPresenting ? 1 : 0
        }
        animator.addCompletion { animatingPosition in
            toVC.view.transform = .identity
            fromVC.view.transform = .identity
            dropShadowView?.removeFromSuperview()
            dimmingView?.removeFromSuperview()
            CornerRadiusOptions.RoundedRectangle.identity.setCornerRadius(to: presentedVC.view)
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
