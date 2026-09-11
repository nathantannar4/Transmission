//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

extension EdgeInsets {

    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension EdgeInsets {

    init(
        edgeInsets: UIEdgeInsets,
        layoutDirection: UITraitEnvironmentLayoutDirection
    ) {
        self.init(
            top: edgeInsets.top,
            leading: layoutDirection == .leftToRight ? edgeInsets.left : edgeInsets.right,
            bottom: edgeInsets.right,
            trailing: layoutDirection == .leftToRight ? edgeInsets.right : edgeInsets.left
        )
    }
}

extension UIEdgeInsets {

    init(
        edgeInsets: EdgeInsets,
        layoutDirection: LayoutDirection
    ) {
        self.init(
            top: edgeInsets.top,
            left: layoutDirection == .leftToRight ? edgeInsets.leading : edgeInsets.trailing,
            bottom: edgeInsets.bottom,
            right: layoutDirection == .leftToRight ? edgeInsets.trailing : edgeInsets.leading
        )
    }
}

#endif
