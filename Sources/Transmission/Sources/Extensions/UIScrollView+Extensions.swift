//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIScrollView {

    var contentScrollsAlongYAxis: Bool {
        guard
            // _contentScrollsAlongYAxis
            let aSelector = NSStringFromBase64EncodedString("X2NvbnRlbnRTY3JvbGxzQWxvbmdZQXhpcw=="),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? Bool
        else {
            return alwaysBounceVertical
        }
        return value
    }

    var contentScrollsAlongXAxis: Bool {
        guard
            // _contentScrollsAlongXAxis
            let aSelector = NSStringFromBase64EncodedString("X2NvbnRlbnRTY3JvbGxzQWxvbmdYQXhpcw=="),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? Bool
        else {
            return alwaysBounceHorizontal
        }
        return value
    }

    // _UIQueuingScrollView
    static let UIQueuingScrollView: AnyClass? = NSClassFromBase64EncodedString("X1VJUXVldWluZ1Njcm9sbFZpZXc=")
    var isQueuingScrollView: Bool {
        guard let aClass = Self.UIQueuingScrollView else { return false }
        return isKind(of: aClass)
    }
}

#endif
