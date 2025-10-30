//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

open class PassthroughWindow: UIWindow {

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result == self ? nil : result
    }
}

#endif
