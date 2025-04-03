//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension CGSize {
    func isApproximatelyEqual(to size: CGSize, tolerance: CGFloat = 1e-5) -> Bool {
        return abs(width - size.width) <= tolerance &&
            abs(height - size.height) <= tolerance
    }
}

extension CGRect {
    func isApproximatelyEqual(to rect: CGRect, tolerance: CGFloat = 1e-5) -> Bool {
        return abs(origin.x - rect.origin.x) <= tolerance &&
            abs(origin.y - rect.origin.y) <= tolerance &&
            abs(size.width - rect.size.width) <= tolerance &&
            abs(size.height - rect.size.height) <= tolerance
    }
}

#endif
