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

    func preferredContentSize(for width: CGFloat) -> CGSize {
        var size = intrinsicContentSize
        if size.height <= 0 {
            size.width = width
            size.height = idealHeight(for: width)
        }
        return size
    }

    func idealHeight(for width: CGFloat) -> CGFloat {
        idealSize(for: width).height
    }

    func idealSize(for width: CGFloat) -> CGSize {
        var fittingSize = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        if fittingSize.height >= UIView.layoutFittingExpandedSize.height {
            let sizeThatFits = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            if sizeThatFits.height > 0 {
                fittingSize.height = sizeThatFits.height
            }
        }
        return fittingSize
    }

    func setFramePreservingTransform(_ frame: CGRect) {
        let anchor = layer.anchorPoint
        bounds = CGRect(origin: .zero, size: frame.size)
        center = CGPoint(
            x: frame.minX + (frame.width * anchor.x),
            y: frame.minY + (frame.height * anchor.y)
        )
    }

    func constrain(to other: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor),
            bottomAnchor.constraint(equalTo: other.bottomAnchor),
            leadingAnchor.constraint(equalTo: other.leadingAnchor),
            trailingAnchor.constraint(equalTo: other.trailingAnchor),
        ])
    }
}

#endif
