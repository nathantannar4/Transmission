//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
open class DestinationHostingController<
    Content: View
>: HostingController<Content> {

    public weak var sourceViewController: AnyHostingController?

    private var didAppear = false

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fix push transition of navigation items, such as a custom title view
        if #unavailable(iOS 26.0),
            !didAppear,
            let transitionCoordinator,
            transitionCoordinator.presentationStyle == .none,
            transitionCoordinator.isAnimated
        {
            transitionCoordinator.animate { [weak self] _ in
                self?.render()
            }
        }
        didAppear = true
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let sourceViewController, sourceViewController.shouldRenderForContentUpdate {
            // Render so the modifier that controls the presentation of this hosting controller
            // can run and update.
            withCATransaction { [weak sourceViewController] in
                sourceViewController?.render()
            }
        }
    }
}

#endif
