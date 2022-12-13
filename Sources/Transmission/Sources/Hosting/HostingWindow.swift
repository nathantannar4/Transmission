//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

open class HostingWindow<Content: View>: UIWindow {

    public var content: Content {
        get { host.rootView }
        set { host.rootView = newValue }
    }

    private let host: HostingWindowController

    public init(windowScene: UIWindowScene, content: Content) {
        self.host = HostingWindowController(content: content)
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

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == rootViewController?.view || result == self {
            return nil
        }
        return result
    }

    private class HostingWindowController: _HostingController<Content> {
        override var childForStatusBarStyle: UIViewController? {
            guard let window = view.window,
                let parent = window.parent,
                window.windowLevel.rawValue == parent.windowLevel.rawValue,
                let parentViewController = parent.presentedViewController
            else {
                return nil
            }
            return parentViewController
        }

        override var childForStatusBarHidden: UIViewController? {
            guard let window = view.window,
                let parent = window.parent,
                window.windowLevel.rawValue <= parent.windowLevel.rawValue,
                let parentViewController = parent.presentedViewController
            else {
                return nil
            }
            return parentViewController
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = nil
        }
    }
}

#endif
