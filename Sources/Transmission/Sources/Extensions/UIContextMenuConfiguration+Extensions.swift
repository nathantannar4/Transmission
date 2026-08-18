//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

extension UIContextMenuConfiguration {

    var preferredMenuAlignment: Int {
        get {
            guard
                // preferredMenuAlignment
                let aSelector = NSStringFromBase64EncodedString("cHJlZmVycmVkTWVudUFsaWdubWVudA=="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? Int
            else {
                return 0
            }
            return value
        } set {
            guard
                // setPreferredMenuAlignment:
                let aSelector = NSStringFromBase64EncodedString("c2V0UHJlZmVycmVkTWVudUFsaWdubWVudDo="),
                responds(to: NSSelectorFromString(aSelector)),
                // preferredMenuAlignment
                let key = NSStringFromBase64EncodedString("cHJlZmVycmVkTWVudUFsaWdubWVudA==")
            else {
                return
            }
            setValue(newValue, forKey: key)
        }
    }
}

#endif
