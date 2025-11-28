//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension CGAffineTransform {

    init(
        to targetRect: CGRect,
        from sourceRect: CGRect,
        preserveAspectRatio: Bool = true
    ) {
        let translateX = sourceRect.midX - targetRect.midX
        var translateY = sourceRect.midY - targetRect.midY
        let scaleX: CGFloat
        let scaleY: CGFloat
        if preserveAspectRatio {
            let x = sourceRect.width / targetRect.width
            let y = sourceRect.height / targetRect.height
            scaleX = min(x, y)
            scaleY = scaleX
            translateY -= (y - scaleY) * targetRect.height / 2
        } else {
            scaleX = sourceRect.width / targetRect.width
            scaleY = sourceRect.height / targetRect.height
        }
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
