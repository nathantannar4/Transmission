//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

extension UIColor {

    var alpha: CGFloat {
        var alpha: CGFloat = 0
        if getWhite(nil, alpha: &alpha) {
            return alpha
        }
        return 1
    }

    var isTranslucent: Bool {
        return alpha < 1
    }
}

#endif
