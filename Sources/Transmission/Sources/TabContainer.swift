//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct TabTransition {

    @usableFromInline
    enum Value {
        case `default`
        case representable(any TabTransitionRepresentable)
    }
    @usableFromInline
    var value: Value

    /// The default transition style of the `UITabBarController`.
    public static var `default`: TabTransition {
        TabTransition(value: .default)
    }

    /// A custom transition style.
    public static func custom<
        T: TabTransitionRepresentable
    >(
        _ transition: T
    ) -> TabTransition {
        TabTransition(
            value: .representable(transition)
        )
    }
}

/// The context for a ``PresentationLinkTransitionRepresentable``
@available(iOS 14.0, *)
@frozen
public struct TabTransitionRepresentableContext {
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

@available(iOS 14.0, *)
public protocol TabTransitionRepresentable {

    typealias Context = TabTransitionRepresentableContext
    associatedtype UIAnimationControllerType: UIViewControllerAnimatedTransitioning
    associatedtype UIInteractionControllerType: UIViewControllerInteractiveTransitioning

    /// The animation controller to use for the transition.
    @MainActor @preconcurrency func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIAnimationControllerType?

    /// The interaction controller to use for the transition.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func tabBarController(
        _ tabBarController: UITabBarController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIInteractionControllerType?
}

@available(iOS 14.0, *)
extension TabTransitionRepresentable {

    public func tabBarController(
        _ tabBarController: UITabBarController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

@available(iOS 14.0, *)
open class TabControllerTransition: ViewControllerTransition {

    public init(animation: Animation?) {
        super.init(isPresenting: true, animation: animation)
        wantsInteractiveStart = false
    }
}

@available(iOS 14.0, *)
extension TabTransition {

    /// The cross dissolve transition style.
    public static var crossDissolve: TabTransition {
        .crossDissolve()
    }

    /// The cross dissolve transition style.
    public static func crossDissolve(
        transform: CGAffineTransform = .identity
    ) -> TabTransition {
        .custom(
            CrossDissolveTabTransition(
                options: .init(
                    transform: transform
                )
            )
        )
    }
}

@available(iOS 14.0, *)
public struct CrossDissolveTabTransition: TabTransitionRepresentable {

    /// The transition options for a cross dissolve transition.
    @frozen
    public struct Options {

        public var transform: CGAffineTransform

        public init(
            transform: CGAffineTransform = .identity
        ) {
            self.transform = transform
        }
    }

    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        return CrossDissolveTabControllerTransition(
            transform: options.transform,
            animation: context.transaction.animation
        )
    }
}

@available(iOS 14.0, *)
open class CrossDissolveTabControllerTransition: TabControllerTransition {

    public var transform: CGAffineTransform

    public init(
        transform: CGAffineTransform = .identity,
        animation: Animation?
    ) {
        self.transform = transform
        super.init(animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        let transition = CrossDissolveTransitionAnimator(
            transform: transform
        )
        transition.animateTransition(with: animator, using: transitionContext, isPresenting: isPresenting)
    }
}

@available(iOS 14.0, *)
extension TabTransition {

    /// The cross dissolve transition style.
    public static var slide: TabTransition {
        .slide()
    }

    /// The cross dissolve transition style.
    public static func slide(
        initialOpacity: CGFloat = 1
    ) -> TabTransition {
        .custom(
            SlideTabTransition(
                options: .init(
                    initialOpacity: initialOpacity
                )
            )
        )
    }
}

@available(iOS 14.0, *)
public struct SlideTabTransition: TabTransitionRepresentable {

    /// The transition options for a slide transition.
    @frozen
    public struct Options {

        public var initialOpacity: CGFloat

        public init(
            initialOpacity: CGFloat = 1
        ) {
            self.initialOpacity = initialOpacity
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        let fromIndex = tabBarController.viewControllers?.firstIndex(of: fromVC)
        let toIndex = tabBarController.viewControllers?.firstIndex(of: toVC)
        let edge: Edge = {
            guard let fromIndex, let toIndex else { return .trailing }
            return fromIndex > toIndex ? .leading : .trailing
        }()
        return SlideTabControllerTransition(
            edge: edge,
            initialOpacity: options.initialOpacity,
            animation: context.transaction.animation
        )
    }
}

@available(iOS 14.0, *)
open class SlideTabControllerTransition: TabControllerTransition {

    public var edge: Edge
    public var initialOpacity: CGFloat

    public init(
        edge: Edge,
        initialOpacity: CGFloat,
        animation: Animation?
    ) {
        self.edge = edge
        self.initialOpacity = initialOpacity
        super.init(animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        let transition = SlideTransitionAnimator(
            edge: edge,
            initialOpacity: initialOpacity,
            animatedViews: [.from, .to]
        )
        transition.animateTransition(with: animator, using: transitionContext, isPresenting: isPresenting)
    }
}

@available(iOS 14.0, *)
@frozen
public struct TabLabel: Equatable {

    @frozen
    public enum Role: Equatable {
        case search

        @available(iOS 27.0, *)
        case prominent
    }

    @usableFromInline
    struct Badge: Equatable {
        var value: Text
        var color: Color?
    }

    var role: Role?
    var badge: Badge?
    var selectedImage: Image?
    var label: LabelElement

    public init(
        role: Role? = nil,
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.role = role
        self.label = label()
    }

    public func badge(_ value: Text?, color: Color? = nil) -> Self {
        var copy = self
        copy.badge = value.map { Badge(value: $0, color: color) }
        return copy
    }

    public func selectedImage(_ image: Image?) -> Self {
        var copy = self
        copy.selectedImage = image
        return copy
    }

    public struct Key: TraitValueKey {
        public static var defaultValue: TabLabel? { nil }
    }
}

@available(iOS 14.0, *)
extension View {

    public func tabBarTabLabel(
        label: () -> TabLabel
    ) -> some View {
        trait(TabLabel.Key.self, label())
    }

    public func tabBarTabLabel(
        @LabelElementBuilder label: () -> LabelElement
    ) -> some View {
        trait(TabLabel.Key.self, TabLabel(label: label))
    }
}

@available(iOS 14.0, *)
public struct TabContainer<
    Selection: Hashable,
    Content: View,
    Controller: TabContainerController<Selection>
>: View {

    var transition: TabTransition
    @StateOrBinding var selection: Selection
    var content: Content

    public init(
        _ as: Controller.Type,
        transition: TabTransition = .default,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self._selection = .init(selection)
        self.content = content()
    }

    public init(
        transition: TabTransition = .default,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) where Controller == TabContainerController<Selection> {
        self.init(
            TabContainerController<Selection>.self,
            transition: transition,
            selection: selection,
            content: content
        )
    }

    public init(
        _ as: Controller.Type,
        transition: TabTransition = .default,
        @ViewBuilder content: () -> Content
    ) where Selection == Int {
        self.transition = transition
        self._selection = .init(0)
        self.content = content()
    }

    public init(
        transition: TabTransition = .default,
        @ViewBuilder content: () -> Content
    ) where Selection == Int, Controller == TabContainerController<Selection> {
        self.init(
            TabContainerController<Selection>.self,
            transition: transition,
            content: content
        )
    }

    public var body: some View {
        VariadicViewAdapter {
            content
        } content: { content in
            ControllerContainer(
                ContainerBody(
                    transition: transition,
                    selection: $selection,
                    content: content
                )
            )
        }
    }

    private struct ContainerBody: ControllerContainerRepresentable {
        var transition: TabTransition
        var selection: Binding<Selection>
        var content: VariadicView

        func makeBody(configuration: Configuration) -> some View {
            TabContainerAdapter<Selection, Controller>(
                configuration: configuration,
                transition: transition,
                selection: selection,
                content: content
            )
        }
    }
}

@available(iOS 14.0, *)
private struct TabContainerAdapter<
    Selection: Hashable,
    Controller: TabContainerController<Selection>
>: UIViewControllerRepresentable {

    var configuration: ControllerContainerConfiguration
    var transition: TabTransition
    var selection: Binding<Selection>
    var content: VariadicView

    typealias UIViewControllerType = Controller

    func makeUIViewController(
        context: Context
    ) -> UIViewControllerType {
        let controller = UIViewControllerType(
            selection: selection
        )
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        uiViewController.selection = selection
        uiViewController.transition = transition
        uiViewController.update(
            content,
            configuration: configuration,
            environment: context.environment,
            transaction: context.transaction
        )
    }
}

@available(iOS 14.0, *)
open class TabContainerController<
    Selection: Hashable
>: UITabBarController, UITabBarControllerDelegate {

    public var selection: Binding<Selection>

    public var transition: TabTransition = .default

    private var safeAreaInsets: UIEdgeInsets? {
        didSet {
            guard oldValue != safeAreaInsets else { return }
            updateAdditionalSafeAreaInsets()
        }
    }

    public let tabViewControllers = VariadicViewHostingControllersAdapter(id: Selection.self)

    private var context = TabTransitionRepresentableContext(
        environment: EnvironmentValues(),
        transaction: Transaction()
    )

    public required init(
        selection: Binding<Selection>
    ) {
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 18.0, *) {
            mode = .tabBar
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = nil
    }

    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateAdditionalSafeAreaInsets()
    }

    private func updateAdditionalSafeAreaInsets() {
        let additionalSafeAreaInsets = additionalSafeAreaInsets(
            safeAreaInsets: safeAreaInsets
        )
        if self.additionalSafeAreaInsets != additionalSafeAreaInsets {
            self.additionalSafeAreaInsets = additionalSafeAreaInsets
        }
    }

    open func update(
        _ content: VariadicView,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        let didUpdate = tabViewControllers.updateViewControllers(
            content: content,
            transaction: transaction
        ) { index, viewController, child in
            if let tabLabel = child[TabLabel.Key.self] {
                let tabBarItem = makeUIBarButtonItem(
                    for: tabLabel,
                    index: index,
                    environment: environment
                )
                viewController.tabBarItem = tabBarItem
            } else {
                viewController.tabBarItem = UITabBarItem(title: nil, image: nil, tag: index)
            }

        }
        let selection = tabViewControllers.index(for: selection.wrappedValue)
        if didUpdate {
            setViewControllers(
                tabViewControllers.viewControllers,
                animated: transaction.isAnimated
            )
        }

        if let selection, selection != selectedIndex {
            if let duration = transaction.animation?.duration(defaultDuration: 0.35) {
                UIView.transition(with: tabBar, duration: duration, options: [.transitionCrossDissolve]) {
                    self.selectedIndex = selection
                }
            } else {
                selectedIndex = selection
            }
        }
    }

    fileprivate func update(
        _ content: VariadicView,
        configuration: ControllerContainerConfiguration,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        safeAreaInsets = configuration.safeAreaInsets.toUIEdgeInsets(layoutDirection: environment.layoutDirection)
        context = TabTransitionRepresentableContext(
            environment: environment,
            transaction: transaction
        )
        update(content, environment: environment, transaction: transaction)
        context.transaction = Transaction()
    }

    open func makeUIBarButtonItem(
        for tabLabel: TabLabel,
        index: Int,
        environment: EnvironmentValues
    ) -> UITabBarItem {
        let title = tabLabel.label.title?.resolve(in: environment)
        let image = tabLabel.label.image?.toUIImage(in: environment)
        let tabBarItem: UITabBarItem = {
            switch tabLabel.role {
            case .search, .prominent:
                let item = UITabBarItem(
                    tabBarSystemItem: .search,
                    tag: index
                )
                item.title = title
                item.image = image
                return item
            default:
                let item = UITabBarItem(
                    title: title,
                    image: image,
                    tag: index
                )
                return item
            }
        }()
        tabBarItem.selectedImage = tabLabel.selectedImage?.toUIImage(in: environment)
        tabBarItem.badgeValue = tabLabel.badge?.value.resolve(in: environment)
        tabBarItem.badgeColor = tabLabel.badge?.color?.toUIColor(in: environment)
        return tabBarItem
    }

    // MARK: - UITabBarControllerDelegate

    open func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        if tabBarController.selectedViewController == viewController {
            if let navigationController = viewController._firstDescendent(ofType: UINavigationController.self) {
                if let transitionCoordinator = navigationController.transitionCoordinator,
                    transitionCoordinator.isInteractive
                {
                    transitionCoordinator.animate(
                        alongsideTransition: nil
                    ) { [weak navigationController] _ in
                        navigationController?.popToRootViewController(animated: true)
                    }
                } else if navigationController.viewControllers.count > 1 {
                    navigationController.popToRootViewController(animated: true)
                } else if let scrollView = navigationController.topViewController?._contentScrollView {
                    let offset = CGPoint(
                        x: scrollView.contentOffset.x,
                        y: -scrollView.adjustedContentInset.top
                    )
                    scrollView.setContentOffset(offset, animated: true)
                }
            }
            return false
        }
        context.transaction.animation = .default
        return true
    }

    open func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        if let id = tabViewControllers.id(for: viewController) {
            selection.wrappedValue = id
        }
    }

    open func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController,
    ) -> UIViewControllerAnimatedTransitioning? {
        switch transition.value {
        case .default:
            return nil
        case .representable(let transition):
            assert(!swift_getIsClassType(transition), "TabTransitionRepresentable must be value types (either a struct or an enum); it was a class")
            return transition.tabBarController(
                tabBarController,
                animationControllerForTransitionFrom: fromVC,
                to: toVC,
                context: context
            )
        }
    }

    open func tabBarController(
        _ tabBarController: UITabBarController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        switch transition.value {
        case .default:
            return nil
        case .representable(let transition):
            assert(!swift_getIsClassType(transition), "TabTransitionRepresentable must be value types (either a struct or an enum); it was a class")
            return transition.tabBarController(
                tabBarController,
                interactionControllerFor: animationController,
                context: context
            )
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct TabContainer_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PreviewWithTag()
        }

        ZStack {
            PreviewWithForEach()
        }
    }

    struct PreviewWithTag: View {
        @State var selection = 0

        var body: some View {
            TabContainer(
                selection: $selection
            ) {
                Color.red
                    .ignoresSafeArea()
                    .tag(0)
                    .tabBarTabLabel {
                        Label("Tab 0", systemImage: selection == 0 ? "circle.fill" : "circle")
                    }
                Color.blue
                    .ignoresSafeArea()
                    .tag(1)
                    .tabBarTabLabel {
                        TabLabel {
                            Label("Tab 1", systemImage: selection == 1 ? "circle.fill" : "circle")
                        }
                        .badge(Text(1, format: .number), color: .black)
                        .selectedImage(Image(systemName: "circle.fill"))
                    }

                Color.yellow
                    .ignoresSafeArea()
                    .tag(2)
                    .tabBarTabLabel {
                        TabLabel(role: .search) {
                            Label("Tab 2", systemImage: selection == 2 ? "circle.fill" : "circle")
                        }
                    }
            }
        }
    }

    struct PreviewWithForEach: View {
        @State var selection = 0

        var body: some View {
            TabContainer(
                selection: $selection
            ) {
                ForEach(0...2, id: \.self) { id in
                    Text("\(id)")
                }
            }
        }
    }
}

#endif
