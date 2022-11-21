//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIView {
    var viewController: UIViewController? {
        _viewController
    }

    public var _viewController: UIViewController? {
        var responder: UIResponder? = next
        while responder != nil, !(responder is UIViewController) {
            responder = responder?.next
        }
        return responder as? UIViewController
    }
}

#endif
