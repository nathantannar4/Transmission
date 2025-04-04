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
                preferredCornerRadius: preferredCornerRadius,
                preferredPresentationShadow: preferredPresentationBackgroundColor == .clear ? .clear : .prominent
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
        public var preferredCornerRadius: CGFloat?
        public var preferredPresentationShadow: PresentationLinkTransition.Shadow

        public init(
            edge: Edge = .bottom,
            prefersScaleEffect: Bool = true,
            preferredCornerRadius: CGFloat? = nil,
            preferredPresentationShadow: PresentationLinkTransition.Shadow = .prominent
        ) {
            self.edge = edge
            self.prefersScaleEffect = prefersScaleEffect
            self.preferredCornerRadius = preferredCornerRadius
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
            preferredCornerRadius: options.preferredCornerRadius,
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

    public var preferredCornerRadius: CGFloat? {
        didSet {
            guard oldValue != preferredCornerRadius else { return }
            cornerRadiusDidChange()
        }
    }

    open override var wantsInteractiveDismissal: Bool {
        return false
    }

    open override var presentationStyle: UIModalPresentationStyle {
        .overFullScreen
    }

    private var cornerRadius: CGFloat {
        preferredCornerRadius ?? max(12, UIScreen.main.displayCornerRadius)
    }

    public init(
        edge: Edge = .bottom,
        preferredCornerRadius: CGFloat? = nil,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        self.preferredCornerRadius = preferredCornerRadius
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        return .identity
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.layer.cornerCurve = .continuous
        cornerRadiusDidChange()
        dimmingView.isHidden = false
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        cornerRadiusDidChange()
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        presentingViewController.view.isHidden = presentedViewController.presentedViewController != nil
    }

    private func cornerRadiusDidChange() {
        presentedViewController.view.layer.cornerRadius = cornerRadius
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
///     let transition = SlidePresentationControllerTransition(
///         edge: options.edge,
///         prefersScaleEffect: options.prefersScaleEffect,
///         presentationBackgroundColor: options.options.preferredPresentationBackgroundUIColor,
///         isPresenting: true,
///         animation: animation
///     )
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
///     let transition = SlidePresentationControllerTransition(
///         edge: options.edge,
///         prefersScaleEffect: options.prefersScaleEffect,
///         presentationBackgroundColor: options.options.preferredPresentationBackgroundUIColor,
///         isPresenting: false,
///         animation: animation
///     )
///     transition.wantsInteractiveStart = options.options.isInteractive && presentationController.wantsInteractiveTransition
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

    static let displayCornerRadius: CGFloat = {
        #if targetEnvironment(macCatalyst)
        return 12
        #else
        return max(UIScreen.main.displayCornerRadius, 12)
        #endif
    }()

    public init(
        edge: Edge,
        prefersScaleEffect: Bool = true,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        self.prefersScaleEffect = prefersScaleEffect
        super.init(isPresenting: isPresenting, animation: animation)
    }

    public override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let isPresenting = isPresenting
        let animator = UIViewPropertyAnimator(animation: animation) ?? UIViewPropertyAnimator(duration: duration, curve: completionCurve)

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        let frame = transitionContext.finalFrame(for: presented)
        #if targetEnvironment(macCatalyst)
        let isScaleEnabled = false
        #else
        let isTranslucentBackground = presented.view.backgroundColor?.isTranslucent ?? false
        let isScaleEnabled = prefersScaleEffect && !isTranslucentBackground && presenting.view.convert(presenting.view.frame.origin, to: nil).y == 0 &&
            frame.origin.y == 0
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
        } else {
            #if !targetEnvironment(macCatalyst)
            if isScaleEnabled {
                presenting.view.transform = dzTransform
                presenting.view.layer.cornerRadius = Self.displayCornerRadius
            }
            #endif
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
                presenting.view.layer.cornerRadius = isPresenting ? Self.displayCornerRadius : 0
            }
        }
        animator.addCompletion { animatingPosition in
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = 0
                presenting.view.layer.masksToBounds = true
                presenting.view.transform = .identity
            }

            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        return animator
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
