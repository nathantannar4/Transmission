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
        transaction: Transaction
    ) {
        super.update(content: content, transaction: transaction)
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
    private var ignoreUpdates = 0

    private var environment: EnvironmentValues?
    private var adapter: ContextMenuPreviewViewControllerAdapter<Preview, Representable>?
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
        self.menu = menu
        self.isPresented = isPresented
        self.environment = context.environment
        self.visibleInset = visibleInset
        self.sourceView = sourceView
        self.interaction = interaction

        if Preview.self != EmptyView.self {
            if let adapter {
                adapter.update(
                    preview: preview,
                    context: context
                )
            } else {
                adapter = ContextMenuPreviewViewControllerAdapter(
                    preview: preview,
                    sourceView: sourceView,
                    transition: transition,
                    context: context,
                    navigationController: sourceView._viewController?._navigationController,
                    onFinish: { [weak self] in
                        self?.onFinish($0)
                    }
                )
            }
        }

        guard let interaction else { return }
        let hasVisibleMenu = interaction.hasVisibleMenu
        if isPresenting {
            ignoreUpdates -= 1
        }
        if isPresented.wrappedValue {
            if hasVisibleMenu, !isPresenting {
                let context = MenuRepresentableContext(
                    transaction: context.transaction,
                    environment: context.environment
                )
                interaction.update(menu, context: context)
            } else if !hasVisibleMenu, !isDismissing {
                isPresenting = true
                withCATransaction {
                    interaction.presentMenu()
                }
            } else if isDismissing {
                withCATransaction {
                    isPresented.wrappedValue = false
                }
            }
        } else if hasVisibleMenu, !isPresenting, isPresented.wrappedValue == false {
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
    }

    func willShow(animation: Animation? = nil) {
        sourceViewSize = interaction?.view?.bounds.size
        withAnimation(animation) {
            isPresented.wrappedValue = true
        }
    }

    func didShow(animation: Animation? = nil) {
        if ignoreUpdates < 0, let interaction, let environment {
            let context = MenuRepresentableContext(
                transaction: Transaction(animation: animation),
                environment: environment
            )
            withCATransaction { [menu] in
                interaction.update(menu, context: context)
            }
        }
        ignoreUpdates = 0
    }

    func willHide(animation: Animation? = nil) {
        isPresenting = false
        sourceViewSize = nil
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
        case .custom:
            break
        }
    }

    // MARK: - UIContextMenuInteractionDelegate

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {

        guard let environment else { return nil }
        let context = MenuRepresentableContext(
            transaction: Transaction(animation: .default),
            environment: environment
        )
        let uiMenu = menu.makeUIMenu(context: context)
        guard !uiMenu.children.isEmpty else {
            willHide()
            return nil
        }

        let configuration = UIContextMenuConfiguration(
            identifier: nil
        ) { [weak adapter] in
            guard let viewController = adapter?.viewController else { return nil }
            return viewController
        } actionProvider: { _ in
            return uiMenu
        }
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
                // Skip 2 superfulous updates when triggered via UI interaction, since updating the menu
                // cancels touch interaction.
                ignoreUpdates = 2
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
        guard let sourceView = sourceView ?? interaction.view else { return nil }
        let parameters = UIPreviewParameters()
        if sourceView.isHidden {
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(rect: CGRect(origin: .zero, size: CGSize(width: sourceView.bounds.width, height: 0)))
            parameters.shadowPath = UIBezierPath()
            let preview = UITargetedPreview(
                view: {
                    if #available(iOS 26.0, *) {
                        return sourceView
                    }
                    return sourceView.superview ?? sourceView
                }(),
                parameters: parameters
            )
            return preview
        } else {
            parameters.backgroundColor = sourceView.backgroundColor ?? .clear
            if visibleInset != 0 {
                let rect = sourceView.bounds
                    .insetBy(dx: visibleInset, dy: visibleInset)
                parameters.visiblePath = UIBezierPath(rect: rect)
            }
            if sourceView.layer.cornerRadius < 1 {
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
                return preview
            }
            let preview = UITargetedPreview(
                view: sourceView,
                parameters: parameters
            )
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
                let navigationController = adapter.navigationController
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

    @objc func _delegate_getAccessoryViewsForConfiguration(
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
        case .custom(let adapter):
            return adapter.viewController
        }
    }

    var navigationController: UINavigationController? {
        switch storage {
        case .presentation, .custom:
            return nil
        case .destination(let adapter):
            return adapter.navigationController
        }
    }

    private enum Storage {
        case presentation(ContextMenuPresentationPreviewViewControllerAdapter<Preview, Representable>)
        case destination(ContextMenuDestinationPreviewViewControllerAdapter<Preview, Representable>)
        case custom(ContextMenuCustomPreviewViewControllerAdapter<Preview, Representable>)
    }
    private let storage: Storage

    init(
        preview: Preview,
        sourceView: UIView,
        transition: ContextMenuLinkPreviewTransition,
        context: Representable.Context,
        navigationController: UINavigationController?,
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
                navigationController: navigationController,
                isPresented: .constant(true),
                onPop: { onFinish($1) }
            )
            storage = .destination(adapter)
        case .custom:
            let adapter = ContextMenuCustomPreviewViewControllerAdapter(
                content: preview,
                context: context
            )
            storage = .custom(adapter)
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
        case .custom(let adapter):
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
        if #available(iOS 16.0, *) {
            viewController.sizingOptions = .preferredContentSize
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
        if #available(iOS 16.0, *) {
            viewController.sizingOptions = .preferredContentSize
        }
        return viewController
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
class ContextMenuCustomPreviewViewControllerAdapter<
    Preview: View,
    Representable: UIViewRepresentable
>: ViewControllerAdapter<Preview, Representable> {

    override func makeHostingController(
        content: Preview,
        context: Representable.Context
    ) -> UIViewController {
        let viewController = super.makeHostingController(content: content, context: context) as! HostingController<Preview>
        if #available(iOS 16.0, *) {
            viewController.sizingOptions = .preferredContentSize
        }
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
                        Text("Holde to show menu")
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
            }
        }
    }
}

#endif
