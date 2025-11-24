//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

open class PresentationHostingWindowController<Content: View>: UIViewController {

    public var content: Content {
        get { hostingController.content }
        set { hostingController.content = newValue }
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
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostingController.view.frame = view.bounds
    }
}

#endif
