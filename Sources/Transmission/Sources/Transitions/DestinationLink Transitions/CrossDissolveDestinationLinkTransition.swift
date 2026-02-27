//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The cross dissolve transition style.
    public static var crossDissolve: DestinationLinkTransition {
        .crossDissolve(.init())
    }

    /// The cross dissolve transition style.
    public static func crossDissolve(
        _ transitionOptions: CrossDissolveDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init(
            prefersPanGesturePop: true
        )
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            CrossDissolveDestinationLinkTransition(
                options: transitionOptions
            )
        )
    }

    /// The cross dissolve transition style.
    public static func crossDissolve(
        prefersPanGesturePop: Bool = true,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .crossDissolve(
            .init(
            ),
            options: .init(
                isInteractive: isInteractive,
                prefersPanGesturePop: prefersPanGesturePop,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }
}

@available(iOS 14.0, *)
public struct CrossDissolveDestinationLinkTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a cross dissolve transition.
    @frozen
    public struct Options: Sendable {

        public init() { }
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
    ) -> CrossDissolveNavigationControllerTransition? {
        let transition = CrossDissolveNavigationControllerTransition(
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> CrossDissolveNavigationControllerTransition? {
        let transition = CrossDissolveNavigationControllerTransition(
            isPresenting: false,
            animation: context.transaction.animation
        )
        return transition
    }
}

@available(iOS 14.0, *)
open class CrossDissolveNavigationControllerTransition: ViewControllerTransition {

    public override init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            isPresenting: isPresenting,
            animation: animation
        )
    }
}

#endif
