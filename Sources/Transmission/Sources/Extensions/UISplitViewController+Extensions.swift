//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 14.0, *)
extension UISplitViewController.DisplayMode {
    func isCollapsed(
        column: UISplitViewController.Column,
        style: UISplitViewController.Style,
        isCollapsed: Bool
    ) -> Bool {
        if isCollapsed {
            return column != .primary
        } else {
            switch self {
            case .secondaryOnly:
                return column == .secondary ? false : true
            case .oneBesideSecondary, .oneOverSecondary:
                switch style {
                case .doubleColumn:
                    return column == .supplementary ? true : false
                case .tripleColumn:
                    return column == .primary ? true : false
                default:
                    return false
                }
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                return false
            case .automatic:
                return false
            @unknown default:
                return true
            }
        }
    }
}

#endif
