//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

class ViewControllerReader: UIView {

    let onDidMoveToWindow: (UIViewController?) -> Void

    init(onDidMoveToWindow: @escaping (UIViewController?) -> Void) {
        self.onDidMoveToWindow = onDidMoveToWindow
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
        onDidMoveToWindow(viewController)
    }
}

class TransitionSourceView<Content: View>: ViewControllerReader {

    var hostingView: HostingView<Content>?

    init(
        onDidMoveToWindow: @escaping (UIViewController?) -> Void,
        content: Content
    ) {
        super.init(onDidMoveToWindow: onDidMoveToWindow)
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
