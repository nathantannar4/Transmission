//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

extension EnvironmentValues {

    var hostingController: UIViewController? {
        self["WithCurrentHostingControllerKey"]
    }
}

#endif
