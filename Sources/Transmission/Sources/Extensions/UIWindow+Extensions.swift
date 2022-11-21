//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIWindow {
    func present(
        _ window: UIWindow,
        animated: Bool,
        transition: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        window.parent = self
        if window.windowLevel.rawValue > windowLevel.rawValue {
            window.makeKeyAndVisible()
        } else {
            window.isHidden = false
        }
        window.alpha = min(window.alpha, window.alpha)
        UIView.transition(
            with: self,
            duration: animated ? 0.35 : 0,
            options: [.curveEaseInOut]
        ) {
            window.alpha = 1
            transition?()
        } completion: { _ in
            completion?()
        }
    }

    func dismiss(
        animated: Bool,
        transition: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        self.resignKey()
        self.alpha = 1
        UIView.transition(
            with: self,
            duration: animated ? 0.35 : 0,
            options: [.curveEaseInOut]
        ) {
            self.alpha = 0.999
            transition?()
        } completion: { _ in
            self.isHidden = true
            self.parent = nil
            completion?()
        }
    }

    var presentedViewController: UIViewController? {
        var viewController = rootViewController
        while let next = viewController?.presentedViewController {
            viewController = next
        }
        return viewController
    }

    @objc
    var parent: UIWindow? {
        get {
            let aSel: Selector = #selector(getter:UIWindow.parent)
            return objc_getAssociatedObject(self, unsafeBitCast(aSel, to: UnsafeRawPointer.self)) as? UIWindow
        }
        set {
            let aSel: Selector = #selector(getter:UIWindow.parent)
            objc_setAssociatedObject(self, unsafeBitCast(aSel, to: UnsafeRawPointer.self), newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

#endif
