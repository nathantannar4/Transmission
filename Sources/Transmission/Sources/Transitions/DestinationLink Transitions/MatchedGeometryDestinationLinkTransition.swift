//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The matched geometry transition style.
    public static var matchedGeometry: DestinationLinkTransition {
        .matchedGeometry(.init())
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        _ transitionOptions: MatchedGeometryDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            MatchedGeometryDestinationLinkTransition(options: transitionOptions)
        )
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        preferredFromCornerRadius: CornerRadiusOptions? = nil,
        prefersZoomEffect: Bool = false,
        initialOpacity: CGFloat = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            .init(
                preferredFromCornerRadius: preferredFromCornerRadius,
                prefersZoomEffect: prefersZoomEffect,
                initialOpacity: initialOpacity
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }

    /// The matched geometry transition style.
    public static let matchedGeometryZoom: DestinationLinkTransition = .matchedGeometryZoom()

    /// The matched geometry transition style.
    public static func matchedGeometryZoom(
        preferredFromCornerRadius: CornerRadiusOptions? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            preferredFromCornerRadius: preferredFromCornerRadius,
            prefersZoomEffect: true,
            initialOpacity: 0
        )
    }
}

@available(iOS 14.0, *)
public struct MatchedGeometryDestinationLinkTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a matched geometry transition.
    @frozen
    public struct Options {

        public var preferredFromCornerRadius: CornerRadiusOptions?
        public var prefersZoomEffect: Bool
        public var initialOpacity: CGFloat

        public init(
            preferredFromCornerRadius: CornerRadiusOptions? = nil,
            prefersZoomEffect: Bool = false,
            initialOpacity: CGFloat = 1
        ) {
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.prefersZoomEffect = prefersZoomEffect
            self.initialOpacity = initialOpacity
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
    ) -> MatchedGeometryNavigationControllerTransition? {

        let transition = MatchedGeometryNavigationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: false,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: nil,
            initialOpacity: options.initialOpacity,
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
    ) -> MatchedGeometryNavigationControllerTransition? {

        let transition = MatchedGeometryNavigationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: false,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: nil,
            initialOpacity: options.initialOpacity,
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = true
        return transition
    }
}

@available(iOS 14.0, *)
open class MatchedGeometryNavigationControllerTransition: MatchedGeometryViewControllerTransition {

    open override func update(_ percentComplete: CGFloat) {
        let frictionPercentComplete = frictionCurve(percentComplete, distance: 1, coefficient: 0.75)
        super.update(frictionPercentComplete)
    }
}

#endif
