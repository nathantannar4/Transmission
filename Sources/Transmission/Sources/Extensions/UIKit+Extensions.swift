//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

extension UIEdgeInsets {
    init(_ edgeInsets: EdgeInsets, layoutDirection: LayoutDirection) {
        self = UIEdgeInsets(
            top: edgeInsets.top,
            left: layoutDirection == .leftToRight ? edgeInsets.leading : edgeInsets.trailing,
            bottom: edgeInsets.bottom,
            right: layoutDirection == .leftToRight ? edgeInsets.trailing : edgeInsets.leading
        )
    }
}

extension UIView.AnimationCurve {

    func toSwiftUI() -> UIView.AnimationCurve {
        switch self {
        case .easeInOut:
            return .easeInOut
        case .easeIn:
            return .easeIn
        case .easeOut:
            return .easeOut
        case .linear:
            return .linear
        default:
            return .easeInOut
        }
    }

    func toSwiftUI(duration: TimeInterval) -> Animation {
        switch self {
        case .linear:
            return .linear(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        @unknown default:
            return .easeInOut(duration: duration)
        }
    }
}

#endif
