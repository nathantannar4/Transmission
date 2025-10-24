//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension EdgeInsets {

    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension UIEdgeInsets {
    public init(
        edgeInsets: EdgeInsets,
        layoutDirection: UITraitEnvironmentLayoutDirection
    ) {
        self.init(
            top: edgeInsets.top,
            left: layoutDirection == .rightToLeft ? edgeInsets.trailing : edgeInsets.leading,
            bottom: edgeInsets.bottom,
            right: layoutDirection == .rightToLeft ? edgeInsets.leading : edgeInsets.trailing
        )
    }
}
