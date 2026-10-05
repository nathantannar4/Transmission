//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension NSTextAlignment {

    public init(
        alignment: HorizontalAlignment,
        layoutDirection: LayoutDirection
    ) {
        switch alignment {
        case .center:
            self.init(alignment: TextAlignment.center, layoutDirection: layoutDirection)
        case .trailing:
            self.init(alignment: TextAlignment.trailing, layoutDirection: layoutDirection)
        default:
            self.init(alignment: TextAlignment.leading, layoutDirection: layoutDirection)
        }
    }

    public init(
        alignment: TextAlignment,
        layoutDirection: LayoutDirection
    ) {
        switch alignment {
        case .center:
            self = .center
        default:
            switch layoutDirection {
            case .rightToLeft:
                if alignment == .leading {
                    self = .right
                } else {
                    self = .left
                }
            default:
                if alignment == .leading {
                    self = .left
                } else {
                    self = .right
                }
            }
        }
    }
}

