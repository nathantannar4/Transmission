//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIAlertController {

    var contentViewController: UIViewController? {
        get {
            guard
                // contentViewController
                let aSelector = NSStringFromBase64EncodedString("Y29udGVudFZpZXdDb250cm9sbGVy"),
                responds(to: NSSelectorFromString(aSelector)),
                let contentViewController = value(forKey: aSelector) as? UIViewController
            else {
                return nil
            }
            return contentViewController
        } set {
            guard
                // setContentViewController:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0Q29udGVudFZpZXdDb250cm9sbGVyOg=="),
                responds(to: aSelector)
            else {
                return
            }
            perform(aSelector, with: newValue)
        }
    }
}

#endif
