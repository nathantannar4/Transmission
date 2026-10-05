//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class NavigationControllerTransition: ViewControllerTransition {

    public override init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            isPresenting: isPresenting,
            animation: animation
        )
    }

    open override func _configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        super._configureTransitionAnimator(using: transitionContext, animator: animator)

        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            transitionContext.presentationStyle == .none
        else {
            return
        }

        let toPalettes = [
            toVC.navigationItem.topPalette,
            toVC.navigationItem.bottomPalette,
        ].compactMap { $0 }

        for palette in toPalettes {
            palette.contentView?.alpha = 0
            palette.contentView?.transform = toVC.view.transform
        }

        let toTitleView = toVC.navigationItem.titleView
        toTitleView?.layoutIfNeeded()
        toTitleView?.transform = toVC.view.transform

        let fromPalettes = [
            fromVC.navigationItem.topPalette,
            fromVC.navigationItem.bottomPalette,
        ].compactMap { $0 }

        for palette in fromPalettes {
            palette.contentView?.alpha = 1
            palette.contentView?.transform = .identity
        }

        let fromTitleView = fromVC.navigationItem.titleView
        fromTitleView?.layoutIfNeeded()
        fromTitleView?.transform = .identity

        if #available(iOS 26.0, *), !toPalettes.isEmpty || fromPalettes.isEmpty {
            UIView.fixPaletteTransition()
        }

        animator.addAnimations {
            for palette in toPalettes {
                palette.contentView?.alpha = 1
                palette.contentView?.transform = .identity
            }
            for palette in fromPalettes {
                palette.contentView?.alpha = 0
                palette.contentView?.transform = fromVC.view.transform
            }
            toTitleView?.transform = .identity

            fromTitleView?.transform = fromVC.view.transform
        }

        animator.addCompletion { _ in
            for palette in toPalettes {
                palette.contentView?.alpha = 1
                palette.contentView?.transform = .identity
            }
            for palette in fromPalettes {
                palette.contentView?.alpha = 1
                palette.contentView?.transform = .identity
            }
            fromTitleView?.transform = .identity
            fromTitleView?.alpha = 1
            toTitleView?.transform = .identity
            toTitleView?.alpha = 1
        }
    }
}

#endif
