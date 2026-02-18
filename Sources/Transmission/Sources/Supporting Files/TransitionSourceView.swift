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

    var hostingView: TransitionSourceHostingView<Content>?

    init(
        onDidMoveToWindow: @escaping (UIViewController?) -> Void,
        content: Content
    ) {
        super.init(onDidMoveToWindow: onDidMoveToWindow)
        if Content.self != EmptyView.self {
            isHidden = false
            let hostingView = TransitionSourceHostingView(content: content)
            addSubview(hostingView)
            hostingView.disablesSafeArea = true
            self.hostingView = hostingView
        }
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        hostingView?.sizeThatFits(size) ?? super.sizeThatFits(size)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        hostingView?.hitTest(point, with: event)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingView?.frame = bounds
    }
}

class TransitionSourceHostingView<Content: View>: HostingView<Content> {

    var cornerRadius: CornerRadiusOptions? {
        didSet {
            guard cornerRadius != oldValue else { return }
            layer.setNeedsLayout()
        }
    }

    override init(content: Content) {
        super.init(content: content)
        isHitTestingPassthrough = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerCornerRadius()
    }

    private func updateLayerCornerRadius() {
        if let cornerRadius = cornerRadius {
            cornerRadius.apply(to: self)
        }
    }
}

#endif
