//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

@available(iOS 18.0, *)
extension UIViewController.Transition.ZoomOptions {

    @available(iOS 26.0, *)
    var recedesPresentingView: Bool {
        get {
            // _recedesPresentingView
            guard
                let aSelector = NSStringFromBase64EncodedString("X3JlY2VkZXNQcmVzZW50aW5nVmlldw=="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? Bool
            else {
                return true
            }
            return value
        }
        set {
            // _recedesPresentingView
            guard
                let aSelector = NSStringFromBase64EncodedString("X3JlY2VkZXNQcmVzZW50aW5nVmlldw=="),
                responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            return setValue(newValue, forKey: aSelector)
        }
    }
}

#endif
