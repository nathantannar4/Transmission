//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIViewController {

    func _popViewController(animated: Bool) {
        guard let navigationController = navigationController,
            let index = navigationController.viewControllers.firstIndex(of: self),
            index > 0
        else {
            return
        }
        navigationController.popToViewController(navigationController.viewControllers[index - 1], animated: animated)
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
}

#endif
