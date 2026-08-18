//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import Engine

extension UIViewController {

    func _popViewController(
        count: Int = 1,
        animated: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard
            let navigationController = navigationController,
            let index = navigationController.viewControllers.firstIndex(of: self),
            index > 0 || navigationController.viewControllers.count > 1
        else {
            completion?(false)
            return
        }
        let completion: () -> Void = {
            navigationController.interactiveTransitionWillEnd()
            completion?(true)
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
            completion()
        }
    }

    func _dismiss(
        count: Int = 1,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        let targetViewController = {
            var remaining = count
            var presentingViewController = self
            if remaining == 1, presentingViewController.presentedViewController == nil {
                remaining -= 1
            }
            while remaining > 0, let next = presentingViewController.presentingViewController {
                presentingViewController = next
                remaining -= 1
            }
            return presentingViewController
        }()
        targetViewController.dismiss(animated: animated, completion: completion)
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

    var _navigationController: UINavigationController? {
        if let navigationController {
            return navigationController
        }
        if let next = view.superview?.viewController {
            return next as? UINavigationController ?? next.navigationController
        }
        return nil
    }

    var _presentationController: UIPresentationController? {
        var ancestor = self
        while let parent = ancestor.parent {
            ancestor = parent
        }
        guard ancestor.presentingViewController != nil else { return nil }
        if #available(iOS 16.0, *), let activePresentationController = ancestor.activePresentationController {
            return activePresentationController
        }
        return ancestor.presentationController
    }

    public var _contentScrollView: UIScrollView? {
        contentScrollView
    }

    var contentScrollView: UIScrollView? {
        view.firstDescendent(ofType: UIScrollView.self) { scrollView in
            return scrollView.contentScrollsAlongYAxis
        }
    }

    public func _firstDescendent<T: UIViewController>(ofType type: T.Type) -> T? {
        firstDescendent(ofType: type)
    }

    func firstDescendent<T: UIViewController>(ofType type: T.Type) -> T? {
        for child in children {
            if let match = child as? T {
                return match
            } else if let match = child.firstDescendent(ofType: type) {
                return match
            }
        }
        return nil
    }

    func isDescendent(of ancestor: UIViewController) -> Bool {
        var parent = parent
        while parent != nil {
            if parent == ancestor {
                return true
            }
            parent = parent?.parent
        }
        return false
    }

    func fixSwiftUIHitTesting() {
        if let tabBarController = self as? UITabBarController {
            tabBarController.selectedViewController?.fixSwiftUIHitTesting()
        } else if let navigationController = self as? UINavigationController {
            navigationController.topViewController?.fixSwiftUIHitTesting()
        } else if let splitViewController = self as? UISplitViewController {
            for viewController in splitViewController.viewControllers {
                viewController.fixSwiftUIHitTesting()
            }
        } else if let pageViewController = self as? UIPageViewController {
            for viewController in pageViewController.viewControllers ?? [] {
                viewController.fixSwiftUIHitTesting()
            }
        } else if let view = viewIfLoaded {
            // This fixes SwiftUI's gesture handling that can get messed up when applying
            // transforms and/or frame changes during an interactive presentation. This resets
            // SwiftUI's geometry in a clean way, fixing hit testing.
            let frame = view.frame
            view.frame = .zero
            view.frame = frame
        }
    }

    var firstResponder: UIResponder? {
        guard let firstReponder = UIResponder._current, firstReponder._isInResponderChain(of: self) else { return nil }
        return firstReponder
    }
}

#endif
