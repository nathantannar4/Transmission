//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@MainActor
protocol UIViewControllerPresentationDelegate: NSObject {
    func viewControllerDidDismiss(_ viewController: UIViewController, presentingViewController: UIViewController?, animated: Bool)
}

extension UIViewController {

    private static var presentationDelegateKey: Bool = false

    var presentationDelegate: UIViewControllerPresentationDelegate? {
        get {
            guard let obj = objc_getAssociatedObject(self, &Self.presentationDelegateKey) as? ObjCWeakBox<NSObject> else {
                return nil
            }
            return obj.value as? UIViewControllerPresentationDelegate
        }
        set {
            if !Self.presentationDelegateKey {
                Self.presentationDelegateKey = true

                let original = #selector(UIViewController.dismiss(animated:completion:))
                let swizzled = #selector(UIViewController.swizzled_dismiss(animated:completion:))
                if let originalMethod = class_getInstanceMethod(UIViewController.self, original),
                   let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }

            if let box = objc_getAssociatedObject(self, &Self.presentationDelegateKey) as? ObjCWeakBox<NSObject> {
                box.value = newValue
            } else {
                let box = ObjCWeakBox<NSObject>(value: newValue)
                objc_setAssociatedObject(self, &Self.presentationDelegateKey, box, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    @objc
    func swizzled_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        var parentDelegates = [(UIViewController, UIViewControllerPresentationDelegate)]()
        var presentedDelegates = [(UIViewController, UIViewControllerPresentationDelegate)]()
        var next: UIViewController? = parent
        while let current = next {
            if let presentationDelegate = current.presentationDelegate {
                parentDelegates.append((current, presentationDelegate))
            }
            next = current.parent
        }
        next = presentedViewController
        while let current = next {
            if let presentationDelegate = current.presentationDelegate {
                presentedDelegates.append((current, presentationDelegate))
            }
            next = current.presentedViewController
        }
        let presentingViewController = presentingViewController
        swizzled_dismiss(animated: flag) {
            if self.transitionCoordinator?.isCancelled != true {
                for (viewController, delegate) in presentedDelegates.reversed() {
                    delegate.viewControllerDidDismiss(viewController, presentingViewController: presentingViewController, animated: flag)
                }

                if self.presentingViewController == nil, let delegate = self.presentationDelegate {
                    delegate.viewControllerDidDismiss(self, presentingViewController: presentingViewController, animated: flag)
                }

                for (viewController, delegate) in parentDelegates.reversed() {
                    delegate.viewControllerDidDismiss(viewController, presentingViewController: presentingViewController, animated: flag)
                }
            }
            completion?()
        }
    }
}

@MainActor
protocol UINavigationControllerPresentationDelegate: NSObject {
    func navigationController(_ navigationController: UINavigationController, didPop viewController: UIViewController, animated: Bool)
}


extension UINavigationController {

    private static var pushDelegateKey: Bool = false

    var pushDelegate: UINavigationControllerPresentationDelegate? {
        get {
            guard let obj = objc_getAssociatedObject(self, &Self.pushDelegateKey) as? ObjCWeakBox<NSObject> else {
                return nil
            }
            return obj.value as? UINavigationControllerPresentationDelegate
        }
        set {
            if !Self.pushDelegateKey {
                Self.pushDelegateKey = true

                let originalPop = #selector(UINavigationController.popViewController(animated:))
                let swizzledPop = #selector(UINavigationController.swizzled_popViewController(animated:))
                if let originalMethod = class_getInstanceMethod(UINavigationController.self, originalPop),
                   let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledPop)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }

                let originalPopTo = #selector(UINavigationController.popToViewController(_:animated:))
                let swizzledPopTo = #selector(UINavigationController.swizzled_popToViewController(_:animated:))
                if let originalMethod = class_getInstanceMethod(UINavigationController.self, originalPopTo),
                   let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledPopTo)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }

                let originalPopToRoot = #selector(UINavigationController.popToRootViewController(animated:))
                let swizzledPopToRoot = #selector(UINavigationController.swizzled_popToRootViewController(animated:))
                if let originalMethod = class_getInstanceMethod(UINavigationController.self, originalPopToRoot),
                   let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledPopToRoot)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }

                let originalSet = #selector(UINavigationController.setViewControllers(_:animated:))
                let swizzledSet = #selector(UINavigationController.swizzled_setViewControllers(_:animated:))
                if let originalMethod = class_getInstanceMethod(UINavigationController.self, originalSet),
                   let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledSet)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }

            if let box = objc_getAssociatedObject(self, &Self.pushDelegateKey) as? ObjCWeakBox<NSObject> {
                box.value = newValue
            } else {
                let box = ObjCWeakBox<NSObject>(value: newValue)
                objc_setAssociatedObject(self, &Self.pushDelegateKey, box, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    @objc
    func swizzled_popViewController(animated: Bool) -> UIViewController? {
        let vc = swizzled_popViewController(animated: animated)
        if let pushDelegate, let vc {
            pushDelegate.navigationController(self, didPop: vc, animated: animated)
        }
        return vc
    }

    @objc
    func swizzled_popToRootViewController(animated: Bool) -> [UIViewController]? {
        let vcs = swizzled_popToRootViewController(animated: animated)
        if let pushDelegate, let vcs {
            for vc in vcs.reversed() {
                pushDelegate.navigationController(self, didPop: vc, animated: animated)
            }
        }
        return vcs
    }

    @objc
    func swizzled_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let vcs = swizzled_popToViewController(viewController, animated: animated)
        if let pushDelegate, let vcs {
            for vc in vcs.reversed() {
                pushDelegate.navigationController(self, didPop: vc, animated: animated)
            }
        }
        return vcs
    }

    @objc
    func swizzled_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        let vcs = self.viewControllers
            .filter { !viewControllers.contains($0) }
        swizzled_setViewControllers(viewControllers, animated: animated)
        if let pushDelegate {
            for vc in vcs.reversed() {
                pushDelegate.navigationController(self, didPop: vc, animated: animated)
            }
        }
    }
}

#endif
