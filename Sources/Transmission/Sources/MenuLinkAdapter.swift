//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// The primary action of the ``MenuLink``
@frozen
@available(iOS 14.0, *)
public enum MenuLinkPrimaryAction {

    /// The primary action is disabled, and the menu will pass through touches to the label
    case disabled

    /// Show the menu on tap
    case showMenu

    /// A custom handler on tap
    case custom(@MainActor () -> Void)
}

/// The background style of the ``MenuLink``,
///
/// > Note: Neccesary for the correct glass morphing effect
///
@frozen
@available(iOS 14.0, *)
public enum MenuLinkBackgroundStyle {
    case plain

    @available(iOS 26.0, *)
    case glass

    @available(iOS 26.0, *)
    case clearGlass
}

/// A view that manages the presentation of a context menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``MenuSourceViewLink``
///  - ``MenuLinkModifier``
///
@frozen
@available(iOS 14.0, *)
public struct MenuLinkAdapter<
    Menu: MenuElement,
    Content: View
>: View {

    var content: Content
    var menu: Menu
    var primaryAction: MenuLinkPrimaryAction
    var cornerRadius: CornerRadiusOptions?
    var background: MenuLinkBackgroundStyle
    var visibleInset: CGFloat
    var isPresented: Binding<Bool>

    public init(
        primaryAction: MenuLinkPrimaryAction,
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.menu = menu()
        self.primaryAction = primaryAction
        self.cornerRadius = cornerRadius
        self.background = background
        self.visibleInset = visibleInset
        self.isPresented = isPresented
    }

    public var body: some View {
        MenuLinkAdapterBody(
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            isPresented: isPresented,
            menu: menu,
            sourceView: content,
            primaryAction: primaryAction
        )
    }
}

@available(iOS 14.0, *)
private struct MenuLinkAdapterBody<
    Menu: MenuElement,
    SourceView: View
>: UIViewRepresentable {

    var cornerRadius: CornerRadiusOptions?
    var background: MenuLinkBackgroundStyle
    var visibleInset: CGFloat
    var isPresented: Binding<Bool>
    var menu: Menu
    var sourceView: SourceView
    var primaryAction: MenuLinkPrimaryAction

    typealias UIViewType = MenuLinkSourceView<Menu, SourceView>

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType(
            content: sourceView,
            background: background,
            coordinator: context.coordinator
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.primaryAction = primaryAction
        uiView.onUpdate(
            content: sourceView,
            context: context,
            cornerRadius: cornerRadius
        )
        context.coordinator.onUpdate(
            isPresented: isPresented,
            transition: .default,
            menu: menu,
            preview: EmptyView(),
            context: context,
            visibleInset: visibleInset,
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
private class MenuLinkSourceView<
    Menu: MenuElement,
    Content: View
>: UIButton {

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
    private let coordinator: MenuLinkAdapterBody<Menu, Content>.Coordinator

    var contentView: UIView {
        if #available(iOS 15.0, *), configuration != nil,
            let backgroundView = subviews.first,
            let contentView = backgroundView.subviews.first
        {
            if let effectView = contentView as? UIVisualEffectView {
                return effectView.contentView
            }
            return contentView
        }
        return self
    }

    init(
        content: Content,
        background: MenuLinkBackgroundStyle,
        coordinator: MenuLinkAdapterBody<Menu, Content>.Coordinator
    ) {
        self.hostingView = TransitionSourceView(content: content)
        self.coordinator = coordinator
        super.init(frame: .zero)

        if #available(iOS 15.0, *) {
            self.configuration = background.makeConfiguration()
            automaticallyUpdatesConfiguration = false
        }

        tintAdjustmentMode = .normal
        isContextMenuInteractionEnabled = true

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostingView)

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
        context: MenuLinkAdapterBody<Menu, Content>.Context,
        cornerRadius: CornerRadiusOptions?
    ) {
        hostingView.update(
            content: content,
            transaction: context.transaction,
            cornerRadius: cornerRadius
        )
    }

    func sizeThatFits(_ proposal: ProposedSize) -> CGSize? {
        hostingView.sizeThatFits(proposal)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        hostingView.sizeThatFits(size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingView.frame = convert(bounds, to: hostingView)
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
        configuration: UIContextMenuConfiguration,
        highlightPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return coordinator.contextMenuInteraction(
            interaction,
            configuration: configuration,
            highlightPreviewForItemWithIdentifier: identifier
        )
    }

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

@available(iOS 14.0, *)
extension MenuLinkBackgroundStyle {

    @available(iOS 15.0, *)
    @MainActor
    func makeConfiguration() -> UIButton.Configuration {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            switch self {
            case .glass:
                return .glass()
            case .clearGlass:
                return .clearGlass()
            default:
                break
            }
        }
        #endif

        var configuration = UIButton.Configuration.plain()
        configuration.background.cornerRadius = 0
        return configuration
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuLinkAdapter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isMenuAPresented = false
        @State var isMenuBPresented = false
        @State var isMenuCPresented = false

        var body: some View {
            VStack {
                MenuLinkAdapter(
                    primaryAction: .custom({ print("primary action") }),
                    background: {
                        if #available(iOS 26.0, *) {
                            return .glass
                        }
                        return .plain
                    }(),
                    isPresented: $isMenuAPresented
                ) {
                    MenuButton {

                    } label: {
                        Text("Option A")
                    }

                    MenuButton {

                    } label: {
                        Text("Option B")
                    }
                } content: {
                    VStack(alignment: .leading) {
                        Text("Primary Action")
                        Text("Holde to show menu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                MenuLinkAdapter(
                    primaryAction: .disabled,
                    background: {
                        if #available(iOS 26.0, *) {
                            return .glass
                        }
                        return .plain
                    }(),
                    isPresented: $isMenuBPresented
                ) {
                    MenuButton {

                    } label: {
                        Text("Option A")
                    }

                    MenuButton {

                    } label: {
                        Text("Option B")
                    }
                } content: {
                    Button {
                        withAnimation {
                            isMenuBPresented = true
                        }
                    } label: {
                        Text("Show Menu")
                    }
                    .padding()
                }

                MenuLinkAdapter(
                    primaryAction: .disabled,
                    background: .plain,
                    isPresented: $isMenuCPresented
                ) {
                    MenuButton {

                    } label: {
                        Text("Option A")
                    }

                    MenuButton {

                    } label: {
                        Text("Option B")
                    }
                } content: {
                    Button {
                        withAnimation {
                            isMenuCPresented = true
                        }
                    } label: {
                        Text("Show Menu")
                    }
                    .padding()
                    .background(
                        ZStack {
                            if #available(iOS 15.0, *) {
                                Rectangle()
                                    .fill(Material.ultraThickMaterial)
                            }
                        }
                    )
                }
            }
        }
    }
}

#endif
