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
        animations: ((Bool) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        window.parent = self
        if window.windowLevel.rawValue > windowLevel.rawValue {
            window.makeKeyAndVisible()
        } else {
            window.isHidden = false
        }
        animations?(false)
        UIView.animate(
            with: animation
        ) {
            animations?(true)
        } completion: {
            completion?()
        }
    }

    func dismiss(
        animation: Animation?,
        animations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        self.resignKey()
        UIView.animate(
            with: animation
        ) {
            animations?()
        } completion: {
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
