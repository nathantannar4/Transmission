//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UISearchController {

    @available(iOS 26.0, *)
    public var searchIconBarButtonItem: UIBarButtonItem? {
        guard
            // _searchIconBarButtonItem
            let aSelector = NSStringFromBase64EncodedString("X3NlYXJjaEljb25CYXJCdXR0b25JdGVt"),
            searchBar.responds(to: NSSelectorFromString(aSelector)),
            let value = searchBar.value(forKey: aSelector) as? UIBarButtonItem
        else {
            return nil
        }
        return value
    }
}

#endif
