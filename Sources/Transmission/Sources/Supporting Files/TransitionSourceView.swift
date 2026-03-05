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

struct TransitionSourceViewContent<Content: View>: View {
    var content: Content
    var animation: Animation?
    var update: UInt

    var body: some View {
        content
            .animation(animation, value: update)
            .transaction { $0.animation = nil }
    }
}

class TransitionSourceView<Content: View>: ViewControllerReader {

    var hostingView: TransitionSourceHostingView<TransitionSourceViewContent<Content>>? {
        hostStorage?.hostingView
    }

    enum Storage {
        case hostingView(TransitionSourceHostingView<TransitionSourceViewContent<Content>>)
        case hostingController(TransitionSourceHostingController<TransitionSourceViewContent<Content>>)

        var hostingView: TransitionSourceHostingView<TransitionSourceViewContent<Content>> {
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
            let content = TransitionSourceViewContent(
                content: content,
                animation: nil,
                update: 0
            )
            if useHostingController {
                let hostingController = TransitionSourceHostingController(content: content)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                addSubview(hostingController.view)
                hostStorage = .hostingController(hostingController)
            } else {
                let hostingView = TransitionSourceHostingView(content: content)
                hostingView.translatesAutoresizingMaskIntoConstraints = false
                addSubview(hostingView)
                hostStorage = .hostingView(hostingView)
            }
        }
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(content: Content, transaction: Transaction) {
        guard let hostingView else { return }
        hostingView.content = TransitionSourceViewContent(
            content: content,
            animation: transaction.animation,
            update: hostingView.content.update &+ 1
        )
    }

    func sizeThatFits(_ proposal: ProposedSize) -> CGSize {
        let fittingSize = proposal
            .replacingUnspecifiedDimensions(
                by: CGSize(
                    width: CGFloat.infinity,
                    height: CGFloat.infinity
                )
            )
        let size = sizeThatFits(fittingSize)
        return size
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        hostingView?.sizeThatFits(size) ?? super.sizeThatFits(size)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        hostingView?.hitTest(point, with: event)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if hostingView != nil, let superview {
            if let superclass = superview.superclass {
                UIView.disableInitialImplicitFrameAnimations(aClass: superclass)
            }
            superview.disableInitialImplicitFrameAnimations()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingView?.frame = bounds
    }

    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if let hostingView, isInitialFrameAnimationAction(for: layer, forKey: event) {
            if let action = hostingView.action(for: hostingView.layer, forKey: event), action is NSNull {
                return NSNull()
            }
        }
        let action = super.action(for: layer, forKey: event)
        return action
    }
}

class TransitionSourceHostingView<Content: View>: HostingView<Content> {

    var cornerRadius: CornerRadiusOptions? {
        didSet {
            guard cornerRadius != oldValue else { return }
            setNeedsLayout()
        }
    }

    private var hasInitialLayout = false

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
        hasInitialLayout = true
    }

    private func updateLayerCornerRadius() {
        if let cornerRadius = cornerRadius {
            cornerRadius.apply(to: self)
        }
    }

    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if !hasInitialLayout, isInitialFrameAnimationAction(for: layer, forKey: event) {
            return NSNull()
        }
        let action = super.action(for: layer, forKey: event)
        return action
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

    override func loadView() {
        view = hostingView
    }
}

#endif
