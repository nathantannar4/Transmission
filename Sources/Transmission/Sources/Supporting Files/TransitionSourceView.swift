//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

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
        guard presentingViewController.wrappedValue == nil else { return }
        let viewController = viewController
        withCATransaction { [presentingViewController] in
            presentingViewController.wrappedValue = viewController
        }
    }
}

@available(iOS 14.0, *)
struct TransitionSourceViewContent<Content: View>: View {
    var content: Content
    var transaction: Transaction

    @UpdatePhase var updatePhase

    var body: some View {
        content
            .transaction(transaction, value: updatePhase)
            .transaction { $0.animation = nil }
    }
}

@available(iOS 14.0, *)
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
        presentingViewController: Binding<UIViewController?>,
        content: Content,
        useHostingController: Bool
    ) {
        super.init(presentingViewController: presentingViewController)
        if Content.self != EmptyView.self {
            isHidden = false
            let content = TransitionSourceViewContent(
                content: content,
                transaction: Transaction()
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
            transaction: transaction
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

// MARK: - Previews

@available(iOS 14.0, *)
struct TransitionSourceView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isExpanded: Bool = false

        var body: some View {
            let size: CGFloat = isExpanded ? 200 : 100
            VStack {
                TransitionSourceViewPreview {
                    ZStack {
                        Color.red

                        if #available(iOS 16.0, *) {
                            Text(isExpanded ? "Expanded" : "Collapsed")
                                .contentTransition(.numericText())
                        } else {
                            Text(isExpanded ? "Expanded" : "Collapsed")
                        }
                    }
                }
                .frame(width: size, height: size)

                TransitionSourceViewPreview {
                    ZStack {
                        Color.red

                        if #available(iOS 16.0, *) {
                            Text(isExpanded ? "Expanded" : "Collapsed")
                                .contentTransition(.numericText())
                        } else {
                            Text(isExpanded ? "Expanded" : "Collapsed")
                        }
                    }
                    .frame(width: size, height: size)
                }

                TransitionSourceViewPreview {
                    ZStack {
                        Color.red

                        if #available(iOS 16.0, *) {
                            Text(isExpanded ? "Expanded" : "Collapsed")
                                .contentTransition(.numericText())
                        } else {
                            Text(isExpanded ? "Expanded" : "Collapsed")
                        }
                    }
                    .frame(width: size, height: size)
                }
                .frame(width: size, height: size)
            }
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }

    struct TransitionSourceViewPreview<Content: View>: UIViewRepresentable {
        var content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeUIView(context: Context) -> TransitionSourceView<Content> {
            TransitionSourceView(
                presentingViewController: .constant(nil),
                content: content,
                useHostingController: false
            )
        }

        func updateUIView(_ uiView: TransitionSourceView<Content>, context: Context) {
            uiView.update(
                content: content,
                transaction: context.transaction
            )
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        func sizeThatFits(
            _ proposal: ProposedViewSize,
            uiView: TransitionSourceView<Content>,
            context: Context
        ) -> CGSize? {
            return uiView.sizeThatFits(ProposedSize(proposal))
        }

        func _overrideSizeThatFits(
            _ size: inout CGSize,
            in proposedSize: _ProposedSize,
            uiView: TransitionSourceView<Content>
        ) {
            size = uiView.sizeThatFits(ProposedSize(proposedSize))
        }
    }
}

#endif
