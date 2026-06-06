//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
open class PresentationHostingWindowController<Content: View>: UIViewController {

    public var content: Content {
        get { hostingController.content }
        set { hostingController.content = newValue }
    }

    open override var childForStatusBarStyle: UIViewController? {
        viewControllerForStatusBarAppearance
    }

    open override var childForStatusBarHidden: UIViewController? {
        viewControllerForStatusBarAppearance
    }

    var viewControllerForStatusBarAppearance: UIViewController {
        guard
            let window = presentingWindow,
            let parent = window.parent,
            window.windowLevel.rawValue == parent.windowLevel.rawValue || window.windowLevel == .alert,
            var presentingViewController = parent.presentedViewController
        else {
            return hostingController
        }
        while !presentingViewController.modalPresentationCapturesStatusBarAppearance, let presenting = presentingViewController.presentingViewController {
            presentingViewController = presenting
        }
        return presentingViewController
    }

    public weak var presentingWindow: UIWindow?

    private let hostingController: HostingController<Content>

    public init(content: Content) {
        self.hostingController = HostingController(content: content)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func loadView() {
        view = PassthroughView()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        hostingController.view.backgroundColor = nil
        hostingController.willMove(toParent: self)
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        (view as? PassthroughView)?.rootView = hostingController.view
        hostingController.didMove(toParent: self)
    }

    open func update(content: Content, transaction: Transaction) {
        hostingController.update(content: content, transaction: transaction)
    }
}

#endif
