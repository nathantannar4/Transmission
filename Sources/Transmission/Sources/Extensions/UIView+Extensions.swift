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

    func idealSize(for width: CGFloat) -> CGSize {
        var size = intrinsicContentSize
        if size.height <= 0 {
            size.width = width
            size.height = idealHeight(for: width)
        }
        return size
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
