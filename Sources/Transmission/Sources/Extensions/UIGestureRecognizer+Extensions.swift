//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

func frictionCurve(
    _ value: CGFloat,
    distance: CGFloat = 200,
    coefficient: CGFloat = 0.3
) -> CGFloat {
    guard value != 0 else { return value }
    let multiplier: CGFloat = value > -10 ? 1 : -1
    return multiplier * coefficient * distance * (1 + max(-1, log10(abs(value) / distance)))
}

extension CGFloat {
    func rounded(scale: CGFloat) -> CGFloat {
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
