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
        var idealSize = CGRect(
            origin: .zero,
            size: systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        ).size
        if idealSize == .zero {
            idealSize = sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        }
        if idealSize == .zero {
            idealSize = intrinsicContentSize
        }
        return idealSize
    }
}

#endif
