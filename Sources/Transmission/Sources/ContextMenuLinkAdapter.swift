//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 16.0, *)
public enum ContextMenuOrder {

    /// The default order
    case automatic

    /// Allows the system to choose the appropriate ordering strategy for the current context.
    case priority

    /// Order menu elements according to priority. Keeping the first element in the UIMenu closest to user's interaction point.
    case fixed
}

@available(iOS 14.0, *)
public protocol ContextMenuProvider {

    @available(iOS 16.0, *)
    var order: ContextMenuOrder { get }

    @MainActor @preconcurrency func makeUIMenu(context: Context) -> UIMenu

    typealias Context = ContextMenuProviderContext
}

@frozen
@available(iOS 14.0, *)
public struct ContextMenuProviderContext {
    public var environment: EnvironmentValues
}

@available(iOS 16.0, *)
extension ContextMenuProvider {
    public var order: ContextMenuOrder { .automatic }
}

/// A view manages the presentation of a context menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``ContextMenuSourceViewLink``
///  - ``ContextMenuLinkModifier``
///  - ``ContextMenuAccessoryView``
///
@frozen
@available(iOS 14.0, *)
public struct ContextMenuLinkAdapter<
    Label: View,
    Menu: ContextMenuProvider,
    AccessoryViews: View,
    Preview: View
>: View {

    var label: Label
    var menu: Menu
    var accessoryViews: AccessoryViews
    var preview: Preview
    var transition: ContextMenuLinkPreviewTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var visibleInset: CGFloat

    @StateOrBinding var isPresented: Bool

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        menu: Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews,
    ) {
        self.label = label()
        self.menu = menu
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self._isPresented = .init(false)
    }

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews,
    ) {
        self.label = label()
        self.menu = menu
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        ContextMenuLinkAdapterBody(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: $isPresented,
            menu: menu,
            accessoryViews: accessoryViews,
            preview: preview,
            sourceView: label
        )
    }
}

@available(iOS 14.0, *)
private struct ContextMenuLinkAdapterBody<
    Menu: ContextMenuProvider,
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

    typealias UIViewType = TransitionSourceView<SourceView>

    func makeUIView(
        context: Context
    ) -> UIViewType {
        let uiView = TransitionSourceView(
            content: sourceView
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
            accessoryViews: accessoryViews,
            preview: preview,
            context: context,
            visibleInset: visibleInset,
            sourceView: uiView.sourceView ?? uiView
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

    typealias Coordinator = ContextMenuLinkCoordinator<Menu, AccessoryViews, Preview, SourceView, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isPresented: isPresented,
            menu: menu
        )
    }
}

@available(iOS 14.0, *)
final class ContextMenuLinkCoordinator<
    Menu: ContextMenuProvider,
    AccessoryViews: View,
    Preview: View,
    SourceView: View,
    Representable: PlatformViewRepresentable
>: NSObject, UIContextMenuInteractionDelegate {

    private var menu: Menu
    private var interaction: ContextMenuInteraction<AccessoryViews>?
    private var isPresented: Binding<Bool>
    private var visibleInset: CGFloat = 0

    private var environment: EnvironmentValues?
    private var adapter: ContextMenuPreviewViewControllerAdapter<Preview, Representable>?

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
        accessoryViews: AccessoryViews,
        preview: Preview,
        context: Representable.Context,
        visibleInset: CGFloat,
        sourceView: UIView
    ) {
        assert(!swift_getIsClassType(menu), "ContextMenuProvider must be value types (either a struct or an enum); it was a class")
        self.menu = menu
        self.isPresented = isPresented
        self.environment = context.environment
        self.visibleInset = visibleInset

        if let interaction {
            interaction.update(
                accessoryViews: accessoryViews,
                transaction: context.transaction
            )
        } else {
            let interaction = ContextMenuInteraction(delegate: self, accessoryViews: accessoryViews)
            sourceView.addInteraction(interaction)
            self.interaction = interaction
        }

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
        let isPresented = isPresented.wrappedValue
        if isPresented {
            if interaction.hasVisibleMenu {
                let context = ContextMenuProviderContext(
                    environment: context.environment
                )
                let menu = menu.makeUIMenu(context: context)
                interaction.updateVisibleMenu({ _ in menu })
            } else {
                withCATransaction {
                    interaction.presentMenu()
                }
            }
        } else if interaction.hasVisibleMenu {
            withCATransaction {
                interaction.dismissMenu()
            }
        }
    }

    func onDismantle() {
        if let interaction {
            interaction.view?.removeInteraction(interaction)
            if interaction.hasVisibleMenu {
                interaction.dismissMenu()
            }
        }
        interaction = nil
        adapter = nil
    }

    func didShow(animation: Animation? = nil) {
        withAnimation(animation) {
            isPresented.wrappedValue = true
        }
    }

    func didHide(animation: Animation? = nil) {
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
        let context = ContextMenuProviderContext(
            environment: environment
        )
        let uiMenu = menu.makeUIMenu(context: context)
        guard !uiMenu.children.isEmpty else {
            didHide()
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
            switch menu.order {
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
        if let animator {
            animator.addAnimations { [weak self] in
                guard let self else { return }
                didShow(animation: .default)
            }
        } else {
            didShow()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        if let animator {
            animator.addAnimations { [weak self] in
                guard let self else { return }
                didHide(animation: .default)
            }
        } else {
            didHide()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        highlightPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return contextMenuPreview(interaction, isPresenting: true)
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        dismissalPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        return contextMenuPreview(interaction, isPresenting: false)
    }

    func contextMenuPreview(
        _ interaction: UIContextMenuInteraction,
        isPresenting: Bool
    ) -> UITargetedPreview? {
        guard let sourceView = interaction.view else { return nil }
        let parameters = UIPreviewParameters()
        if sourceView.isHidden {
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(rect: CGRect(origin: .zero, size: CGSize(width: sourceView.bounds.width, height: 0)))
            parameters.shadowPath = UIBezierPath()
        } else {
            parameters.backgroundColor = sourceView.backgroundColor ?? .clear
            if visibleInset != 0 {
                let rect = sourceView.bounds.insetBy(dx: visibleInset, dy: visibleInset)
                parameters.visiblePath = UIBezierPath(rect: rect)
            }
            if sourceView.layer.cornerRadius < 1 {
                parameters.shadowPath = UIBezierPath()
            }
        }
        let preview = UITargetedPreview(
            view: sourceView,
            parameters: parameters
        )
        return preview
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
class ContextMenuInteraction<
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
                transition: .default(.init()),
                context: context,
                isPresented: .constant(true),
                onDismiss: { onFinish($1) }
            )
            storage = .presentation(adapter)
        case .destination:
            let adapter = ContextMenuDestinationPreviewViewControllerAdapter(
                destination: preview,
                sourceView: sourceView,
                transition: .default(.init()),
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
            let view = view
        else {
            return
        }
        let point = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        perform(aSelector, with: NSValue(cgPoint: point))
    }
}

#endif
