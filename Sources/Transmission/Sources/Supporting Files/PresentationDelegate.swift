//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

protocol UIViewControllerPresentationDelegate: NSObject {
    func viewControllerDidDismiss()
}

extension UIViewController {

    private static var dismissViewControllerKey: Bool = false

    var presentationDelegate: UIViewControllerPresentationDelegate? {
        get {
            guard let obj = objc_getAssociatedObject(self, &Self.dismissViewControllerKey) as? ObjCWeakBox<NSObject> else {
                return nil
            }
            return obj.value as? UIViewControllerPresentationDelegate
        }
        set {
            if !Self.dismissViewControllerKey {
                Self.dismissViewControllerKey = true

                let original = #selector(UIViewController.dismiss(animated:completion:))
                let swizzled = #selector(UIViewController.swizzled_dismiss(animated:completion:))
                if let originalMethod = class_getInstanceMethod(UIViewController.self, original),
                   let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }

            if let box = objc_getAssociatedObject(self, &Self.dismissViewControllerKey) as? ObjCWeakBox<NSObject> {
                box.value = newValue
            } else {
                let box = ObjCWeakBox<NSObject>(value: newValue)
                objc_setAssociatedObject(self, &Self.dismissViewControllerKey, box, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    @objc
    func swizzled_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        swizzled_dismiss(animated: flag) {
            if let presentationDelegate = self.presentationDelegate {
                presentationDelegate.viewControllerDidDismiss()
            }
            completion?()
        }
    }
}

#endif
