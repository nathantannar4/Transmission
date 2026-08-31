//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A view manages the presentation of a context menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``ContextMenuSourceViewLink``
///  - ``ContextMenuLinkModifier``
///  - ``ContextMenuAccessoryView``
///  - ``MenuSourceViewLink``
///
@frozen
@available(iOS 14.0, *)
public struct ContextMenuLinkAdapter<
    Content: View,
    Menu: MenuElement,
    AccessoryViews: View,
    Preview: View
>: View {

    var content: Content
    var menu: Menu
    var accessoryViews: AccessoryViews
    var preview: Preview
    var transition: ContextMenuLinkPreviewTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var visibleInset: CGFloat
    var isPresented: Binding<Bool>

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) {
        self.content = content()
        self.menu = menu()
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self.isPresented = isPresented
    }

    public var body: some View {
        ContextMenuLinkAdapterBody(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: isPresented,
            menu: menu,
            accessoryViews: accessoryViews,
            preview: preview,
            sourceView: content
        )
    }
}

@available(iOS 14.0, *)
private struct ContextMenuLinkAdapterBody<
    Menu: MenuElement,
    AccessoryViews: View,
    Preview: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: ContextMenuLinkPreviewTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var visibleInset: CGFloat
    var isPresented: Binding<Bool>
    var menu: Menu
    var accessoryViews: AccessoryViews
    var preview: Preview
    var sourceView: SourceView

    typealias UIViewType = ContextMenuLinkSourceView<SourceView, AccessoryViews>

    func makeUIView(
        context: Context
    ) -> UIViewType {
        let uiView = UIViewType(
            delegate: context.coordinator,
            content: sourceView,
            accessoryViews: accessoryViews
        )
        return uiView
    }

    func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        uiView.update(
            content: sourceView,
            accessoryViews: accessoryViews,
            transaction: context.transaction,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor?.toUIColor(in: context.environment)
        )
        context.coordinator.onUpdate(
            isPresented: isPresented,
            transition: transition,
            menu: menu,
            preview: preview,
            context: context,
            visibleInset: visibleInset,
            sourceView: uiView.sourceView ?? uiView,
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

    typealias Coordinator = ContextMenuLinkCoordinator<Menu, Preview, SourceView, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isPresented: isPresented,
            menu: menu
        )
    }
}

@available(iOS 14.0, *)
private class ContextMenuLinkSourceView<
    Content: View,
    AccessoryViews: View
>: TransitionSourceView<Content> {

    let contextMenuInteraction: ContextMenuAccessoryViewsInteraction<AccessoryViews>

    init(
        delegate: UIContextMenuInteractionDelegate,
        content: Content,
        accessoryViews: AccessoryViews,
    ) {
        let interaction = ContextMenuAccessoryViewsInteraction(delegate: delegate, accessoryViews: accessoryViews)
        self.contextMenuInteraction = interaction
        super.init(content: content)
        (sourceView ?? self).addInteraction(interaction)
    }
    
    @MainActor public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        content: Content,
        accessoryViews: AccessoryViews,
        transaction: Transaction,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: UIColor? = nil
    ) {
        super.update(content: content, transaction: transaction, cornerRadius: cornerRadius, backgroundColor: backgroundColor)
        contextMenuInteraction.update(accessoryViews: accessoryViews, transaction: transaction)
    }
}

@available(iOS 14.0, *)
final class ContextMenuLinkCoordinator<
    Menu: MenuElement,
    Preview: View,
    SourceView: View,
    Representable: PlatformViewRepresentable
>: NSObject, UIContextMenuInteractionDelegate {

    private var isPresented: Binding<Bool>
    private var menu: Menu
    private var interaction: UIContextMenuInteraction?
    private var visibleInset: CGFloat = 0

    private(set) var isPresenting = false
    private(set) var isDismissing = false
    private var didDeferUpdates = false

    private var environment: EnvironmentValues?
    private var adapter: ContextMenuPreviewViewControllerAdapter<Preview, Representable>?
    private var makeAdapter: (() -> ContextMenuPreviewViewControllerAdapter<Preview, Representable>)?
    private var sourceViewSize: CGSize?
    private weak var sourceView: UIView?

    init(
        isPresented: Binding<Bool>,
        menu: Menu
    ) {
        self.isPresented = isPresented
        self.menu = menu
    }

    func onUpdate(
        isPresented: Binding<Bool>,
        transition: ContextMenuLinkPreviewTransition,
        menu: Menu,
        preview: Preview,
        context: Representable.Context,
        visibleInset: CGFloat,
        sourceView: UIView,
        interaction: UIContextMenuInteraction?
    ) {
        assert(!swift_getIsClassType(menu), "MenuRepresentable must be value types (either a struct or an enum); it was a class")
        let oldMenu = self.menu
        self.menu = menu
        self.isPresented = isPresented
        self.environment = context.environment
        self.visibleInset = visibleInset
        self.sourceView = sourceView
        self.interaction = interaction

        if let adapter {
            adapter.update(
                preview: preview,
                context: context
            )
        } else if !preview.isEmptyView {
            makeAdapter = { [weak self] in
                ContextMenuPreviewViewControllerAdapter(
                    preview: preview,
                    sourceView: sourceView,
                    transition: transition,
                    context: context,
                    onFinish: { [weak self] in
                        self?.onFinish($0)
                    }
                )
            }
        } else {
            makeAdapter = nil
        }

        guard let interaction else { return }
        let hasVisibleMenu = interaction.hasVisibleMenu
        if isPresented.wrappedValue {
            let canUpdate: Bool = {
                guard isPresenting else { return true }
                guard !didDeferUpdates else { return false }
                // Updating the number of menu items during a presentation breaks the animation
                let oldCount = oldMenu._makeMenuElementsCount()
                let newCount = menu._makeMenuElementsCount()
                return oldCount == newCount
            }()
            if hasVisibleMenu, !canUpdate {
                didDeferUpdates = true
            }
            if hasVisibleMenu, canUpdate {
                let context = MenuRepresentableContext(
                    transaction: context.transaction,
                    environment: context.environment
                )
                interaction.update(menu, context: context)
            } else if !hasVisibleMenu, !isDismissing {
                isPresenting = true
                withCATransaction { [weak interaction] in
                    if interaction?.view?.window == nil {
                        isPresented.wrappedValue = false
                    } else {
                        interaction?.presentMenu()
                    }
                }
            } else if isDismissing {
                withCATransaction {
                    isPresented.wrappedValue = false
                }
            }
        } else if hasVisibleMenu, isPresented.wrappedValue == false {
            withCATransaction {
                interaction.dismissMenu()
            }
        } else if !hasVisibleMenu {
            isDismissing = false
        }
    }

    func onDismantle() {
        if let interaction {
            if interaction.hasVisibleMenu {
                interaction.dismissMenu()
            }
        }
        interaction = nil
        adapter = nil
        makeAdapter = nil
    }

    func willShow(animation: Animation? = nil) {
        sourceViewSize = interaction?.view?.bounds.size
        withAnimation(animation) {
            isPresented.wrappedValue = true
        }
    }

    func didShow(animation: Animation? = nil) {
        if didDeferUpdates, let interaction, let environment {
            let context = MenuRepresentableContext(
                transaction: Transaction(animation: animation),
                environment: environment
            )
            interaction.update(menu, context: context)
        }
        didDeferUpdates = false
    }

    func willHide(animation: Animation? = nil) {
        isPresenting = false
        sourceViewSize = nil
        didDeferUpdates = false
        adapter = nil
        withAnimation(animation) {
            isPresented.wrappedValue = false
        }
    }

    func onFinish(_ transaction: Transaction) {
        guard let adapter else { return }
        switch adapter.transition.value {
        case .presentation:
            adapter.viewController._dismiss(animated: transaction.isAnimated)
        case .destination:
            adapter.viewController._popViewController(animated: transaction.isAnimated)
        case .custom, .transient:
            break
        }
    }

    // MARK: - UIContextMenuInteractionDelegate

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {

        guard let environment else { return nil }
        let previewProvider: UIContextMenuContentPreviewProvider? = {
            if let viewController = adapter?.viewController {
                return {
                    viewController
                }
            }
            if makeAdapter != nil {
                return { [weak self] in
                    guard let self else { return nil }
                    if let makeAdapter {
                        adapter = makeAdapter()
                        self.makeAdapter = nil
                    }
                    return adapter?.viewController
                }
            }
            return nil
        }()
        let menuProvider: UIContextMenuActionProvider? = { [menu] _ in
            let context = MenuRepresentableContext(
                transaction: Transaction(animation: .default),
                environment: environment
            )
            return menu.makeUIMenu(context: context)
        }
        let configuration = UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: previewProvider,
            actionProvider: menuProvider
        )
        if #available(iOS 16.0, *) {
            switch menu.layoutProperties.order {
            case .automatic:
                configuration.preferredMenuElementOrder = .automatic
            case .priority:
                configuration.preferredMenuElementOrder = .priority
            case .fixed:
                configuration.preferredMenuElementOrder = .fixed
            }
        }
        if let preferredAlignment = menu.layoutProperties.preferredAlignment {
            configuration.preferredMenuAlignment = {
                switch preferredAlignment {
                case .leading:
                    return 1
                case .center:
                    return 2
                case .trailing:
                    return 3
                default:
                    return 0
                }
            }()
        }
        return configuration
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        isDismissing = false
        if let animator {
            if !isPresenting {
                isPresenting = true
            }
            animator.addAnimations { [weak self] in
                guard let self else { return }
                willShow(animation: .default)
            }
            animator.addCompletion { [weak self] in
                guard let self, isPresenting else { return }
                isPresenting = false
                didShow(animation: .default)
            }
        } else {
            willShow()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        isPresenting = false
        if let animator {
            isDismissing = true
            animator.addAnimations { [weak self] in
                guard let self else { return }
                willHide(animation: .default)
            }
            animator.addCompletion { [weak self] in
                guard let self else { return }
                isDismissing = false
            }
        } else {
            willHide()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard #unavailable(iOS 16.0) else { return nil }
        return contextMenuPreview(interaction)
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard #unavailable(iOS 16.0) else { return nil }
        return contextMenuPreview(interaction)
    }

    @available(iOS 16.0, *)
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        highlightPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return contextMenuPreview(interaction)
    }

    @available(iOS 16.0, *)
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        dismissalPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return contextMenuPreview(interaction)
    }

    func contextMenuPreview(
        _ interaction: UIContextMenuInteraction
    ) -> UITargetedPreview? {
        guard let sourceView = sourceView ?? interaction.view, sourceView.window != nil else { return nil }
        let parameters = UIPreviewParameters()
        if sourceView.isHidden {
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(rect: CGRect(origin: .zero, size: CGSize(width: sourceView.bounds.width, height: 0)))
            let preview = UITargetedPreview(
                view: {
                    if #available(iOS 26.0, *) {
                        return sourceView
                    }
                    return sourceView.superview ?? sourceView
                }(),
                parameters: parameters
            )
            preview.prefersUnmaskedPlatterStyle = !sourceView.clipsToBounds
            return preview
        } else {
            parameters.backgroundColor = sourceView.backgroundColor ?? .clear
            if visibleInset != 0 {
                let rect = sourceView.bounds
                    .insetBy(dx: visibleInset, dy: visibleInset)
                parameters.visiblePath = UIBezierPath(rect: rect)
                parameters.shadowPath = UIBezierPath()
            }
            var container = sourceView.superview
            while let ancestor = container, !ancestor.isSwiftUIPlatformViewHost {
                container = ancestor.superview
            }
            if let container {
                let center = sourceView.convert(sourceView.center, to: container)
                var transform = CGAffineTransform.identity
                // Fixes resizing while menu is open
                if let sourceViewSize, sourceViewSize != sourceView.bounds.size {
                    let scale = sourceView.traitCollection.displayScale
                    let xOffset = ((sourceViewSize.width - sourceView.bounds.size.width) / 2).rounded(scale: scale)
                    let yOffset = ((sourceViewSize.height - sourceView.bounds.size.height) / 2).rounded(scale: scale)
                    if #available(iOS 26.0, *) {
                        if isPresenting {
                            transform = CGAffineTransform(translationX: xOffset, y: yOffset)
                        }
                    } else {
                        transform = CGAffineTransform(translationX: xOffset, y: yOffset)
                    }
                }
                let preview = UITargetedPreview(
                    view: sourceView,
                    parameters: parameters,
                    target: UIPreviewTarget(
                        container: container,
                        center: center,
                        transform: transform
                    )
                )
                preview.prefersUnmaskedPlatterStyle = !sourceView.clipsToBounds
                return preview
            }
            let preview = UITargetedPreview(
                view: sourceView,
                parameters: parameters
            )
            preview.prefersUnmaskedPlatterStyle = !sourceView.clipsToBounds
            return preview
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: any UIContextMenuInteractionCommitAnimating
    ) {
        guard
            let previewViewController = animator.previewViewController,
            let adapter,
            adapter.viewController == previewViewController,
            let viewController = interaction.view?.viewController
        else {
            animator.preferredCommitStyle = .dismiss
            return
        }
        switch adapter.transition.value {
        case .presentation:
            animator.preferredCommitStyle = .pop
            animator.addCompletion {
                viewController.present(previewViewController, animated: true)
            }
        case .destination:
            guard
                let navigationController = adapter.viewController.navigationController
            else {
                animator.preferredCommitStyle = .dismiss
                return
            }
            animator.preferredCommitStyle = .pop
            animator.addCompletion {
                navigationController.pushViewController(previewViewController, animated: true)
            }
        case .custom(let action):
            animator.preferredCommitStyle = .dismiss
            animator.addCompletion {
                action()
            }
        case .transient:
            animator.preferredCommitStyle = .dismiss
        }
    }
}

@available(iOS 14.0, *)
class ContextMenuAccessoryViewsInteraction<
    AccessoryViews: View
>: UIContextMenuInteraction {

    private var accessoryViews: AccessoryViews
    private var adapter: ContextMenuAccessoryViewAdapter<AccessoryViews>?

    init(
        delegate: UIContextMenuInteractionDelegate,
        accessoryViews: AccessoryViews
    ) {
        self.accessoryViews = accessoryViews
        super.init(delegate: delegate)
    }

    func update(
        accessoryViews newValue: AccessoryViews,
        transaction: Transaction
    ) {
        accessoryViews = newValue
        adapter?.update(accessoryViews: accessoryViews, transaction: transaction)
        if !hasVisibleMenu, adapter != nil {
            adapter = nil
        }
    }

    @objc
    func _delegate_getAccessoryViewsForConfiguration(
        _ configuration: UIContextMenuConfiguration
    ) -> [UIView] {
        adapter = nil
        guard AccessoryViews.self != EmptyView.self else { return [] }
        adapter = ContextMenuAccessoryViewAdapter(
            accessoryViews: accessoryViews,
            interaction: self,
            configuration: configuration
        )
        return adapter?.accessoryViews ?? []
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
class ContextMenuPreviewViewControllerAdapter<
    Preview: View,
    Representable: UIViewRepresentable
> {

    let transition: ContextMenuLinkPreviewTransition

    var viewController: UIViewController! {
        switch storage {
        case .presentation(let adapter):
            return adapter.viewController
        case .destination(let adapter):
            return adapter.viewController
        case .transient(let adapter):
            return adapter.viewController
        }
    }

    private enum Storage {
        case presentation(ContextMenuPresentationPreviewViewControllerAdapter<Preview, Representable>)
        case destination(ContextMenuDestinationPreviewViewControllerAdapter<Preview, Representable>)
        case transient(ContextMenuCustomPreviewViewControllerAdapter<Preview, Representable>)
    }
    private let storage: Storage

    init(
        preview: Preview,
        sourceView: UIView,
        transition: ContextMenuLinkPreviewTransition,
        context: Representable.Context,
        onFinish: @escaping (Transaction) -> Void
    ) {
        self.transition = transition
        switch transition.value {
        case .presentation:
            let adapter = ContextMenuPresentationPreviewViewControllerAdapter(
                destination: preview,
                sourceView: sourceView,
                transition: .default,
                context: context,
                isPresented: .constant(true),
                onDismiss: { onFinish($1) }
            )
            storage = .presentation(adapter)
        case .destination:
            let adapter = ContextMenuDestinationPreviewViewControllerAdapter(
                destination: preview,
                sourceView: sourceView,
                transition: .default,
                context: context,
                isPresented: .constant(true),
                onPop: { onFinish($1) }
            )
            storage = .destination(adapter)
        case .custom, .transient:
            let adapter = ContextMenuCustomPreviewViewControllerAdapter(
                destination: preview,
                sourceView: sourceView,
                transition: .default,
                context: context,
                isPresented: .constant(true),
                onDismiss: { onFinish($1) }
            )
            storage = .transient(adapter)
        }
    }

    func update(
        preview: Preview,
        context: Representable.Context
    ) {
        switch storage {
        case .presentation(let adapter):
            adapter.update(
                destination: preview,
                context: context,
                isPresented: .constant(true)
            )
        case .destination(let adapter):
            adapter.update(
                destination: preview,
                context: context,
                isPresented: .constant(true)
            )
        case .transient(let adapter):
            adapter.updateViewController(
                content: preview,
                context: context
            )
        }
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
class ContextMenuPresentationPreviewViewControllerAdapter<
    Preview: View,
    Representable: UIViewRepresentable
>: PresentationLinkDestinationViewControllerAdapter<Preview, Representable> {

    override func makeHostingController(
        content: Preview,
        context: Representable.Context
    ) -> UIViewController {
        let viewController = super.makeHostingController(content: content, context: context) as! DestinationController
        if let window = sourceView?.window {
            let width = window.bounds.inset(by: window.layoutMargins).width
            viewController.preferredContentSize = viewController.view.idealSize(for: width)
        }
        return viewController
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
class ContextMenuDestinationPreviewViewControllerAdapter<
    Preview: View,
    Representable: UIViewRepresentable
>: DestinationLinkDestinationViewControllerAdapter<Preview, Representable> {

    override func makeHostingController(
        content: Preview,
        context: Representable.Context
    ) -> UIViewController {
        let viewController = super.makeHostingController(content: content, context: context) as! DestinationController
        if let window = sourceView?.window {
            let width = window.bounds.inset(by: window.layoutMargins).width
            viewController.preferredContentSize = viewController.view.idealSize(for: width)
        }
        return viewController
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
class ContextMenuCustomPreviewViewControllerAdapter<
    Preview: View,
    Representable: UIViewRepresentable
>: ContextMenuPresentationPreviewViewControllerAdapter<Preview, Representable> {

    override func makeHostingController(
        content: Preview,
        context: Representable.Context
    ) -> UIViewController {
        let viewController = super.makeHostingController(content: content, context: context) as! DestinationController
        viewController.disableSafeArea = true
        viewController.view.backgroundColor = sourceView?.backgroundColor
        viewController.view.layer.cornerRadius = sourceView?.layer.cornerRadius ?? 0
        return viewController
    }
}

extension UIContextMenuInteraction {

    var hasVisibleMenu: Bool {
        // _hasVisibleMenu
        let aSelector = NSStringFromBase64EncodedString("X2hhc1Zpc2libGVNZW51")
        guard
            let aSelector,
            responds(to: NSSelectorFromString(aSelector))
        else {
            return false
        }
        return value(forKey: aSelector) as? Bool ?? false
    }

    func presentMenu() {
        // _presentMenuAtLocation:
        let aSelector = NSSelectorFromBase64EncodedString("X3ByZXNlbnRNZW51QXRMb2NhdGlvbjo=")
        guard
            let aSelector,
            responds(to: aSelector),
            let view
        else {
            return
        }
        let point = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        perform(aSelector, with: NSValue(cgPoint: point))
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct ContextMenuLinkAdapter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isMenuAPresented = false
        @State var isMenuBPresented = false
        @State var isMenuCPresented = false
        @State var isMenuDPresented = false
        @State var isMenuEPresented = false
        @State var isMenuFPresented = false
        @State var hasCustomPreview = true

        var body: some View {
            VStack {
                ContextMenuLinkAdapter(
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
                        Text("Hold to show menu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                ContextMenuLinkAdapter(
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
                }

                ContextMenuLinkAdapter(
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .background {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.red)
                                .padding(-12)
                        }
                }
                .padding(.vertical, 12)

                Toggle(isOn: $hasCustomPreview) {
                    Text("hasCustomPreview")
                }

                ContextMenuLinkAdapter(
                    isPresented: $isMenuDPresented
                ) {
                    MenuButton {

                    } label: {
                        Text("Option A")
                    }

                    MenuButton {

                    } label: {
                        Text("Option B")
                    }
                } preview: {
                    if hasCustomPreview {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .frame(width: 300, height: 300)
                    }
                } content: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                }

                ContextMenuLinkAdapter(
                    isPresented: $isMenuEPresented
                ) {
                    MenuButton {

                    } label: {
                        Text("Option A")
                    }

                    MenuButton {

                    } label: {
                        Text("Option B")
                    }
                } preview: {
                    Text("""
                    Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

                    Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

                    Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.
                    """)
                    .frame(maxHeight: 300, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .ignoresSafeArea()
                    }
                } content: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                }

                ContextMenuLinkAdapter(
                    isPresented: $isMenuFPresented
                ) {
                    MenuGroup(preferredAlignment: .leading) {
                        MenuButton {

                        } label: {
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Text("Option B")
                        }
                    }
                } content: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .frame(width: 300, height: 100)
                } accessoryViews: {
                    ContextMenuAccessoryView(
                        location: .preview,
                        alignment: .topLeading,
                        anchor: .center
                    ) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .frame(width: 300, height: 50)
                    }
                }
            }
        }
    }
}

#endif
