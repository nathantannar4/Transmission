//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

@available(iOS 14.0, *)
open class TransitionSourceView<Content: View>: UIView, AnyHostingView {

    public var sourceView: UIView? {
        hostStorage?.hostingView
    }

    open override var intrinsicContentSize: CGSize {
        hostStorage?.hostingView.intrinsicContentSize ?? super.intrinsicContentSize
    }

    private enum Storage {
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

    private let presentingViewController: Binding<UIViewController?>?

    public init(
        presentingViewController: Binding<UIViewController?>? = nil,
        content: Content,
        useHostingController: Bool = false
    ) {
        self.presentingViewController = presentingViewController
        super.init(frame: .zero)
        if Content.self != EmptyView.self {
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
        } else {
            isHidden = true
        }
        clipsToBounds = false
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(
        content: Content,
        transaction: Transaction,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: UIColor? = nil
    ) {
        guard let hostingView = hostStorage?.hostingView else { return }
        hostingView.cornerRadius = cornerRadius
        hostingView.backgroundColor = backgroundColor
        hostingView.content = TransitionSourceViewContent(
            content: content,
            transaction: transaction
        )
        hostingView.layoutIfNeeded()
    }

    open func sizeThatFits(_ proposal: ProposedSize) -> CGSize? {
        hostStorage?.hostingView.sizeThatFits(proposal)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        hostStorage?.hostingView.sizeThatFits(size) ?? super.sizeThatFits(size)
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if hostStorage != nil, let superview {
            if let superclass = superview.superclass {
                UIView.disableInitialImplicitFrameAnimations(aClass: superclass)
            }
            superview.disableInitialImplicitFrameAnimations()
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        guard
            let presentingViewController,
            presentingViewController.wrappedValue == nil
        else {
            return
        }
        let viewController = viewController
        withCATransaction { [presentingViewController] in
            presentingViewController.wrappedValue = viewController
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        hostStorage?.hostingView.frame = bounds
    }

    public func render() {
        hostStorage?.hostingView.render()
    }

    open override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if let hostingView = hostStorage?.hostingView, isInitialFrameAnimationAction(for: layer, forKey: event) {
            if let action = hostingView.action(for: hostingView.layer, forKey: event), action is NSNull {
                return NSNull()
            }
        }
        let action = super.action(for: layer, forKey: event)
        return action
    }
}

@available(iOS 14.0, *)
private struct TransitionSourceViewContent<Content: View>: View {
    var content: Content
    var transaction: Transaction

    @UpdatePhase var updatePhase

    var body: some View {
        content
            .transaction(transaction, value: updatePhase)
    }
}

private class TransitionSourceHostingView<Content: View>: HostingView<Content> {

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
        cornerRadius?.apply(to: self, masksToBounds: backgroundColor != nil)
        hasInitialLayout = true
    }

    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if !hasInitialLayout, isInitialFrameAnimationAction(for: layer, forKey: event) {
            return NSNull()
        }
        let action = super.action(for: layer, forKey: event)
        return action
    }
}

private class TransitionSourceHostingController<Content: View>: UIViewController {

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
                TransitionSourceViewPreview(
                    backgroundColor: .systemYellow
                ) {
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

                TransitionSourceViewPreview(
                    cornerRadius: .rounded(cornerRadius: 24),
                    backgroundColor: .systemYellow
                ) {
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

                TransitionSourceViewPreview(
                    cornerRadius: .rounded(cornerRadius: 24)
                ) {
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

                // Won't animate as nicely if a size is not defined
                TransitionSourceViewPreview(
                    backgroundColor: .systemYellow
                ) {
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
            }
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }

    struct TransitionSourceViewPreview<Content: View>: UIViewRepresentable {
        var cornerRadius: CornerRadiusOptions?
        var backgroundColor: UIColor?
        var content: Content

        init(
            cornerRadius: CornerRadiusOptions? = nil,
            backgroundColor: UIColor? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
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
                transaction: context.transaction,
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor
            )
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        func sizeThatFits(
            _ proposal: ProposedViewSize,
            uiView: UIViewType,
            context: Context
        ) -> CGSize? {
            return uiView.sizeThatFits(ProposedSize(proposal))
        }

        func _overrideSizeThatFits(
            _ size: inout CGSize,
            in proposedSize: _ProposedSize,
            uiView: UIViewType
        ) {
            size = uiView.sizeThatFits(ProposedSize(proposedSize)) ?? size
        }
    }
}

#endif
