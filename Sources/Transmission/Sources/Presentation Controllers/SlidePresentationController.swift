//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The slide presentation style.
    public static var slide: PresentationLinkTransition = .slide()

    /// The slide presentation style.
    public static func slide(
        _ transitionOptions: SlidePresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init(
            modalPresentationCapturesStatusBarAppearance: true
        )
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            SlidePresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The slide presentation style.
    public static func slide(
        edge: Edge = .bottom,
        prefersScaleEffect: Bool = true,
        preferredCornerRadius: CGFloat? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .slide(
            .init(
                edge: edge,
                prefersScaleEffect: prefersScaleEffect,
                preferredFromCornerRadius: preferredCornerRadius,
                preferredPresentationShadow: preferredPresentationBackgroundColor == .clear ? .clear : .minimal
            ),
            options: .init(
                isInteractive: isInteractive,
                modalPresentationCapturesStatusBarAppearance: true,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct SlidePresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a card transition.
    @frozen
    public struct Options {

        public var edge: Edge
        public var prefersScaleEffect: Bool
        public var preferredFromCornerRadius: CGFloat?
        public var preferredToCornerRadius: CGFloat?
        public var preferredPresentationShadow: PresentationLinkTransition.Shadow

        public init(
            edge: Edge = .bottom,
            prefersScaleEffect: Bool = true,
            preferredFromCornerRadius: CGFloat? = nil,
            preferredToCornerRadius: CGFloat? = nil,
            preferredPresentationShadow: PresentationLinkTransition.Shadow = .minimal
        ) {
            self.edge = edge
            self.prefersScaleEffect = prefersScaleEffect
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.preferredToCornerRadius = preferredToCornerRadius
            self.preferredPresentationShadow = preferredPresentationShadow
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        context: Context
    ) -> SlidePresentationController {
        let presentationController = SlidePresentationController(
            edge: options.edge,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.presentedViewShadow = options.preferredPresentationShadow
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: SlidePresentationController,
        context: Context
    ) {
        presentationController.edge = options.edge
        presentationController.presentedViewShadow = options.preferredPresentationShadow
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let transition = SlidePresentationControllerTransition(
            edge: options.edge,
            prefersScaleEffect: options.prefersScaleEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let presentationController = dismissed.presentationController as? InteractivePresentationController else {
            return nil
        }
        let transition = SlidePresentationControllerTransition(
            edge: options.edge,
            prefersScaleEffect: options.prefersScaleEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }
}

/// A presentation controller that presents the view in a full screen sheet
@available(iOS 14.0, *)
open class SlidePresentationController: InteractivePresentationController {

    public var edge: Edge

    public override var edges: Edge.Set {
        get { Edge.Set(edge) }
        set { }
    }

    open override var wantsInteractiveDismissal: Bool {
        return prefersInteractiveDismissal
    }

    open override var presentationStyle: UIModalPresentationStyle {
        .overFullScreen
    }

    public init(
        edge: Edge = .bottom,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        dimmingView.isHidden = false
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        if prefersInteractiveDismissal {
            return super.presentedViewTransform(for: translation)
        }
        return .identity
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        if transform.isIdentity {
            presentedViewController.view.layer.cornerRadius = 0
            updateShadow(progress: 0)
        } else {
            presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius()
            let progress = max(0, min(transform.d, 1))
            updateShadow(progress: progress)
        }
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.layer.cornerCurve = .continuous
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        presentingViewController.view.isHidden = presentedViewController.presentedViewController != nil
    }
}

/// An interactive transition built for the ``SlidePresentationController``.
///
/// ```
/// func animationController(
///     forPresented presented: UIViewController,
///     presenting: UIViewController,
///     source: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     let transition = SlidePresentationControllerTransition(...)
///     transition.wantsInteractiveStart = false
///     return transition
/// }
///
/// func animationController(
///     forDismissed dismissed: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     guard let presentationController = dismissed.presentationController as? SlidePresentationController else {
///         return nil
///     }
///     let transition = SlidePresentationControllerTransition(...)
///     transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
///     presentationController.transition(with: transition)
///     return transition
/// }
///
/// func interactionControllerForDismissal(
///     using animator: UIViewControllerAnimatedTransitioning
/// ) -> UIViewControllerInteractiveTransitioning? {
///     return animator as? SlidePresentationControllerTransition
/// }
/// ```
///
@available(iOS 14.0, *)
open class SlidePresentationControllerTransition: PresentationControllerTransition {

    public var edge: Edge
    public var prefersScaleEffect: Bool
    public var preferredFromCornerRadius: CGFloat?
    public var preferredToCornerRadius: CGFloat?

    public init(
        edge: Edge,
        prefersScaleEffect: Bool = true,
        preferredFromCornerRadius: CGFloat?,
        preferredToCornerRadius: CGFloat?,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        self.prefersScaleEffect = prefersScaleEffect
        self.preferredFromCornerRadius = preferredFromCornerRadius
        self.preferredToCornerRadius = preferredToCornerRadius
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        let isPresenting = isPresenting
        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let frame = transitionContext.finalFrame(for: presented)
        #if targetEnvironment(macCatalyst)
        let isScaleEnabled = false
        let toCornerRadius = preferredToCornerRadius ?? 0
        let fromCornerRadius = preferredFromCornerRadius ?? 0
        #else
        let isTranslucentBackground = presented.view.backgroundColor?.isTranslucent ?? false
        let isScaleEnabled = prefersScaleEffect && !isTranslucentBackground && presenting.view.convert(presenting.view.frame.origin, to: nil).y == 0 &&
            frame.origin.y == 0
        let toCornerRadius = preferredToCornerRadius ?? UIScreen.main.displayCornerRadius(min: 0)
        let fromCornerRadius = preferredFromCornerRadius ?? (preferredToCornerRadius ?? UIScreen.main.displayCornerRadius())
        #endif
        let safeAreaInsets = transitionContext.containerView.safeAreaInsets

        var dzTransform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        switch edge {
        case .top:
            dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.bottom / 2)
        case .bottom:
            dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.top / 2)
        case .leading:
            switch presented.traitCollection.layoutDirection {
            case .rightToLeft:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.left / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.right / 2)
            }
        case .trailing:
            switch presented.traitCollection.layoutDirection {
            case .leftToRight:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.right / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.left / 2)
            }
        }

        presenting.view.layer.cornerCurve = .continuous
        presenting.view.layer.masksToBounds = true

        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = frame
            presented.view.transform = presentationTransform(
                presented: presented,
                frame: frame
            )
            presented.view.layer.cornerRadius = fromCornerRadius
        } else {
            #if !targetEnvironment(macCatalyst)
            if isScaleEnabled {
                presenting.view.transform = dzTransform
                presenting.view.layer.cornerRadius = UIScreen.main.displayCornerRadius()
            }
            #endif
            presented.view.layer.cornerRadius = toCornerRadius
        }

        let presentedTransform = isPresenting ? .identity : presentationTransform(
            presented: presented,
            frame: frame
        )
        let presentingTransform = isPresenting && isScaleEnabled ? dzTransform : .identity
        animator.addAnimations {
            presented.view.transform = presentedTransform
            presenting.view.transform = presentingTransform
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = isPresenting ? UIScreen.main.displayCornerRadius() : 0
            }
        }
        animator.addCompletion { animatingPosition in
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = 0
                presenting.view.layer.masksToBounds = true
                presenting.view.transform = .identity
            }
            presented.view.layer.cornerRadius = 0
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
    }

    private func presentationTransform(
        presented: UIViewController,
        frame: CGRect
    ) -> CGAffineTransform {
        switch edge {
        case .top:
            return CGAffineTransform(translationX: 0, y: -frame.maxY)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: frame.maxY)
        case .leading:
            switch presented.traitCollection.layoutDirection {
            case .rightToLeft:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        case .trailing:
            switch presented.traitCollection.layoutDirection {
            case .leftToRight:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        }
    }
}

#endif
