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

    var isInteracting: Bool {
        let isInteracting = state == .began || state == .changed
        return isInteracting
    }

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

    private static let UIKitResponderGestureRecognizer: AnyClass? = NSClassFromString("SwiftUI.UIKitResponderGestureRecognizer")
    var isSwiftUIGestureResponder: Bool {
        guard let aClass = Self.UIKitResponderGestureRecognizer else {
            return false
        }
        return isKind(of: aClass)
    }

    var isSheetDismissPanGesture: Bool {
        guard name == "_UISheetInteractionBackgroundDismissRecognizer" else {
            return false
        }
        return self is UIPanGestureRecognizer
    }

    var isZoomDismissPanGesture: Bool {
        guard name == "com.apple.UIKit.ZoomInteractiveDismissSwipeDown" else {
            return false
        }
        return self is UIPanGestureRecognizer
    }

    var isZoomDismissEdgeGesture: Bool {
        guard name == "com.apple.UIKit.ZoomInteractiveDismissLeadingEdgePan" else {
            return false
        }
        return self is UIScreenEdgePanGestureRecognizer
    }

    var isZoomDismissPinchGesture: Bool {
        guard name == "com.apple.UIKit.ZoomInteractiveDismissPinch" else {
            return false
        }
        return true
    }

    var isZoomDismissGesture: Bool {
        isZoomDismissPanGesture || isZoomDismissEdgeGesture || isZoomDismissPinchGesture
    }

    static let zoomGestureActivationThreshold = CGSize(width: 200, height: 150)
}

#endif
