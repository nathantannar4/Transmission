//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

open class PresentationHostingWindowController<Content: View>: UIViewController {

    public var content: Content {
        get { host.content }
        set { host.content = newValue }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let proxy = viewControllerForStatusBarAppearance else {
            return super.preferredStatusBarStyle
        }
        if proxy.modalPresentationCapturesStatusBarAppearance {
            return proxy.preferredStatusBarStyle
        } else if let presentingViewController = proxy.presentingViewController {
            if proxy._activePresentationController is UISheetPresentationController {
                return .lightContent
            }
            return presentingViewController.preferredStatusBarStyle
        }
        return super.preferredStatusBarStyle
    }

    open override var childForStatusBarStyle: UIViewController? {
        viewControllerForStatusBarAppearance ?? super.childForStatusBarStyle
    }

    open override var prefersStatusBarHidden: Bool {
        guard let proxy = viewControllerForStatusBarAppearance else {
            return super.prefersStatusBarHidden
        }
        if proxy.modalPresentationCapturesStatusBarAppearance {
            return proxy.prefersStatusBarHidden
        } else if let presentingViewController = proxy.presentingViewController {
            if proxy._activePresentationController is UISheetPresentationController {
                return false
            }
            return presentingViewController.prefersStatusBarHidden
        }
        return super.prefersStatusBarHidden
    }

    open override var childForStatusBarHidden: UIViewController? {
        viewControllerForStatusBarAppearance ?? super.childForStatusBarHidden
    }

    var viewControllerForStatusBarAppearance: UIViewController? {
        guard let window = view.window,
            let parent = window.parent,
            window.windowLevel.rawValue <= parent.windowLevel.rawValue,
            let parentViewController = parent.presentedViewController
        else {
            return nil
        }
        return parentViewController
    }

    private let host: HostingView<Content>

    public init(content: Content) {
        // Use a `HostingView` rather than `HostingController` so to utilize `HostingView`'s
        // hitTest override to allow touches to pass through.
        self.host = HostingView(content: content)
        super.init(nibName: nil, bundle: nil)
        host.isHitTestingPassthrough = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func loadView() {
        view = host
    }
}

#endif
