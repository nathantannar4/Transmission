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
        window.isHidden = false
        animations?(false)
        window.layoutIfNeeded()
        if window.windowLevel.rawValue > windowLevel.rawValue {
            UIView.animate(with: animation) {
                window.makeKeyAndVisible()
                animations?(true)
            } completion: { _ in
                completion?()
                window.layer.removeAllAnimations()
            }
        } else {
            UIView.animate(
                with: animation
            ) {
                animations?(true)
            } completion: {
                completion?()
            }
        }
    }

    func dismiss(
        animation: Animation?,
        animations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        resignKey()
        if let parent {
            windowLevel = parent.windowLevel
            rootViewController?.setNeedsStatusBarAppearanceUpdate(animated: animation != nil)
        }
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
            let box = objc_getAssociatedObject(self, unsafeBitCast(aSel, to: UnsafeRawPointer.self)) as? ObjCWeakBox<UIWindow>
            return box?.value
        }
        set {
            let aSel: Selector = #selector(getter:UIWindow.parent)
            let box = newValue.map { ObjCWeakBox(value: $0) }
            objc_setAssociatedObject(self, unsafeBitCast(aSel, to: UnsafeRawPointer.self), box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

#endif
