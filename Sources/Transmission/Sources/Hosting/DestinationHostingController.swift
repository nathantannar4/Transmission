//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

open class DestinationHostingController<
    Content: View
>: HostingController<Content> {

    public weak var sourceViewController: AnyHostingController?

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let sourceViewController, sourceViewController.shouldRenderForContentUpdate {
            // Render so the modifier that controls the presentation of this hosting controller
            // can run and update.
            sourceViewController.render()
        }
    }
}

#endif
