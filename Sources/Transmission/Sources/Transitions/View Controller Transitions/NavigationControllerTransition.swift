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
            transitionContext.presentationStyle == .none,
            let navigationController = fromVC.navigationController
        else {
            return
        }

        let isPresenting = isPresenting
        let toTransfrom = CGAffineTransform(translationX: toVC.view.transform.tx, y: 0)

        let toPalettes = [
            toVC.navigationItem.topPalette,
            toVC.navigationItem.bottomPalette,
        ].compactMap { $0 }

        for palette in toPalettes {
            palette.contentView?.transform = toTransfrom
            palette.contentView?.alpha = 0
        }

        let toTitleView = toVC.navigationItem.titleView
        toTitleView?.layoutIfNeeded()
        toTitleView?.alpha = 0
        toTitleView?.transform = toTransfrom

        let fromPalettes = [
            fromVC.navigationItem.topPalette,
            fromVC.navigationItem.bottomPalette,
        ].compactMap { $0 }

        for palette in fromPalettes {
            palette.isTransitioning = true
            palette.contentView?.transform = .identity
            palette.contentView?.alpha = 1
        }

        let fromTitleView = fromVC.navigationItem.titleView
        fromTitleView?.layoutIfNeeded()
        fromTitleView?.alpha = 1
        fromTitleView?.transform = .identity

        func getNavigationSearchBar(item: UINavigationItem) -> UISearchBar? {
            guard let searchController = item.searchController else {
                return nil
            }
            if #available(iOS 16.0, *), item.searchBarPlacement == .stacked {
                return searchController.searchBar
            } else {
                return searchController.searchBar
            }
        }

        let fromSearchBar = getNavigationSearchBar(item: fromVC.navigationItem)
        let toSearchBar = getNavigationSearchBar(item: toVC.navigationItem)

        let toSearchBarTransform: CGAffineTransform = {
            var transfrom = toTransfrom
            if transfrom.tx > 0 {
                transfrom.tx = navigationController.navigationBar.bounds.width
            } else if transfrom.tx < 0 {
                transfrom.tx = -navigationController.navigationBar.bounds.width
            }
            return transfrom
        }()

        var shouldAnimateSearchBars = true
#if XCODE_26
        if #available(iOS 26.0, *), fromSearchBar != nil, toSearchBar != nil {
            shouldAnimateSearchBars = false
        }
#endif
        if shouldAnimateSearchBars {
            fromSearchBar?.alpha = 1
            fromSearchBar?.transform = .identity
            toSearchBar?.alpha = 0
            toSearchBar?.transform = toSearchBarTransform
        }
#if XCODE_26
        if #available(iOS 26.0, *), !toPalettes.isEmpty || !fromPalettes.isEmpty {
            UIView.fixPaletteTransition()
        }

        // Fix glass appearance on push
        if #available(iOS 26.0, *), toSearchBar != nil, let transitionCoordinator = toVC.transitionCoordinator {
            let fromSearchController = fromVC.navigationItem.searchController
            let fromPlacement = fromVC.navigationItem.preferredSearchBarPlacement
            let fromAllowsToolbarIntegration = fromVC.navigationItem.searchBarPlacementAllowsToolbarIntegration
            fromVC.navigationItem.searchController = toVC.navigationItem.searchController
            fromVC.navigationItem.preferredSearchBarPlacement = toVC.navigationItem.preferredSearchBarPlacement
            fromVC.navigationItem.searchBarPlacementAllowsToolbarIntegration = toVC.navigationItem.searchBarPlacementAllowsToolbarIntegration
            let onFinish: () -> Void = {
                fromVC.navigationItem.searchController = fromSearchController
                fromVC.navigationItem.preferredSearchBarPlacement = fromPlacement
                fromVC.navigationItem.searchBarPlacementAllowsToolbarIntegration = fromAllowsToolbarIntegration
            }
            transitionCoordinator.notifyWhenInteractionChanges { ctx in
                if ctx.isCancelled {
                    onFinish()
                }
            }
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                onFinish()
            }
        }
#endif

        animator.addAnimations {
            let fromTransfrom = CGAffineTransform(translationX: fromVC.view.transform.tx, y: 0)
            for palette in toPalettes {
                palette.contentView?.transform = .identity
                palette.contentView?.alpha = 1
            }
            for palette in fromPalettes {
                palette.contentView?.transform = fromTransfrom
                palette.contentView?.alpha = 0
            }
            toTitleView?.alpha = 1
            toTitleView?.transform = .identity
            fromTitleView?.alpha = 0
            fromTitleView?.transform = fromTransfrom
            if shouldAnimateSearchBars {
                let fromSearchBarTransform: CGAffineTransform = {
                    var transfrom = fromTransfrom
                    if transfrom.tx > 0 {
                        transfrom.tx = navigationController.navigationBar.bounds.width
                    } else if transfrom.tx < 0 {
                        transfrom.tx = -navigationController.navigationBar.bounds.width
                    }
                    return transfrom
                }()
                toSearchBar?.alpha = 1
                toSearchBar?.transform = .identity
                fromSearchBar?.alpha = 0
                fromSearchBar?.transform = fromSearchBarTransform
            }
        }

        animator.addCompletion { position in
            for palette in toPalettes {
                palette.contentView?.transform = .identity
            }
            for palette in fromPalettes {
                palette.contentView?.transform = .identity
            }
            toTitleView?.alpha = 1
            toTitleView?.transform = .identity
            fromTitleView?.alpha = 1
            fromTitleView?.transform = .identity
            toSearchBar?.alpha = 1
            toSearchBar?.transform = .identity
            fromSearchBar?.alpha = 1
            fromSearchBar?.transform = .identity

#if XCODE_26
            // Fix glass rendering
            if #available(iOS 26.0, *), position == .start, let searchController = fromVC.navigationItem.searchController {
                fromVC.navigationItem.searchController = nil
                fromVC.navigationItem.searchController = searchController
            }
#endif
        }
    }
}

#if XCODE_26
extension UIView {

    private static var didFixPaletteTransition = false
    @available(iOS 26.0, *)
    static func fixPaletteTransition() {
        guard !didFixPaletteTransition else { return }
        didFixPaletteTransition = true
        guard
            // _UINavigationBarPalette
            let paletteViewClass = NSClassFromBase64EncodedString("X1VJTmF2aWdhdGlvbkJhclBhbGV0dGU=") as? UIView.Type
                else {
            return
        }
        swizzle(
            target: paletteViewClass,
            source: paletteViewClass,
            aSelector: #selector(UIView.snapshotView(afterScreenUpdates:)),
            aSwizzledSelector: #selector(UIView.swizzled_snapshotView(afterScreenUpdates:))
        )
    }

    @objc
    func swizzled_snapshotView(afterScreenUpdates: Bool) -> UIView? {
        guard
            let palette = self as? _UINavigationBarPalette,
            palette.isTransitioning,
            palette.contentView?.layer.animationKeys()?.isEmpty == false
        else {
            return swizzled_snapshotView(afterScreenUpdates: afterScreenUpdates)
        }
        // Force live render so custom transition animations can animate it
        return self
    }
}
#endif

#endif
