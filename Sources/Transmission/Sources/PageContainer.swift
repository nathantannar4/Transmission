//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
@frozen
public struct PageTransition {

    @usableFromInline
    enum Value: Hashable {
        case scroll(Axis, CGFloat)
        case pageCurl(Axis, CGFloat)
    }

    var value: Value
    var isInteractive: Bool

    public func isInteractive(_ isInteractive: Bool) -> PageTransition {
        var copy = self
        copy.isInteractive = isInteractive
        return copy
    }

    public static var scroll: PageTransition {
        .scroll(axis: .horizontal)
    }

    public static func scroll(
        axis: Axis,
        spacing: CGFloat = 0,
        isInteractive: Bool = true
    ) -> PageTransition {
        PageTransition(
            value: .scroll(axis, spacing),
            isInteractive: isInteractive
        )
    }

    public static var pageCurl: PageTransition {
        .pageCurl(axis: .horizontal)
    }

    public static func pageCurl(
        axis: Axis,
        spacing: CGFloat = 0,
        isInteractive: Bool = true
    ) -> PageTransition {
        PageTransition(
            value: .pageCurl(axis, spacing),
            isInteractive: isInteractive
        )
    }
}

@available(iOS 14.0, *)
public protocol PageControlStyle: DynamicProperty {

    associatedtype Selection: Hashable
    associatedtype Body: View

    @ViewBuilder @MainActor @preconcurrency func makeBody(configuration: Configuration) -> Body

    typealias Configuration = PageControlConfiguration<Selection>
}

@available(iOS 14.0, *)
public struct PageControlConfiguration<Selection: Hashable> {
    @Binding public var selection: Selection
    public var pages: [Selection]
}

@available(iOS 14.0, *)
extension PageControlStyle {

    public static func system<
        Selection: Hashable
    >(
        showsPageControl: Bool = true,
        selectedTintColor: Color? = nil,
        unselectedTintColor: Color? = nil,
        hidesForSinglePage: Bool = false
    ) -> Self where Self == PageControlSystemStyle<Selection> {
        PageControlSystemStyle(
            showsPageControl: showsPageControl,
            selectedTintColor: selectedTintColor,
            unselectedTintColor: unselectedTintColor,
            hidesForSinglePage: hidesForSinglePage
        )
    }
}

@available(iOS 14.0, *)
public struct PageControlSystemStyle<
    Selection: Hashable
>: PageControlStyle {

    public typealias Selection = Selection
    public var showsPageControl: Bool
    public var selectedTintColor: Color?
    public var unselectedTintColor: Color?
    public var hidesForSinglePage: Bool

    public init(
        showsPageControl: Bool,
        selectedTintColor: Color? = nil,
        unselectedTintColor: Color? = nil,
        hidesForSinglePage: Bool = false
    ) {
        self.showsPageControl = showsPageControl
        self.selectedTintColor = selectedTintColor
        self.unselectedTintColor = unselectedTintColor
        self.hidesForSinglePage = hidesForSinglePage
    }

    public func makeBody(configuration: Configuration) -> some View {
        if showsPageControl {
            SystemPageControl(
                selection: configuration.$selection,
                pages: configuration.pages,
                selectedTintColor: selectedTintColor,
                unselectedTintColor: unselectedTintColor,
                hidesForSinglePage: hidesForSinglePage
            )
        }
    }
}

@available(iOS 14.0, *)
public struct PageContainer<
    Selection: Hashable,
    Content: View,
    Style: PageControlStyle,
    Controller: PageContainerController<Selection>
>: View where Style.Selection == Selection {

    var transition: PageTransition
    var alignment: Alignment
    var style: Style
    @StateOrBinding var selection: Selection
    var transitionProgress: Binding<CGFloat>? = nil
    var content: Content

    public init(
        _ as: Controller.Type,
        transition: PageTransition = .scroll,
        alignment: Alignment = .bottom,
        style: Style,
        selection: Binding<Selection>,
        transitionProgress: Binding<CGFloat>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self.alignment = alignment
        self.style = style
        self._selection = .init(selection)
        self.transitionProgress = transitionProgress
        self.content = content()
    }

    public init(
        transition: PageTransition = .scroll,
        alignment: Alignment = .bottom,
        style: Style,
        selection: Binding<Selection>,
        transitionProgress: Binding<CGFloat>? = nil,
        @ViewBuilder content: () -> Content
    ) where Controller == PageContainerController<Selection> {
        self.init(
            PageContainerController<Selection>.self,
            transition: transition,
            alignment: alignment,
            style: style,
            selection: selection,
            transitionProgress: transitionProgress,
            content: content
        )
    }

    public init(
        _ as: Controller.Type,
        transition: PageTransition = .scroll,
        alignment: Alignment = .bottom,
        selection: Binding<Selection>,
        transitionProgress: Binding<CGFloat>? = nil,
        @ViewBuilder content: () -> Content
    ) where Style == PageControlSystemStyle<Selection> {
        self.init(
            Controller.self,
            transition: transition,
            alignment: alignment,
            style: PageControlSystemStyle(showsPageControl: false),
            selection: selection,
            transitionProgress: transitionProgress,
            content: content
        )
    }

    public init(
        transition: PageTransition = .scroll,
        alignment: Alignment = .bottom,
        style: Style,
        selection: Binding<Selection>,
        transitionProgress: Binding<CGFloat>? = nil,
        @ViewBuilder content: () -> Content
    ) where Style == PageControlSystemStyle<Selection>, Controller == PageContainerController<Selection> {
        self.init(
            PageContainerController<Selection>.self,
            transition: transition,
            alignment: alignment,
            selection: selection,
            transitionProgress: transitionProgress,
            content: content
        )
    }

    public init(
        _ as: Controller.Type,
        transition: PageTransition = .scroll,
        alignment: Alignment = .bottom,
        style: Style = PageControlSystemStyle<Selection>(showsPageControl: false),
        transitionProgress: Binding<CGFloat>? = nil,
        @ViewBuilder content: () -> Content
    ) where Selection == Int {
        self.transition = transition
        self.alignment = alignment
        self.style = style
        self._selection = .init(0)
        self.transitionProgress = transitionProgress
        self.content = content()
    }

    public init(
        transition: PageTransition = .scroll,
        alignment: Alignment = .bottom,
        style: Style = PageControlSystemStyle<Selection>(showsPageControl: false),
        transitionProgress: Binding<CGFloat>? = nil,
        @ViewBuilder content: () -> Content
    ) where Selection == Int, Controller == PageContainerController<Int> {
        self.init(
            PageContainerController<Int>.self,
            transition: transition,
            alignment: alignment,
            style: style,
            transitionProgress: transitionProgress,
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
                    style: style,
                    selection: $selection,
                    transitionProgress: transitionProgress,
                    content: content
                )
            )
            .id(transition.value)
            .overlay(
                ViewAdapter {
                    let pages = content.compactMap { $0.selection(as: Selection.self) }
                    let configuration = PageControlConfiguration(
                        selection: $selection,
                        pages: pages
                    )
                    style.makeBody(
                        configuration: configuration
                    )
                },
                alignment: alignment
            )
        }
    }

    private struct ContainerBody: ControllerContainerRepresentable {
        var transition: PageTransition
        var style: Style
        var selection: Binding<Selection>
        var transitionProgress: Binding<CGFloat>?
        var content: VariadicView

        func makeBody(configuration: Configuration) -> some View {
            PageContainerAdapter<Selection, Controller>(
                configuration: configuration,
                transition: transition,
                selection: selection,
                transitionProgress: transitionProgress,
                content: content
            )
        }
    }
}

@available(iOS 14.0, *)
private struct PageContainerAdapter<
    Selection: Hashable,
    Controller: PageContainerController<Selection>
>: UIViewControllerRepresentable {

    var configuration: ControllerContainerConfiguration
    var transition: PageTransition
    var selection: Binding<Selection>
    var transitionProgress: Binding<CGFloat>?
    var content: VariadicView

    typealias UIViewControllerType = Controller

    func makeUIViewController(
        context: Context
    ) -> UIViewControllerType {
        let uiViewController = UIViewControllerType(
            transition: transition,
            selection: selection
        )
        return uiViewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        uiViewController.selection = selection
        uiViewController.transitionProgress = transitionProgress
        uiViewController.isInteractive = transition.isInteractive
        uiViewController.update(
            content,
            configuration: configuration,
            environment: context.environment,
            transaction: context.transaction
        )
    }
}

@available(iOS 14.0, *)
private struct SystemPageControl<
    Selection: Hashable
>: UIViewRepresentable {

    @Binding var selection: Selection
    var pages: [Selection]
    var selectedTintColor: Color?
    var unselectedTintColor: Color?
    var hidesForSinglePage: Bool

    func makeUIView(
        context: Context
    ) -> UIPageControl {
        let uiView = UIPageControl()
        uiView.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged),
            for: .valueChanged
        )
        return uiView
    }

    func updateUIView(
        _ uiView: UIPageControl,
        context: Context
    ) {
        context.coordinator.selection = $selection
        context.coordinator.pages = pages
        uiView.currentPageIndicatorTintColor = selectedTintColor?.toUIColor(in: context.environment)
        uiView.pageIndicatorTintColor = unselectedTintColor?.toUIColor(in: context.environment)
        uiView.hidesForSinglePage = hidesForSinglePage
        uiView.currentPage = pages.firstIndex(of: selection) ?? 0
        uiView.numberOfPages = pages.count
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, pages: pages)
    }

    @MainActor
    class Coordinator: NSObject {
        var selection: Binding<Selection>
        var pages: [Selection]

        init(selection: Binding<Selection>, pages: [Selection]) {
            self.selection = selection
            self.pages = pages
        }

        @objc
        func valueChanged(_ sender: UIPageControl) {
            let newValue = pages[sender.currentPage]
            withAnimation {
                selection.wrappedValue = newValue
            }
        }
    }
}

@available(iOS 14.0, *)
open class PageContainerController<
    Selection: Hashable
>: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    public var selection: Binding<Selection>
    public var transitionProgress: Binding<CGFloat>?

    public var selectedIndex: Int? {
        guard
            let viewController = selectedViewController,
            let index = pageViewControllers.firstIndex(where: { $0 == viewController })
        else {
            return nil
        }
        return index
    }

    public var isInteractive: Bool {
        get {
            switch transitionStyle {
            case .scroll:
                return scrollView?.isScrollEnabled ?? false
            case .pageCurl:
                return (panGesture?.isEnabled ?? false) || (tapGesture?.isEnabled ?? false)
            default:
                return false
            }
        }
        set {
            switch transitionStyle {
            case .scroll:
                scrollView?.isScrollEnabled = newValue
            case .pageCurl:
                panGesture?.isEnabled = newValue
                tapGesture?.isEnabled = newValue
            default:
                break
            }
        }
    }

    private var safeAreaInsets: UIEdgeInsets? {
        didSet {
            guard oldValue != safeAreaInsets else { return }
            updateAdditionalSafeAreaInsets()
        }
    }

    public var selectedViewController: UIViewController? {
        viewControllers?.first
    }

    public let pageViewControllers = VariadicViewHostingControllersAdapter(id: Selection.self)

    private var isTransitioningFromIndex: Int?
    private var isTransitioningToIndex: Int?
    private var isTransitioningToDirection: UIPageViewController.NavigationDirection?
    private var isTransitioningViewControllers: Int = 0
    private var didCatchTransition = false

    private var scrollView: UIScrollView? {
        view.subviews.compactMap { $0 as? UIScrollView }.first
    }

    private var panGesture: UIPanGestureRecognizer? {
        view.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).first
    }

    private var tapGesture: UITapGestureRecognizer? {
        view.gestureRecognizers?.compactMap({ $0 as? UITapGestureRecognizer }).first
    }

    public required init(
        transition: PageTransition,
        selection: Binding<Selection>
    ) {
        self.selection = selection
        super.init(
            transitionStyle: {
                switch transition.value {
                case .scroll:
                    return .scroll
                case .pageCurl:
                    return .pageCurl
                }
            }(),
            navigationOrientation: {
                switch transition.value {
                case .scroll(let axis, _):
                    return axis == .vertical ? .vertical : .horizontal
                case .pageCurl(let axis, _):
                    return axis == .vertical ? .vertical : .horizontal
                }
            }(),
            options: [
                .interPageSpacing: {
                    switch transition.value {
                    case .scroll(_, let spacing):
                        return spacing
                    case .pageCurl(_, let spacing):
                        return spacing
                    }
                }()
            ]
        )
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        delegate = self
        dataSource = self

        switch transitionStyle {
        case .scroll:
            scrollView?.backgroundColor = nil
            scrollView?.delegate = self
            switch navigationOrientation {
            case .horizontal:
                scrollView?.alwaysBounceVertical = false
            case .vertical:
                scrollView?.alwaysBounceHorizontal = false
            default:
                break
            }
            scrollView?.isDirectionalLockEnabled = true
            scrollView?.prefersSkippedAsParent = true

        case .pageCurl:
            panGesture?.addTarget(self, action: #selector(didPan(_:)))
            tapGesture?.addTarget(self, action: #selector(didTap(_:)))

        default:
            break
        }
    }

    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateAdditionalSafeAreaInsets()
        if let navigationController, let interactivePopGestureRecognizer = navigationController.interactivePopGestureRecognizer {
            scrollView?.panGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
            panGesture?.require(toFail: interactivePopGestureRecognizer)
        }
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
        let oldSelection = pageViewControllers.index(for: selection.wrappedValue) ?? selectedIndex ?? 0
        let didUpdate = pageViewControllers.updateViewControllers(
            content: content,
            transaction: transaction
        )
        let selection = pageViewControllers.index(for: selection.wrappedValue) ?? max(0, min(oldSelection, pageViewControllers.count - 1))
        if didUpdate {
            view.isHidden = pageViewControllers.isEmpty
            if pageViewControllers.isEmpty {
                setViewControllers([UIViewController()], direction: .forward, animated: false)
            } else {
                displayViewController(
                    at: selection,
                    animated: transaction.isAnimated
                )
            }
        } else if selection != selectedIndex,
            selection != isTransitioningToIndex,
            scrollView?.isDragging != true
        {
            displayViewController(
                at: selection,
                animated: transaction.isAnimated
            )
        }
    }

    fileprivate func update(
        _ content: VariadicView,
        configuration: ControllerContainerConfiguration,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        safeAreaInsets = configuration.safeAreaInsets.toUIEdgeInsets(layoutDirection: environment.layoutDirection)
        update(content, environment: environment, transaction: transaction)
    }

    open func displayViewController(at index: Int, animated: Bool) {
        guard index >= 0, index < pageViewControllers.count else {
            return
        }
        let direction: UIPageViewController.NavigationDirection = index > (selectedIndex ?? -1) ? .forward : .reverse
        let didChangeDirections = isTransitioningToDirection != nil && isTransitioningToDirection != direction
        let viewController = pageViewControllers[index]
        if let scrollView, animated, selectedIndex != nil, didChangeDirections, isTransitioningViewControllers > 1 {
            // Force non-animated if in the middle of a transition, to avoid any NSInternalInconsistencyException crashes
            isTransitioningToDirection = nil
            isTransitioningViewControllers = 0
            setViewControllers([viewController], direction: direction, animated: false)
            scrollView.setContentOffset(scrollView.contentOffset, animated: animated)
            selectedPageDidChange()
        } else {
            isTransitioningToDirection = direction
            isTransitioningViewControllers += 1
            setViewControllers([viewController], direction: direction, animated: animated) { [weak self] success in
                guard let self, success else { return }
                isTransitioningToDirection = nil
                isTransitioningViewControllers = 0
                if animated {
                    updateSelection()
                } else {
                    withCATransaction { [weak self] in
                        self?.updateSelection()
                    }
                }
            }
        }
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    open func selectedPageDidChange() {
        let isBounceEnabled = pageViewControllers.count > 1
        scrollView?.bounces = isBounceEnabled
    }

    @objc
    private func didPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            if gesture.state == .began, let selectedIndex {
                isTransitioningFromIndex = selectedIndex
            }
            let isStarting = isTransitioningToIndex == nil
            if let isTransitioningFromIndex, isTransitioningToIndex == nil {
                let translation = gesture.translation(in: view)
                guard translation != .zero else { return }
                let isAdvancing = navigationOrientation == .horizontal ? translation.x < 0 : translation.y < 0
                isTransitioningToIndex = (isAdvancing ? 1 : -1) + isTransitioningFromIndex
            }
            guard
                let isTransitioningFromIndex,
                let isTransitioningToIndex,
                let transitionProgress
            else {
                return
            }
            let offset = gesture.location(in: view)
            let dimension = navigationOrientation == .horizontal ? view.bounds.width : view.bounds.height
            let delta = navigationOrientation == .horizontal ? offset.x : offset.y
            let isAdvancing = isTransitioningToIndex >= isTransitioningFromIndex
            let progress = (isAdvancing ? (dimension - delta) : -delta) / max(dimension, 1)
            var transaction = Transaction(animation: isStarting ? .default : nil)
            transaction.isContinuous = true
            withTransaction(transaction) {
                transitionProgress.wrappedValue = progress
            }
        case .ended, .cancelled, .failed:
            let transaction = Transaction(animation: .default)
            withTransaction(transaction) {
                if gesture.state == .ended {
                    updateSelection()
                }
                transitionProgress?.wrappedValue = 0
            }
            isTransitioningToIndex = nil
            isTransitioningFromIndex = nil
        default:
            break
        }
    }

    @objc
    private func didTap(_ gesture: UITapGestureRecognizer) {
        let transaction = Transaction(animation: .default)
        withTransaction(transaction) {
            updateSelection()
            transitionProgress?.wrappedValue = 0
        }
        isTransitioningFromIndex = nil
    }

    private func updateSelection() {
        if let index = selectedIndex,
           index != isTransitioningFromIndex,
           let newSelection = pageViewControllers.id(for: index),
           selection.wrappedValue != newSelection
        {
            selection.wrappedValue = newSelection
        }
        selectedPageDidChange()
    }

    // MARK: - UIPageViewControllerDataSource

    final public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        nextViewController(viewController, isAfter: true)
    }

    final public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        nextViewController(viewController, isAfter: false)
    }

    private func nextViewController(_ viewController: UIViewController, isAfter: Bool) -> UIViewController? {
        guard var index = pageViewControllers.firstIndex(where: { $0 == viewController }) else {
            return nil
        }
        index += isAfter ? 1 : -1
        guard index >= 0 && index < pageViewControllers.count else {
            return nil
        }
        return pageViewControllers[index]
    }

    // MARK: - UIPageViewControllerDelegate

    open func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]
    ) {
    }

    open func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        let didTransition = !completed || selectedIndex != isTransitioningFromIndex
        defer {
            if didTransition {
                isTransitioningFromIndex = nil
            }
        }
        isTransitioningToIndex = nil
        guard completed else { return }
        let transaction = Transaction(animation: nil)
        withTransaction(transaction) {
            updateSelection()
        }
        UIView.animate(withDuration: 0.15) {
            self.setNeedsStatusBarAppearanceUpdate()
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    // MARK: - UIScrollViewDelegate

    open func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        guard
            let transitionProgress,
            (scrollView.isTracking && isTransitioningFromIndex != nil) || (scrollView.isDragging && isTransitioningFromIndex == nil && !didCatchTransition)
        else {
            return
        }

        let offset = scrollView.contentOffset
        let size = scrollView.bounds.size
        let dimension = navigationOrientation == .horizontal ? size.width : size.height
        let delta = (navigationOrientation == .horizontal ? offset.x : offset.y) - dimension
        var progress = delta / max(dimension, 1)
        if traitCollection.layoutDirection == .rightToLeft {
            progress = -progress
        }
        if let isTransitioningFromIndex, let selectedIndex {
            if selectedIndex > isTransitioningFromIndex, progress > 0 {
                progress = -(1 - progress)
            } else if selectedIndex < isTransitioningFromIndex, progress < 0 {
                progress = (1 + progress)
            }
        }
        var transaction = Transaction(animation: transitionProgress.wrappedValue == 0 ? .default : nil)
        transaction.isContinuous = true
        withTransaction(transaction) {
            transitionProgress.wrappedValue = progress
        }
    }

    open func scrollViewWillBeginDragging(
        _ scrollView: UIScrollView
    ) {
        if isTransitioningFromIndex != nil {
            didCatchTransition = true
        }
    }

    open func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard let index = selectedIndex else { return }
        let size = scrollView.bounds.size
        let dimension = navigationOrientation == .horizontal ? size.width : size.height
        let delta = (navigationOrientation == .horizontal ? targetContentOffset.pointee.x : targetContentOffset.pointee.y) - dimension
        var progress = delta / max(dimension, 1)
        if traitCollection.layoutDirection == .rightToLeft {
            progress = -progress
        }
        let offset = Int(progress.rounded())
        let indexToTransitionTo = (isTransitioningFromIndex ?? index) + offset
        let isTransitioningPage = targetContentOffset.pointee.x != scrollView.bounds.width
        if index != indexToTransitionTo {
            if indexToTransitionTo >= 0,
                indexToTransitionTo < pageViewControllers.count,
                let newSelection = pageViewControllers.id(for: indexToTransitionTo)
            {
                isTransitioningFromIndex = index
                isTransitioningToIndex = indexToTransitionTo
                let transaction = Transaction(animation: .default)
                withTransaction(transaction) {
                    selection.wrappedValue = newSelection
                }
            }
        } else if !isTransitioningPage {
            if let isTransitioningFromIndex, let newSelection = pageViewControllers.id(for: isTransitioningFromIndex) {
                isTransitioningToIndex = isTransitioningFromIndex
                let transaction = Transaction(animation: .default)
                withTransaction(transaction) {
                    selection.wrappedValue = newSelection
                }
            }
            isTransitioningFromIndex = nil
        }
    }

    open func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        if !decelerate {
            didCatchTransition = false
        }

        guard let transitionProgress else { return }
        let transaction = Transaction(animation: .default)
        withTransaction(transaction) {
            transitionProgress.wrappedValue = 0
        }
    }

    open func scrollViewDidEndDecelerating(
        _ scrollView: UIScrollView
    ) {
        didCatchTransition = false
    }
}

extension UIScrollView {

    private static var prefersSkippedAsParentKey: Bool = false

    var prefersSkippedAsParent: Bool {
        get {
            if #unavailable(iOS 26.0), let box = objc_getAssociatedObject(self, &Self.prefersSkippedAsParentKey) as? ObjCBox<Bool> {
                return box.value
            }
            return false
        }
        set {
            if #unavailable(iOS 26.0), newValue, !Self.prefersSkippedAsParentKey {
                Self.prefersSkippedAsParentKey = true

                guard
                    // _parentScrollView
                    let aSelector = NSSelectorFromBase64EncodedString("X3BhcmVudFNjcm9sbFZpZXc=")
                else {
                    return
                }
                swizzle(
                    target: UIScrollView.self,
                    source: UIScrollView.self,
                    aSelector: aSelector,
                    aSwizzledSelector: #selector(swizzled_parentScrollView)
                )
            }
            let box = ObjCBox(value: newValue)
            objc_setAssociatedObject(self, &Self.prefersSkippedAsParentKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc
    private func swizzled_parentScrollView() -> UIScrollView? {
        guard let parent = self.swizzled_parentScrollView() else { return nil }
        if parent.prefersSkippedAsParent {
            if (contentScrollsAlongYAxis && !parent.contentScrollsAlongYAxis) || (contentScrollsAlongXAxis && !parent.contentScrollsAlongXAxis) {
                return parent.swizzled_parentScrollView()
            }
        }
        return parent
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct PageContainer_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PreviewA()
        }
        ZStack {
            PreviewB()
        }
    }

    struct PreviewA: View {
        @State var isInteractive = true
        @State var selection = 0
        @State var transitionProgress: CGFloat = 0
        @State var tabs = 7
        @Namespace var namespace

        struct PageViews: View {
            var tabs: Int

            var body: some View {
                if tabs >= 1 {
                    Color.blue
                        .overlay(Text(1.description))
                        .tag(1)
                }

                if tabs >= 2 {
                    Color.yellow
                        .ignoresSafeArea()
                        .overlay(Text(2.description))
                        .tag(2)
                }

                if tabs >= 3 {
                    Color.red
                        .overlay(Text(3.description))
                        .tag(3)
                }

                if tabs >= 4 {
                    Color.green
                        .overlay(Text(4.description))
                        .tag(4)
                }

                if tabs >= 5 {
                    Color.purple
                        .overlay(Text(5.description))
                        .id(5)
                }

                if tabs >= 6 {
                    ForEach(6...tabs) { index in
                        Color.orange
                            .overlay(Text(index.description))
                    }
                }
            }
        }

        var body: some View {
            VStack(spacing: 0) {
                VStack {
                    Text(selection.description)

                    Text(transitionProgress.description)

                    Toggle(isOn: $isInteractive) {
                        Text("isInteractive")
                    }

                    Stepper(value: $tabs, step: 1) {
                        Text("tabs \(tabs)")
                    }
                }

                if tabs >= 1 {
                    HStack {
                        ForEach(1...tabs, id: \.self) { tag in
                            Button {
                                withAnimation {
                                    selection = tag
                                }
                            } label: {
                                Text("\(tag)")
                                    .padding(.horizontal)
                                    .padding(.bottom, 3)
                                    .background(alignment: .bottom) {
                                        if selection == tag {
                                            Capsule()
                                                .frame(height: 3)
                                                .matchedGeometryEffect(id: "bar", in: namespace)
                                                .modifier(
                                                    OffsetEffect(
                                                        transitionProgress: transitionProgress
                                                    )
                                                )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                PageContainer(
                    transition: .pageCurl(
                        axis: .horizontal,
                        spacing: 10,
                        isInteractive: isInteractive
                    ),
                    style: .system(
                        showsPageControl: isInteractive,
                        selectedTintColor: .white,
                        unselectedTintColor: .black,
                    ),
                    selection: $selection,
                    transitionProgress: $transitionProgress
                ) {
                    PageViews(tabs: tabs)
                }
                .frame(height: 200)

                PageContainer(
                    transition: .scroll(
                        axis: .horizontal,
                        spacing: 10,
                        isInteractive: isInteractive
                    ),
                    alignment: .top,
                    style: .system(
                        showsPageControl: isInteractive,
                        selectedTintColor: .white,
                        unselectedTintColor: .black,
                    ),
                    selection: $selection,
                    transitionProgress: $transitionProgress
                ) {
                    PageViews(tabs: tabs)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .safeAreaInsets(.bottom, 100)
            }
        }
    }

    struct OffsetEffect: GeometryEffect, Animatable {
        var transitionProgress: CGFloat

        var animatableData: CGFloat {
            get { transitionProgress }
            set { transitionProgress = newValue }
        }

        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(
                CGAffineTransform(
                    translationX: transitionProgress * size.width,
                    y: 0
                )
            )
        }
    }

    struct PreviewB: View {
        class Controller<Selection: Hashable>: PageContainerController<Selection> {
            override func viewDidLoad() {
                super.viewDidLoad()
                view.backgroundColor = .red
            }
        }

        var body: some View {
            PageContainer(Controller.self, style: .system()) {
                Text("Hello, World")
            }
        }
    }
}

#endif
