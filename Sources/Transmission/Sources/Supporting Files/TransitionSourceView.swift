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

    override var backgroundColor: UIColor? {
        get {
            hostingView?.backgroundColor ?? super.backgroundColor
        }
        set {
            if let hostingView {
                hostingView.backgroundColor = newValue
            } else {
                super.backgroundColor = newValue
                isHidden = newValue == nil
            }
        }
    }

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

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        updateLayerCornerRadius()
    }

    private func updateLayerCornerRadius() {
        let cornerRadius = cornerRadius ?? .identity
        cornerRadius.apply(to: self)
    }
}

#endif
