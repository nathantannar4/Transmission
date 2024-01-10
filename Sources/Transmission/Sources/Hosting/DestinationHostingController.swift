//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Turbocharger

open class DestinationHostingController<
    Content: View
>: HostingController<Content> {

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let navigationController,
            let index = navigationController.viewControllers.firstIndex(of: self),
            index > 0,
            let hostingController = navigationController.viewControllers[index - 1] as? AnyHostingController,
            hostingController.view.superview == nil
        else {
            return
        }
        hostingController.render()
    }
}

#endif
