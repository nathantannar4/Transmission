//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIViewController {

    func _popViewController(
        count: Int = 1,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard let navigationController = navigationController,
            let index = navigationController.viewControllers.firstIndex(of: self),
            index > 0
        else {
            completion?()
            return
        }

        if animated {
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
        }
        let toIndex = max(index - count, 0)
        navigationController.popToViewController(navigationController.viewControllers[toIndex], animated: animated)
        if animated {
            CATransaction.commit()
        } else {
            completion?()
        }
    }

    var _transitionCoordinator: UIViewControllerTransitionCoordinator? {
        guard let transitionCoordinator = transitionCoordinator else {
            for child in children {
                if let transitionCoordinator = child._transitionCoordinator {
                    return transitionCoordinator
                }
            }
            return nil
        }
        return transitionCoordinator
    }

    var _activePresentationController: UIPresentationController? {
        guard presentingViewController != nil else { return nil }
        let active: UIPresentationController? = {
            if #available(iOS 16.0, *), let activePresentationController {
                return activePresentationController
            }
            return presentationController
        }()
        guard active?.presentedViewController == self else { return nil }
        return active
    }
}

#endif
