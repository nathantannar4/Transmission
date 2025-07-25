//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

open class DestinationHostingController<
    Content: View
>: HostingController<Content> {

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard let navigationController,
            let index = navigationController.viewControllers.firstIndex(of: self),
            index > 0,
            let hostingController = navigationController.viewControllers[index - 1] as? AnyHostingController,
            hostingController.view.superview == nil
        else {
            return
        }
        hostingController.renderAsync()
    }
}

#endif
