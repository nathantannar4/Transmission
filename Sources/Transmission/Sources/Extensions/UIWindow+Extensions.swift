//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

extension UIWindow {
    func present(
        _ window: UIWindow,
        animation: Animation?,
        transition: ((Bool) -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        window.parent = self
        if window.windowLevel.rawValue > windowLevel.rawValue {
            window.makeKeyAndVisible()
        } else {
            window.isHidden = false
        }
        transition?(false)
        UIView.animate(
            with: animation
        ) {
            transition?(true)
        } completion: { success in
            completion?(success)
        }
    }

    func dismiss(
        animation: Animation?,
        transition: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.resignKey()
        UIView.animate(
            with: animation
        ) {
            transition?()
        } completion: { success in
            if success {
                self.isHidden = true
                self.parent = nil
            }
            completion?(success)
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
