//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A view that manages the presentation of a menu. The presentation is
/// sourced from this view, but does not morph the view with the presented menu.
///
/// See Also:
///  - ``MenuSourceViewLink``
///  - ``MenuLinkAdapter``
///  - ``MenuLinkModifier``
///
@available(iOS 14.0, *)
@frozen
public struct MenuLink<
    Menu: MenuElement,
    Label: View
>: View {

    var label: Label
    var menu: Menu
    var primaryAction: MenuLinkPrimaryAction

    @StateOrBinding var isPresented: Bool

    public init(
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label,
        primaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            primaryAction: primaryAction.map { .custom($0) } ?? .showMenu,
            menu: menu,
            label: label
        )
    }

    public init(
        primaryAction: MenuLinkPrimaryAction,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.menu = menu()
        self.primaryAction = primaryAction
        self._isPresented = .init(false)
    }

    public init(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label,
        primaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            isPresented: isPresented,
            primaryAction: primaryAction.map { .custom($0) } ?? .showMenu,
            menu: menu,
            label: label
        )
    }

    public init(
        isPresented: Binding<Bool>,
        primaryAction: MenuLinkPrimaryAction,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.menu = menu()
        self.primaryAction = primaryAction
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        MenuLinkBody(
            isPresented: $isPresented,
            menu: menu,
            sourceView: label,
            primaryAction: primaryAction
        )
    }
}

@available(iOS 14.0, *)
private struct MenuLinkBody<
    Menu: MenuElement,
    SourceView: View
>: UIViewRepresentable {

    var isPresented: Binding<Bool>
    var menu: Menu
    var sourceView: SourceView
    var primaryAction: MenuLinkPrimaryAction

    typealias UIViewType = MenuLinkView<Menu, SourceView>

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType(
            content: sourceView,
            coordinator: context.coordinator
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.primaryAction = primaryAction
        uiView.onUpdate(
            content: sourceView,
            context: context
        )
        context.coordinator.onUpdate(
            isPresented: isPresented,
            transition: .default,
            menu: menu,
            preview: EmptyView(),
            context: context,
            visibleInset: 0,
            sourceView: uiView,
            interaction: uiView.contextMenuInteraction
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

    static func dismantleUIView(
        _ uiView: UIViewType,
        coordinator: Coordinator
    ) {
        coordinator.onDismantle()
    }

    typealias Coordinator = ContextMenuLinkCoordinator<Menu, EmptyView, SourceView, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isPresented: isPresented,
            menu: menu
        )
    }
}

@available(iOS 14.0, *)
private class MenuLinkView<
    Menu: MenuElement,
    Content: View
>: UIControl {

    var sourceView: UIView {
        hostingView.sourceView ?? hostingView
    }

    var primaryAction: MenuLinkPrimaryAction = .showMenu {
        didSet {
            switch primaryAction {
            case .showMenu:
                showsMenuAsPrimaryAction = true
            default:
                showsMenuAsPrimaryAction = false
            }
        }
    }

    private let hostingView: TransitionSourceView<Content>
    private let coordinator: MenuLinkBody<Menu, Content>.Coordinator

    init(
        content: Content,
        coordinator: MenuLinkBody<Menu, Content>.Coordinator
    ) {
        self.hostingView = TransitionSourceView(content: content)
        self.coordinator = coordinator
        super.init(frame: .zero)

        isContextMenuInteractionEnabled = true

        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hostingView)

        addTarget(self, action: #selector(didTriggerPrimaryAction), for: .primaryActionTriggered)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(iOS 17.4, *)
    override func performPrimaryAction() {
        if showsMenuAsPrimaryAction {
            super.performPrimaryAction()
        } else {
            didTriggerPrimaryAction()
        }
    }

    @objc
    private func didTriggerPrimaryAction() {
        if case .custom(let primaryAction) = primaryAction {
            primaryAction()
        }
    }

    func onUpdate(
        content: Content,
        context: MenuLinkBody<Menu, Content>.Context
    ) {
        hostingView.update(
            content: content,
            transaction: context.transaction
        )
    }

    func sizeThatFits(_ proposal: ProposedSize) -> CGSize? {
        hostingView.sizeThatFits(proposal)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        hostingView.sizeThatFits(size)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        switch primaryAction {
        case .disabled:
            let point = convert(point, to: hostingView)
            return hostingView.hitTest(point, with: event)
        default:
            return super.hitTest(point, with: event)
        }
    }

    override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    // MARK: - UIContextMenuInteractionDelegate

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return coordinator.contextMenuInteraction(
            interaction,
            configurationForMenuAtLocation: location
        )
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        coordinator.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
        coordinator.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return coordinator.contextMenuInteraction(
            interaction,
            previewForHighlightingMenuWithConfiguration: configuration
        )
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return coordinator.contextMenuInteraction(
            interaction,
            previewForDismissingMenuWithConfiguration: configuration
        )
    }

    @available(iOS 16.0, *)
    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        highlightPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return coordinator.contextMenuInteraction(
            interaction,
            configuration: configuration,
            highlightPreviewForItemWithIdentifier: identifier
        )
    }

    @available(iOS 16.0, *)
    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        dismissalPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return coordinator.contextMenuInteraction(
            interaction,
            configuration: configuration,
            dismissalPreviewForItemWithIdentifier: identifier
        )
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuLink_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isPresented = false

        var body: some View {
            VStack {
                MenuLink {
                    MenuButton {

                    } label: {
                        Image(systemName: "textformat.size.smaller")
                        Text("Small")
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "textformat.size.larger")
                        Text("Large")
                    }
                } label: {
                    Text("Menu")
                }

                MenuLink(
                    isPresented: $isPresented,
                    primaryAction: .disabled
                ) {
                    MenuButton {

                    } label: {
                        Image(systemName: "textformat.size.smaller")
                        Text("Small")
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "textformat.size.larger")
                        Text("Large")
                    }
                } label: {
                    Button {
                        withAnimation {
                            isPresented = true
                        }
                    } label: {
                        Text("Menu")
                    }
                }
            }
        }
    }
}

#endif
