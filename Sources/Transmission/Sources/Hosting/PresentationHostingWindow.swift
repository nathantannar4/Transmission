//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

open class PresentationHostingWindow<Content: View>: UIWindow {

    public var content: Content {
        get { host.content }
        set { host.content = newValue }
    }

    private let host: PresentationHostingWindowController

    public init(windowScene: UIWindowScene, content: Content) {
        self.host = PresentationHostingWindowController(content: content)
        super.init(windowScene: windowScene)
        rootViewController = host
    }

    public convenience init(windowScene: UIWindowScene, @ViewBuilder content: () -> Content) {
        self.init(windowScene: windowScene, content: content())
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    public override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(windowScene:content:)")
    public override init(windowScene: UIWindowScene) {
        fatalError("init(windowScene:) has not been implemented")
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self {
            return nil
        }
        return result
    }

    private class PresentationHostingWindowController: UIViewController {

        var content: Content {
            get { host.content }
            set { host.content = newValue }
        }

        override var preferredStatusBarStyle: UIStatusBarStyle {
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

        override var childForStatusBarStyle: UIViewController? {
            viewControllerForStatusBarAppearance ?? super.childForStatusBarStyle
        }

        override var prefersStatusBarHidden: Bool {
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

        override var childForStatusBarHidden: UIViewController? {
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

        init(content: Content) {
            // Use a `HostingView` rather than `HostingController` so to utilize `HostingView`'s
            // hitTest override to allow touches to pass through.
            self.host = HostingView(content: content)
            super.init(nibName: nil, bundle: nil)
            host.isHitTestingPassthrough = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            view = host
        }
    }
}

#endif
