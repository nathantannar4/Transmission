//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UINavigationController {

    func popViewController(
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        popViewController(animated: animated)
        CATransaction.commit()
    }

    func pushViewController(
        _ viewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func setViewControllers(
        _ viewControllers: [UIViewController],
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        setViewControllers(viewControllers, animated: animated)
        CATransaction.commit()
    }

    func popToViewController(
        _ viewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
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

    var interactionController: NSObject? {
        guard
            // _interactionController
            let aSelector = NSStringFromBase64EncodedString("X2ludGVyYWN0aW9uQ29udHJvbGxlcg=="),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? NSObject
        else {
            return nil
        }
        return value
    }

    var zoomInteractionController: NSObject? {
        guard
            let interactionController = interactionController,
            // _UIZoomTransitionController
            let aClass = NSClassFromBase64EncodedString("X1VJWm9vbVRyYW5zaXRpb25Db250cm9sbGVy"),
            interactionController.isKind(of: aClass)
        else {
            return nil
        }
        return interactionController
    }

    func interactiveTransitionWillEnd() {
        // UIKit disables interaction for custom transitions while interacting, but
        // does not re-enable until the animation is complete. This re-enables them
        // when the gesture ends allowing for faster responses.
        navigationBar.isUserInteractionEnabled = true
        tabBarController?.tabBar.isUserInteractionEnabled = true
        topViewController?.firstDescendent(ofType: UITabBarController.self)?.tabBar.isUserInteractionEnabled = true
    }
}

#endif
