//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

extension UIView.AnimationCurve {

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
            return .timingCurve(0.25, 0.1, 0.25, 1.0, duration: duration)
        }
    }
}

#endif
