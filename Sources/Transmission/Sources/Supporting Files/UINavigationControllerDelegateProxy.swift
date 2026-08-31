//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 14.0, *)
final class UINavigationControllerDelegateProxy: NSObject, UINavigationControllerDelegate {

    nonisolated(unsafe) weak var override: UINavigationControllerDelegate?
    nonisolated(unsafe) weak var original: UINavigationControllerDelegate?

    init(override: UINavigationControllerDelegate, original: UINavigationControllerDelegate) {
        self.override = override
        self.original = original
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if original != nil, super.responds(to: aSelector) {
            return true
        }
        if let override, override.responds(to: aSelector) {
            return true
        }
        if let original, original.responds(to: aSelector) {
            return true
        }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if original != nil, super.responds(to: aSelector) {
            return nil
        }
        if let override, override.responds(to: aSelector) {
            return override
        }
        if let original, original.responds(to: aSelector) {
            return original
        }
        return nil
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        original?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
        override?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        original?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )
        override?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        if let interactionController = override?.navigationController?(navigationController, interactionControllerFor: animationController) {
            return interactionController
        }
        return original?.navigationController?(navigationController, interactionControllerFor: animationController)
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if let animationController = override?.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC) {
            return animationController
        }
        return original?.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
    }
}

#endif
