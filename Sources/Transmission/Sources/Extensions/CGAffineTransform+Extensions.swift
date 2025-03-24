//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension CGAffineTransform {

    init(to targetRect: CGRect, from sourceRect: CGRect) {
        let scaleX = sourceRect.width / targetRect.width
        let scaleY = sourceRect.height / targetRect.height
        let translateX = sourceRect.midX - targetRect.midX
        let translateY = sourceRect.midY - targetRect.midY
        self = CGAffineTransformMake(
            scaleX,
            0,
            0,
            scaleY,
            translateX,
            translateY
        )
    }
}

#endif
