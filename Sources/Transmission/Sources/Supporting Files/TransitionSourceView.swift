//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

class ViewControllerReader: UIView {

    let presentingViewController: Binding<UIViewController?>

    init(presentingViewController: Binding<UIViewController?>) {
        self.presentingViewController = presentingViewController
        super.init(frame: .zero)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return size
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        withCATransaction { [weak self] in
            guard let self = self else {
                return
            }
            self.presentingViewController.wrappedValue = self.viewController
        }
    }
}

class TransitionSourceView<Content: View>: ViewControllerReader {

    var hostingView: HostingView<Content>?

    init(
        presentingViewController: Binding<UIViewController?>,
        content: Content
    ) {
        super.init(presentingViewController: presentingViewController)
        if Content.self != EmptyView.self {
            isHidden = false
            let hostingView = HostingView(content: content)
            addSubview(hostingView)
            hostingView.disablesSafeArea = true
            self.hostingView = hostingView
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        hostingView?.sizeThatFits(size) ?? super.sizeThatFits(size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingView?.frame = bounds
    }
}


#endif
