//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

public func frictionCurve(
    _ value: CGFloat,
    distance: CGFloat = 200,
    coefficient: CGFloat = 0.3
) -> CGFloat {
    if value < 0 {
        return -frictionCurve(abs(value), distance: distance, coefficient: coefficient)
    }
    return (1.0 - (1.0 / ((value * coefficient / distance) + 1.0))) * distance
}

extension CGFloat {
    public func rounded(scale: CGFloat) -> CGFloat {
        (self * scale).rounded() / scale
    }
}

extension UIGestureRecognizer {

    var isSimultaneousWithTransition: Bool {
        isScrollViewPanGesture || isWebViewPanGesture
            || delaysTouchesBegan
            || isKind(of: UIPinchGestureRecognizer.self)
    }

    private static let UIScrollViewPanGestureRecognizer: AnyClass? = NSClassFromString("UIScrollViewPanGestureRecognizer")
    var isScrollViewPanGesture: Bool {
        guard let aClass = Self.UIScrollViewPanGestureRecognizer else {
            return false
        }
        return isKind(of: aClass)
    }

    private static let WKScrollView: AnyClass? = NSClassFromString("WKScrollView")
    var isWebViewPanGesture: Bool {
        guard let view, let aClass = Self.WKScrollView else {
            return false
        }
        return view.isKind(of: aClass)
    }
}

#endif
