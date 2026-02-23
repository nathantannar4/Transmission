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

    var hostingView: TransitionSourceHostingView<Content>? {
        hostStorage?.hostingView
    }

    enum Storage {
        case hostingView(TransitionSourceHostingView<Content>)
        case hostingController(TransitionSourceHostingController<Content>)

        var hostingView: TransitionSourceHostingView<Content> {
            switch self {
            case .hostingView(let hostingView):
                return hostingView
            case .hostingController(let hostingController):
                return hostingController.hostingView
            }
        }
    }
    private var hostStorage: Storage?

    init(
        onDidMoveToWindow: @escaping (UIViewController?) -> Void,
        content: Content,
        useHostingController: Bool
    ) {
        super.init(onDidMoveToWindow: onDidMoveToWindow)
        if Content.self != EmptyView.self {
            isHidden = false
            if useHostingController {
                let hostingController = TransitionSourceHostingController(content: content)
                addSubview(hostingController.view)
                hostStorage = .hostingController(hostingController)
            } else {
                let hostingView = TransitionSourceHostingView(content: content)
                addSubview(hostingView)
                hostStorage = .hostingView(hostingView)
            }
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
        switch hostStorage {
        case .hostingView(let hostingView):
            hostingView.frame = bounds
        case .hostingController(let hostingController):
            hostingController.view.frame = bounds
        case .none:
            break
        }
    }
}

class TransitionSourceHostingView<Content: View>: HostingView<Content> {

    var cornerRadius: CornerRadiusOptions? {
        didSet {
            guard cornerRadius != oldValue else { return }
            setNeedsLayout()
        }
    }

    override init(content: Content) {
        super.init(content: content)
        isHitTestingPassthrough = false
        disablesSafeArea = true
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

class TransitionSourceHostingController<Content: View>: UIViewController {

    let hostingView: TransitionSourceHostingView<Content>

    init(content: Content) {
        self.hostingView = TransitionSourceHostingView(content: content)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        view.addSubview(hostingView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostingView.frame = view.bounds
    }
}

#endif
