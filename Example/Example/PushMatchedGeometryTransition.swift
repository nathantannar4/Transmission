//
//  PushMatchedGeometryTransition.swift
//  Example
//
//  Created by Nathan Tannar on 2025-04-02.
//

import UIKit
import SwiftUI
import Transmission

extension DestinationLinkTransition {
    static let matchedGeometry: DestinationLinkTransition = .custom(
        MatchedGeometryPushTransition()
    )
}

struct MatchedGeometryPushTransition: DestinationLinkTransitionRepresentable {

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        guard operation == .push else { return nil }
        let transition = MatchedGeometryPresentationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: false,
            prefersZoomEffect: true,
            preferredFromCornerRadius: nil,
            preferredToCornerRadius: nil,
            initialOpacity: 0,
            isPresenting: operation == .push,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }
}
