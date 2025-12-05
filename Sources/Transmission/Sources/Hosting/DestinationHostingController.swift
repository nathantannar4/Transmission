//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

open class DestinationHostingController<
    Content: View
>: HostingController<Content> {

    public var sourceViewController: AnyHostingController?

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Render so the modifier that controls the presentation of this hosting controller
        // can run and update.
        sourceViewController?.render()
    }
}

#endif
