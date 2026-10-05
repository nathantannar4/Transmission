//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

public enum PreferredPresentationPlacement {
    case sourceView
    case leading
    case center
    case trailing

    #if XCODE_27
    @available(iOS 27.0, *)
    public func toUIKitSheetPlacement() -> UISheetPresentationController.Placement {
        switch self {
        case .sourceView:
            return .automatic
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    #endif
}

#endif
