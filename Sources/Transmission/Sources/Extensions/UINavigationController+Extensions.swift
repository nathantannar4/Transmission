//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UINavigationController {
    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        popViewController(animated: animated)
        CATransaction.commit()
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool, _ completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func popToViewController(_ viewController: UIViewController, animated: Bool, _ completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        popToViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func popToRootViewController(animated: Bool, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        popToRootViewController(animated: animated)
        CATransaction.commit()
    }
}

#endif
