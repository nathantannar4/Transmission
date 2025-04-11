//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIView {
    var viewController: UIViewController? {
        _viewController
    }

    public var _viewController: UIViewController? {
        var responder: UIResponder? = next
        while responder != nil, !(responder is UIViewController) {
            responder = responder?.next
        }
        return responder as? UIViewController
    }

    var idealSize: CGSize {
        let idealHeight = idealHeight(for: frame.width)
        if idealHeight == 0 {
            return intrinsicContentSize
        }
        return CGSize(
            width: frame.width,
            height: idealHeight
        )
    }

    func idealHeight(for width: CGFloat) -> CGFloat {
        var height = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .defaultLow
        ).height
        if height >= UIView.layoutFittingExpandedSize.height {
            let sizeThatFits = sizeThatFits(CGSize(width: width, height: .infinity))
            if sizeThatFits.height > 0 {
                height = sizeThatFits.height
            }
        }
        return height
    }
}

#endif
