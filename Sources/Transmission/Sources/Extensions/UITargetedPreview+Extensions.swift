//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UITargetedPreview {

    var prefersUnmaskedPlatterStyle: Bool {
        get {
            guard
                // prefersUnmaskedPlatterStyle
                let aSelector = NSStringFromBase64EncodedString("cHJlZmVyc1VubWFza2VkUGxhdHRlclN0eWxl"),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? Bool
            else {
                return false
            }
            return value
        } set {
            guard
                // _setPrefersUnmaskedPlatterStyle:
                let aSelector = NSStringFromBase64EncodedString("X3NldFByZWZlcnNVbm1hc2tlZFBsYXR0ZXJTdHlsZTo="),
                responds(to: NSSelectorFromString(aSelector)),
                // prefersUnmaskedPlatterStyle
                let key = NSStringFromBase64EncodedString("cHJlZmVyc1VubWFza2VkUGxhdHRlclN0eWxl")
            else {
                return
            }
            setValue(newValue, forKey: key)
        }
    }
}

#endif
