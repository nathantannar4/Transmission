//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIWindow {
    func present(
        _ window: UIWindow,
        animated: Bool,
        transition: ((Bool) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        window.parent = self
        if window.windowLevel.rawValue > windowLevel.rawValue {
            window.makeKeyAndVisible()
        } else {
            window.isHidden = false
        }
        transition?(false)
        UIView.transition(
            with: window,
            duration: animated ? 0.35 : 0,
            options: [.curveEaseInOut, .layoutSubviews, .allowAnimatedContent]
        ) {
            transition?(true)
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
        UIView.transition(
            with: self,
            duration: animated ? 0.35 : 0,
            options: [.curveEaseInOut, .layoutSubviews, .allowAnimatedContent]
        ) {
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
