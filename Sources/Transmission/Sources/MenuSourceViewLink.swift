//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// The background style of the ``MenuLink``,
///
/// > Note: Neccesary for the correct glass morphing effect
///
@frozen
@available(iOS 14.0, *)
public struct MenuSourceViewLinkBackgroundStyle: Equatable, Sendable {

    @usableFromInline
    enum Effect: Sendable {
        case plain
        case glass
        case prominentGlass
        case clearGlass
        case prominentClearGlass
    }
    @usableFromInline
    var effect: Effect

    @usableFromInline
    var color: Color?

    public static let plain = MenuSourceViewLinkBackgroundStyle(effect: .plain)

    @available(iOS 26.0, *)
    public static let glass = MenuSourceViewLinkBackgroundStyle(effect: .glass)

    @available(iOS 26.0, *)
    public static func glass(tint: Color) -> MenuSourceViewLinkBackgroundStyle {
        MenuSourceViewLinkBackgroundStyle(effect: .prominentGlass, color: tint)
    }

    @available(iOS 26.0, *)
    public static let clearGlass = MenuSourceViewLinkBackgroundStyle(effect: .clearGlass)

    @available(iOS 26.0, *)
    public static func clearGlass(tint: Color) -> MenuSourceViewLinkBackgroundStyle {
        MenuSourceViewLinkBackgroundStyle(effect: .prominentClearGlass, color: tint)
    }
}

/// A view that manages the presentation of a menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``MenuLink``
///  - ``MenuLinkAdapter``
///  - ``MenuLinkModifier``
///
@available(iOS 14.0, *)
@frozen
public struct MenuSourceViewLink<
    Menu: MenuElement,
    Label: View
>: View {

    var label: Label
    var menu: Menu
    var primaryAction: MenuLinkPrimaryAction
    var cornerRadius: CornerRadiusOptions?
    var background: MenuSourceViewLinkBackgroundStyle
    var visibleInset: CGFloat

    @StateOrBinding var isPresented: Bool

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuSourceViewLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label,
        primaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            primaryAction: primaryAction.map { .custom($0) } ?? .showMenu,
            menu: menu,
            label: label
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuSourceViewLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        primaryAction: MenuLinkPrimaryAction,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.menu = menu()
        self.primaryAction = primaryAction
        self.cornerRadius = cornerRadius
        self.background = background
        self.visibleInset = visibleInset
        self._isPresented = .init(false)
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuSourceViewLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label,
        primaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            isPresented: isPresented,
            primaryAction: primaryAction.map { .custom($0) } ?? .showMenu,
            menu: menu,
            label: label
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuSourceViewLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        primaryAction: MenuLinkPrimaryAction,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.menu = menu()
        self.primaryAction = primaryAction
        self.cornerRadius = cornerRadius
        self.background = background
        self.visibleInset = visibleInset
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        MenuSourceViewBody(
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            isPresented: $isPresented,
            menu: menu,
            sourceView: label,
            primaryAction: primaryAction
        )
    }
}

@available(iOS 14.0, *)
extension MenuSourceViewLinkBackgroundStyle {

    @available(iOS 15.0, *)
    @MainActor
    func makeConfiguration() -> UIButton.Configuration {
        var configuration: UIButton.Configuration = .plain()
        switch effect {
        case .glass:
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                configuration = UIButton.Configuration.glass()
                configuration.baseBackgroundColor = color?.toUIColor()
            }
            #endif
        case .prominentGlass:
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                configuration = UIButton.Configuration.prominentGlass()
                configuration.baseBackgroundColor = color?.toUIColor()
            }
            #endif
        case .clearGlass:
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                configuration = UIButton.Configuration.clearGlass()
                configuration.baseBackgroundColor = color?.toUIColor()
            }
            #endif
        case .prominentClearGlass:
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                configuration = UIButton.Configuration.prominentClearGlass()
                configuration.baseBackgroundColor = color?.toUIColor()
            }
            #endif
        case .plain:
            configuration.background.cornerRadius = 0
        }
        return configuration
    }
}


@available(iOS 14.0, *)
private struct MenuSourceViewBody<
    Menu: MenuElement,
    SourceView: View
>: UIViewRepresentable {

    var cornerRadius: CornerRadiusOptions?
    var background: MenuSourceViewLinkBackgroundStyle
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
            context: context
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.primaryAction = primaryAction
        uiView.background = background
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

    var background: MenuSourceViewLinkBackgroundStyle {
        didSet {
            guard #available(iOS 15.0, *), oldValue != background else { return }
            setNeedsUpdateConfiguration()
        }
    }

    private let hostingView: TransitionSourceView<Content>
    private let coordinator: MenuSourceViewBody<Menu, Content>.Coordinator

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
        background: MenuSourceViewLinkBackgroundStyle,
        context: MenuSourceViewBody<Menu, Content>.Context
    ) {
        self.background = background
        self.hostingView = TransitionSourceView(content: content)
        self.coordinator = context.coordinator
        super.init(frame: .zero)

        if #available(iOS 15.0, *) {
            configuration = background.makeConfiguration()
        }

        isContextMenuInteractionEnabled = true

        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
        context: MenuSourceViewBody<Menu, Content>.Context,
        cornerRadius: CornerRadiusOptions?
    ) {
        hostingView.update(
            content: content,
            transaction: context.transaction,
            cornerRadius: cornerRadius
        )
    }

    @available(iOS 15.0, *)
    override func updateConfiguration() {
        configuration = background.makeConfiguration()
        contentView.addSubview(hostingView)
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
struct MenuSourceViewLink_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                StateAdapter(initialValue: false) { $isSelected in
                    MenuSourceViewLink(background: isSelected ? .clearGlass(tint: .blue) : .glass) {
                        MenuGroup {
                            MenuButton {
                                withAnimation {
                                    isSelected.toggle()
                                }
                            } label: {
                                Text("Option A")
                            }
                        }
                    } label: {
                        VStack {
                            Text("Glass Menu")

                            if isSelected {
                                Text("Selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                }

                StateAdapter(initialValue: false) { $isSelected in
                    MenuSourceViewLink(background: .glass(tint: isSelected ? .green : .red)) {
                        MenuGroup {
                            MenuButton {
                                withAnimation {
                                    isSelected.toggle()
                                }
                            } label: {
                                Text("Toggle Selection")
                            }
                        }
                    } label: {
                        VStack {
                            Text("Glass Menu")

                            if isSelected {
                                Text("Selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                }
            }
            #endif

            HStack {
                MenuSourceViewLink {

                } label: {
                    Text("Empty Menu")
                }

                MenuSourceViewLink {
                    MenuGroup {

                    }
                } label: {
                    Text("Empty Menu")
                }
            }

            MenuSourceViewLink {
                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }
            } label: {
                Text("Single Action Menu")
            }

            MenuSourceViewLink {
                MenuButton(attributes: .destructive) {

                } label: {
                    Text("Delete")
                }

                MenuButton(attributes: .disabled) {

                } label: {
                    Text("Disabled")
                }

                MenuButton(attributes: .hidden) {

                } label: {
                    Text("Hidden")
                }
            } label: {
                Text("Multi Action Menu")
            }

            MenuSourceViewLink {
                for item in ["A", "B", "C"] {
                    MenuButton {

                    } label: {
                        Text("Action \(item)")
                    }
                }
            } label: {
                Text("For loop Action Menu")
            }

            MenuSourceViewLink {
                MenuGroup {
                    for item in ["A", "B", "C"] {
                        MenuButton {

                        } label: {
                            Text("Action \(item)")
                        }
                    }
                }
            } label: {
                Text("For loop Group Menu")
            }

            if #available(iOS 16.0, *) {
                StateAdapter(initialValue: false) { $isEnabled in
                    MenuSourceViewLink {
                        MenuGroup {
                            if isEnabled {
                                MenuButton(attributes: .keepsMenuPresented) {
                                    withAnimation {
                                        isEnabled = false
                                    }
                                } label: {
                                    Text("Turn Off")
                                }
                            } else {
                                MenuButton(attributes: .keepsMenuPresented) {
                                    withAnimation {
                                        isEnabled = true
                                    }
                                } label: {
                                    Text("Turn On")
                                }
                            }
                        }

                        if isEnabled {
                            MenuButton(attributes: .keepsMenuPresented) {
                                withAnimation {
                                    isEnabled = false
                                }
                            } label: {
                                Text("Turn Off")
                            }
                        }

                        MenuGroup(id: "details") {
                            MenuButton(attributes: .keepsMenuPresented) {
                                withAnimation {
                                    isEnabled.toggle()
                                }
                            } label: {
                                Text("Toggle")
                            }

                            if isEnabled {
                                MenuButton(attributes: .disabled) {

                                } label: {
                                    Text("Option A")
                                }
                            } else {
                                MenuButton(attributes: .disabled) {

                                } label: {
                                    Text("Option B")
                                }
                            }
                        } label: {
                            Text(isEnabled ? "Enabled Details" : "Disabled Details")
                        }

                        MenuButton(attributes: .keepsMenuPresented) {
                            withAnimation {
                                isEnabled.toggle()
                            }
                        } label: {
                            Text("Toggle")
                        }
                    } label: {
                        Text("Conditional Menu")
                    }
                }

                StateAdapter(initialValue: 1) { $selection in
                    MenuSourceViewLink {
                        for item in 1...(selection + 1) {
                            MenuButton(
                                state: selection == item ? .on : .off,
                                attributes: .keepsMenuPresented
                            ) {
                                withAnimation {
                                    selection = item
                                }
                            } label: {
                                Text("Action \(item)")
                            }
                        }

                        MenuGroup(id: "a") {
                            for item in 1...(selection + 1) {
                                MenuButton(
                                    state: selection == item ? .on : .off,
                                    attributes: .keepsMenuPresented
                                ) {
                                    withAnimation {
                                        selection = item
                                    }
                                } label: {
                                    Text("Action \(item)")
                                }
                            }
                        } label: {
                            Text("Sub Selection A")
                        }

                        MenuGroup(id: "b") {
                            for item in 1...(selection + 1) {
                                MenuButton(
                                    state: selection == item ? .on : .off,
                                    attributes: .keepsMenuPresented
                                ) {
                                    withAnimation {
                                        selection = item
                                    }
                                } label: {
                                    Text("Action \(item)")
                                }
                            }
                        } label: {
                            Text("Sub Selection B")
                        }
                    } label: {
                        Text("Select Action Menu")
                    }
                }
            }

            MenuSourceViewLink {
                MenuGroup {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                }
            } label: {
                Text("Single Action SubMenu")
            }

            MenuSourceViewLink {
                MenuGroup(id: "a") {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                } label: {
                    Image(systemName: "apple.logo")
                    Text("Submenu 1")
                }

                MenuGroup(id: "b") {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                } label: {
                    Image(systemName: "apple.logo")
                    Text("Submenu 2")
                }
            } label: {
                Text("Multi Menu")
            }

            if #available(iOS 16.0, *) {
                MenuSourceViewLink {
                    MenuGroup(size: .medium) {
                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option C")
                        }
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "apple.logo")
                        Text("Option D")
                    }
                } label: {
                    Text("Medium Menu")
                }

                MenuSourceViewLink {
                    MenuGroup(size: .small) {
                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option C")
                        }
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "apple.logo")
                        Text("Option D")
                    }
                } label: {
                    Text("Small Menu")
                }

                MenuSourceViewLink {
                    MenuGroup(order: .fixed) {
                        MenuButton {

                        } label: {
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Text("Option C")
                        }
                    }
                } label: {
                    Text("Fixed Order Menu")
                }

                MenuSourceViewLink {
                    MenuGroup(order: .priority) {
                        MenuButton {

                        } label: {
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Text("Option C")
                        }
                    }
                } label: {
                    Text("Priority Order Menu")
                }
            }
        }
    }
}

#endif
