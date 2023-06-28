//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 15.0, *)
@available(xrOS, unavailable)
extension UISheetPresentationController.Detent {
    var id: String? {
        if #available(iOS 16.0, *) {
            return identifier.rawValue
        } else {
            if responds(to: NSSelectorFromString("_identifier")),
               let identifier = value(forKey: "_identifier") as? String
            {
                return identifier
            } else {
                return nil
            }
        }
    }

    var isDynamic: Bool {
        guard let id = id else {
            return false
        }
        switch id {
        case UISheetPresentationController.Detent.Identifier.large.rawValue,
            UISheetPresentationController.Detent.Identifier.medium.rawValue:
            return false
        default:
            if responds(to: NSSelectorFromString("_constant")),
               let constant = value(forKey: "_constant") as? CGFloat,
               constant > 0
            {
                return false
            }
            return true
        }
    }
}

#endif
