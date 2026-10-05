//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIScreen {

    var displayCornerRadius: CGFloat {
        _displayCornerRadius
    }

    func displayCornerRadius(min: CGFloat = 8) -> CGFloat {
        max(min, _displayCornerRadius)
    }

    public var _displayCornerRadius: CGFloat {
        guard
            // _displayCornerRadius
            let aSelector = NSStringFromBase64EncodedString("X2Rpc3BsYXlDb3JuZXJSYWRpdXM="),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? CGFloat
        else {
            return 0
        }
        return value
    }
}

#endif
