//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

protocol UIViewControllerPresentationDelegate: NSObject {
    func viewControllerDidDismiss()
}

extension UIViewController {

    private static var viewDidDisappearKey: Bool = false

    var presentationDelegate: UIViewControllerPresentationDelegate? {
        get {
            guard let obj = objc_getAssociatedObject(self, &Self.viewDidDisappearKey) as? ObjCWeakBox<NSObject> else {
                return nil
            }
            return obj.value as? UIViewControllerPresentationDelegate
        }
        set {
            if !Self.viewDidDisappearKey {
                Self.viewDidDisappearKey = true

                let original = #selector(UIViewController.viewDidDisappear(_:))
                let swizzled = #selector(UIViewController.swizzled_viewDidDisappear(_:))
                if let originalMethod = class_getInstanceMethod(UIViewController.self, original),
                   let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }

            if let box = objc_getAssociatedObject(self, &Self.viewDidDisappearKey) as? ObjCWeakBox<NSObject> {
                box.value = newValue
            } else {
                let box = ObjCWeakBox<NSObject>(value: newValue)
                objc_setAssociatedObject(self, &Self.viewDidDisappearKey, box, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    @objc
    func swizzled_viewDidDisappear(_ animated: Bool) {
        if isBeingDismissed || isMovingFromParent, let presentationDelegate = presentationDelegate {
            presentationDelegate.viewControllerDidDismiss()
        }

        swizzled_viewDidDisappear(animated)
    }
}

#endif
