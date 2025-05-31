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
        .asymmetric(
            push: MatchedGeometryDestinationLinkTransition(options: transitionOptions),
            pop: .default,
            options: options
        )
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        preferredFromCornerRadius: CornerRadiusOptions? = nil,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        prefersScaleEffect: Bool = false,
        prefersZoomEffect: Bool = false,
        initialOpacity: CGFloat = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            .init(
                preferredFromCornerRadius: preferredFromCornerRadius,
                preferredToCornerRadius: preferredToCornerRadius,
                prefersScaleEffect: prefersScaleEffect,
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
            prefersScaleEffect: true,
            prefersZoomEffect: true,
            initialOpacity: 0
        )
    }
}

@available(iOS 14.0, *)
public struct MatchedGeometryDestinationLinkTransition: DestinationLinkPushTransitionRepresentable {

    /// The transition options for a card transition.
    @frozen
    public struct Options {

        public var preferredFromCornerRadius: CornerRadiusOptions?
        public var preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var prefersScaleEffect: Bool
        public var prefersZoomEffect: Bool
        public var initialOpacity: CGFloat

        public init(
            preferredFromCornerRadius: CornerRadiusOptions? = nil,
            preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            prefersScaleEffect: Bool = false,
            prefersZoomEffect: Bool = false,
            initialOpacity: CGFloat = 1
        ) {
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.preferredToCornerRadius = preferredToCornerRadius
            self.prefersScaleEffect = prefersScaleEffect
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
    ) -> MatchedGeometryPresentationControllerTransition? {

        let transition = MatchedGeometryPresentationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: options.prefersScaleEffect,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
            initialOpacity: options.initialOpacity,
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }
}

#endif
