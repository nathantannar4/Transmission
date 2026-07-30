//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIPopoverPresentationController {

    var shadowView: UIView? {
        guard
            // _shadowView
            let aSelector = NSStringFromBase64EncodedString("X3NoYWRvd1ZpZXc="),
            responds(to: NSSelectorFromString(aSelector)),
            let dropShadowView = value(forKey: aSelector) as? UIView
        else {
            return nil
        }
        return dropShadowView
    }
}

#endif
