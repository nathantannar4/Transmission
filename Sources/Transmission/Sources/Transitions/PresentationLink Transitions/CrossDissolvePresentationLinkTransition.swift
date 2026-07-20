//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The cross dissolve presentation style.
    public static let crossDissolve: PresentationLinkTransition = .crossDissolve()

    /// The cross dissolve presentation style.
    public static func crossDissolve(
        _ transitionOptions: CrossDissolvePresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init(
            modalPresentationCapturesStatusBarAppearance: true
        )
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            CrossDissolvePresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The cross dissolve transition style.
    public static func crossDissolve(
        transform: CGAffineTransform = .identity,
        fromCornerRadius: CornerRadiusOptions? = nil,
        toCornerRadius: CornerRadiusOptions? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .crossDissolve(
            .init(
                transform: transform,
                fromCornerRadius: fromCornerRadius,
                toCornerRadius: toCornerRadius,
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct CrossDissolvePresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a cross dissolve transition.
    @frozen
    public struct Options: Sendable {

        public var transform: CGAffineTransform
        public var fromCornerRadius: CornerRadiusOptions?
        public var toCornerRadius: CornerRadiusOptions?

        public init(
            transform: CGAffineTransform = .identity,
            fromCornerRadius: CornerRadiusOptions? = nil,
            toCornerRadius: CornerRadiusOptions? = nil
        ) {
            self.transform = transform
            self.fromCornerRadius = fromCornerRadius
            self.toCornerRadius = toCornerRadius
        }
    }

    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> InteractivePresentationController {
        let presentationController = InteractivePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: InteractivePresentationController,
        context: Context
    ) {
        var edges: Edge.Set = []
        if options.transform.ty > 0 {
            edges.formUnion(.bottom)
        }
        if options.transform.ty < 0 {
            edges.formUnion(.top)
        }
        if options.transform.tx < 0 {
            edges.formUnion(.leading)
        }
        if options.transform.tx > 0 {
            edges.formUnion(.trailing)
        }
        presentationController.edges = edges
        presentationController.isInteractive = context.options.isInteractive
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> CrossDissolveControllerTransition? {
        let transition = CrossDissolveControllerTransition(
            transform: options.transform,
            fromCornerRadius: options.fromCornerRadius,
            toCornerRadius: options.toCornerRadius,
            isPresenting: true,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PercentDrivenInteractivePresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> CrossDissolveControllerTransition? {
        let transition = CrossDissolveControllerTransition(
            transform: options.transform,
            fromCornerRadius: options.fromCornerRadius,
            toCornerRadius: options.toCornerRadius,
            isPresenting: false,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PercentDrivenInteractivePresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }
}

@available(iOS 14.0, *)
open class CrossDissolveControllerTransition: PresentationControllerTransition {

    public let transform: CGAffineTransform
    public let fromCornerRadius: CornerRadiusOptions?
    public let toCornerRadius: CornerRadiusOptions?

    private weak var presentedView: UIView?

    public init(
        transform: CGAffineTransform = .identity,
        fromCornerRadius: CornerRadiusOptions? = nil,
        toCornerRadius: CornerRadiusOptions? = nil,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.transform = transform
        self.fromCornerRadius = fromCornerRadius
        self.toCornerRadius = toCornerRadius
        super.init(
            isPresenting: isPresenting,
            animation: animation
        )
    }

    open override func cancel() {
        super.cancel()
        presentedView?.isUserInteractionEnabled = false
    }

    open override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        presentedView = transitionContext.view(forKey: isPresenting ? .to : .from)

        let transition = CrossDissolveTransitionAnimator(
            transform: transform,
            fromCornerRadius: fromCornerRadius,
            toCornerRadius: toCornerRadius
        )
        transition.animateTransition(with: animator, using: transitionContext, isPresenting: isPresenting)
    }
}

#endif
