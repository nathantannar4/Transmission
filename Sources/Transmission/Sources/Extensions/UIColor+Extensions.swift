//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

extension UIColor {

    var isTranslucent: Bool {
        var alpha: CGFloat = 0
        if getWhite(nil, alpha: &alpha) {
            return alpha < 1
        }
        return false
    }
}

#endif
