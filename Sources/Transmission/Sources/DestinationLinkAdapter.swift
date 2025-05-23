//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore

/// A view that manages the push a destination view in a new `UIViewController`.  The presentation is
/// sourced from this view.
///
/// To present the destination view with an animation, `isPresented` should
/// be updated with a transaction that has an animation. For example:
///
/// ```
/// withAnimation {
///     isPresented = true
/// }
/// ```
///
/// See Also:
///  - ``DestinationLink``
///  - ``DestinationLinkTransition``
///  - ``DestinationSourceViewLink``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with the ``DestinationLinkTransition/custom(_:)``
///  transition.
///
@frozen
@available(iOS 14.0, *)
public struct DestinationLinkAdapter<
    Content: View,
    Destination: View
>: View {

    var transition: DestinationLinkTransition
    var isPresented: Binding<Bool>
    var content: Content
    var destination: Destination

    public init(
        transition: DestinationLinkTransition,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) where Content == EmptyView {
        self.init(transition: transition, isPresented: isPresented, destination: destination, content: { EmptyView() })
    }

    public init(
        transition: DestinationLinkTransition,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self.isPresented = isPresented
        self.content = content()
        self.destination = destination()
    }

    public var body: some View {
        DestinationLinkAdapterBody(
            transition: transition,
            isPresented: isPresented,
            destination: destination,
            sourceView: content
        )
    }
}

@available(iOS 14.0, *)
private struct DestinationLinkAdapterBody<
    Destination: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: DestinationLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination
    var sourceView: SourceView

    @WeakState var presentingViewController: UIViewController?

    typealias UIViewType = TransitionSourceView<SourceView>
    typealias DestinationViewController = DestinationHostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    func makeUIView(context: Context) -> UIViewType {
        let uiView = TransitionSourceView(
            onDidMoveToWindow: { viewController in
                withCATransaction {
                    presentingViewController = viewController
                }
            },
            content: sourceView
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.hostingView?.content = sourceView

        if let presentingViewController = presentingViewController, isPresented.wrappedValue {

            context.coordinator.isPresented = isPresented

            let isAnimated = context.transaction.isAnimated || (presentingViewController.transitionCoordinator?.isAnimated ?? false)
            let animation = context.transaction.animation
                ?? (isAnimated ? .default : nil)
            context.coordinator.animation = animation

            if let adapter = context.coordinator.adapter {
                adapter.update(
                    destination: destination,
                    context: context,
                    isPresented: isPresented
                )
            } else if let navigationController = presentingViewController.navigationController {

                let adapter = DestinationLinkDestinationViewControllerAdapter(
                    destination: destination,
                    transition: transition.value,
                    context: context,
                    isPresented: isPresented,
                    onPop: { [weak coordinator = context.coordinator] in
                        coordinator?.onPop($0, transaction: $1)
                    }
                )
                context.coordinator.adapter = adapter
                switch adapter.transition {
                case .`default`:
                    break

                case .zoom:
                    if #available(iOS 18.0, *) {
                        let zoomOptions = UIViewController.Transition.ZoomOptions()
                        zoomOptions.interactiveDismissShouldBegin = { [weak adapter] context in
                            adapter?.transition.options.isInteractive ?? true
                        }
                        adapter.viewController.preferredTransition = .zoom(options: zoomOptions, sourceViewProvider: { [weak uiView] _ in
                            return uiView
                        })
                    }

                case .representable(_, let transition):
                    assert(!swift_getIsClassType(transition), "DestinationLinkCustomTransition must be value types (either a struct or an enum); it was a class")
                    context.coordinator.sourceView = uiView
                }

                navigationController.delegates.add(delegate: context.coordinator, for: adapter.viewController)
                context.coordinator.isPushing = true
                navigationController.pushViewController(adapter.viewController, animated: isAnimated) {
                    context.coordinator.animation = nil
                    context.coordinator.didPresentAnimated = isAnimated
                    context.coordinator.isPushing = false
                }
            }
        } else if let adapter = context.coordinator.adapter,
                  !isPresented.wrappedValue
        {
            let viewController = adapter.viewController!
            let isAnimated = context.transaction.isAnimated
                || viewController.transitionCoordinator?.isAnimated == true
            if let presented = viewController.presentedViewController {
                presented.dismiss(animated: isAnimated) {
                    viewController._popViewController(animated: isAnimated)
                }
            } else {
                viewController._popViewController(animated: isAnimated)
            }
            context.coordinator.adapter = nil
        }
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize).toCoreGraphics())
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }

    final class Coordinator: NSObject,
                             UINavigationControllerDelegate
    {
        var isPresented: Binding<Bool>
        var adapter: DestinationLinkDestinationViewControllerAdapter<Destination, SourceView>?
        var animation: Animation?
        var didPresentAnimated = false
        var isPushing = false
        weak var sourceView: UIView?

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        private func makeContext(
            options: DestinationLinkTransition.Options
        ) -> DestinationLinkTransitionRepresentableContext {
            DestinationLinkTransitionRepresentableContext(
                sourceView: sourceView,
                options: options,
                environment: adapter?.environment ?? .init(),
                transaction: Transaction(animation: animation ?? (didPresentAnimated ? .default : nil))
            )
        }

        func onPop(_ count: Int, transaction: Transaction) {
            guard let viewController = adapter?.viewController else { return }
            animation = transaction.animation
            didPresentAnimated = false
            viewController._popViewController(count: count, animated: transaction.isAnimated) {
                withTransaction(transaction) {
                    self.isPresented.wrappedValue = false
                }
            }
        }

        // MARK: - UINavigationControllerDelegate

        func navigationController(
            _ navigationController: UINavigationController,
            didShow viewController: UIViewController,
            animated: Bool
        ) {
            if let viewController = adapter?.viewController,
               !navigationController.viewControllers.contains(viewController),
               !isPushing,
               isPresented.wrappedValue
            {
                // Break the retain cycle
                adapter?.coordinator = nil

                withCATransaction {
                    var transaction = Transaction(animation: animated ? .default : nil)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        self.isPresented.wrappedValue = false
                    }
                }
            }
        }

        func navigationController(
            _ navigationController: UINavigationController,
            interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
            switch adapter?.transition {

            case .representable(let options, let transition):
                return transition.navigationController(
                    navigationController,
                    interactionControllerFor: animationController,
                    context: makeContext(options: options)
                )

            default:
                return nil
            }
        }

        func navigationController(
            _ navigationController: UINavigationController,
            animationControllerFor operation: UINavigationController.Operation,
            from fromVC: UIViewController,
            to toVC: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            switch adapter?.transition {

            case .representable(let options, let transition):
                return transition.navigationController(
                    navigationController,
                    animationControllerFor: operation,
                    from: fromVC,
                    to: toVC,
                    context: makeContext(options: options)
                )

            default:
                return nil
            }
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        if let adapter = coordinator.adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                withCATransaction {
                    adapter.viewController._popViewController(animated: coordinator.didPresentAnimated)
                }
                coordinator.adapter = nil
            } else {
                adapter.coordinator = coordinator
            }
        }
    }
}

final class DestinationLinkDelegateProxy: NSObject, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    private weak var navigationController: UINavigationController?
    private weak var delegate: UINavigationControllerDelegate?
    private var delegates = [ObjectIdentifier: ObjCWeakBox<UINavigationControllerDelegate>]()

    private var topDelegate: ObjectIdentifier?
    private var animationController: UIViewControllerAnimatedTransitioning?
    private var interactionController: UIViewControllerInteractiveTransitioning?
    private weak var popGestureDelegate: UIGestureRecognizerDelegate?

    init(for navigationController: UINavigationController) {
        super.init()
        self.delegate = navigationController.delegate
        self.navigationController = navigationController
        popGestureDelegate = navigationController.interactivePopGestureRecognizer?.delegate
        navigationController.delegate = self
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }

    func add(
        delegate: UINavigationControllerDelegate,
        for viewController: UIViewController
    ) {
        delegates[ObjectIdentifier(viewController)] = ObjCWeakBox(value: delegate)
    }

    private func resetState() {
        topDelegate = nil
        animationController = nil
        interactionController = nil
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        let shouldRequireFailureOf = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldRequireFailureOf: otherGestureRecognizer
        )
        return shouldRequireFailureOf ?? false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        let shouldRecognizeSimultaneouslyWith = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldRecognizeSimultaneouslyWith: otherGestureRecognizer
        )
        return shouldRecognizeSimultaneouslyWith ?? false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        let shouldBeRequiredToFailBy = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldBeRequiredToFailBy: otherGestureRecognizer
        )
        return shouldBeRequiredToFailBy ?? true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let canBegin = popGestureDelegate?.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
        guard
            canBegin,
            let navigationController = navigationController,
            navigationController.transitionCoordinator == nil,
            navigationController.viewControllers.count > 1
        else {
            return false
        }

        guard let animationController = self.navigationController(
            navigationController,
            animationControllerFor: .pop,
            from: navigationController.viewControllers[navigationController.viewControllers.count - 1],
            to: navigationController.viewControllers[navigationController.viewControllers.count - 2]
        ) else {
            return true
        }
        self.topDelegate = ObjectIdentifier(navigationController.viewControllers[navigationController.viewControllers.count - 1])
        self.animationController = animationController

        guard let interactionController = self.navigationController(
            navigationController,
            interactionControllerFor: animationController
        ) else {
            return true
        }
        self.interactionController = interactionController

        if interactionController.wantsInteractiveStart == true {
            navigationController.popViewController(animated: true)
        }
        return false
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        resetState()
        delegate?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
        for delegate in delegates.compactMap(\.value.value) {
            delegate.navigationController?(
                navigationController,
                willShow: viewController,
                animated: animated
            )
        }
        // Bring up to date, so things like navigationTitle is ready during the push
        (viewController.view as? AnyHostingView)?.render()
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        delegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )
        for delegate in delegates.compactMap(\.value.value) {
            delegate.navigationController?(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {

        if let interactionController {
            return interactionController
        } else if let id = topDelegate, let delegate = delegates[id]?.value {
            let interactionController = delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            )
            if let interactionController {
                return interactionController
            }
        }
        return delegate?.navigationController?(
            navigationController,
            interactionControllerFor: animationController
        )
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        let id = ObjectIdentifier(operation == .push ? toVC : fromVC)
        if id == topDelegate, let animationController {
            return animationController
        }

        resetState()
        topDelegate = id

        if let delegate = delegates[id]?.value {
            let animationController = delegate.navigationController?(
                navigationController,
                animationControllerFor: operation,
                from: fromVC,
                to: toVC
            )
            if let animationController {
                return animationController
            }
        }
        return delegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
    }
}

extension UINavigationController {

    private static var navigationDelegateKey: Bool = false

    var delegates: DestinationLinkDelegateProxy {
        guard let obj = objc_getAssociatedObject(self, &Self.navigationDelegateKey) as? ObjCBox<NSObject> else {

            let proxy = DestinationLinkDelegateProxy(for: self)
            let box = ObjCBox<NSObject>(value: proxy)
            objc_setAssociatedObject(self, &Self.navigationDelegateKey, box, .OBJC_ASSOCIATION_RETAIN)
            return proxy
        }
        return obj.value as! DestinationLinkDelegateProxy
    }
}

@available(iOS 14.0, *)
private class DestinationLinkDestinationViewControllerAdapter<
    Destination: View,
    SourceView: View
> {
    var viewController: UIViewController!
    var context: Any!

    typealias DestinationController = DestinationHostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    var transition: DestinationLinkTransition.Value
    var environment: EnvironmentValues
    var isPresented: Binding<Bool>
    var conformance: ProtocolConformance<UIViewControllerRepresentableProtocolDescriptor>? = nil
    var onPop: (Int, Transaction) -> Void

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: DestinationLinkAdapterBody<Destination, SourceView>.Coordinator?

    init(
        destination: Destination,
        transition: DestinationLinkTransition.Value,
        context: DestinationLinkAdapterBody<Destination, SourceView>.Context,
        isPresented: Binding<Bool>,
        onPop: @escaping (Int, Transaction) -> Void
    ) {
        self.transition = transition
        self.environment = context.environment
        self.isPresented = isPresented
        self.onPop = onPop
        if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Destination.self) {
            self.conformance = conformance
            update(
                destination: destination,
                context: context,
                isPresented: isPresented
            )
        } else {
            let viewController = DestinationController(
                content: destination.modifier(
                    DestinationBridgeAdapter(
                        destinationCoordinator: DestinationCoordinator(
                            isPresented: isPresented.wrappedValue,
                            dismissBlock: { [weak self] in self?.pop($0, $1) }
                        )
                    )
                )
            )
            transition.update(viewController)
            self.viewController = viewController
        }
    }

    deinit {
        if let conformance = conformance {
            var visitor = Visitor(
                destination: nil,
                isPresented: .constant(false),
                context: nil,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
        }
    }

    func update(
        destination: Destination,
        context: DestinationLinkAdapterBody<Destination, SourceView>.Context,
        isPresented: Binding<Bool>
    ) {
        environment = context.environment
        self.isPresented = isPresented
        if let conformance = conformance {
            var visitor = Visitor(
                destination: destination,
                isPresented: isPresented,
                context: context,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
        } else {
            let viewController = viewController as! DestinationController
            viewController.content = destination.modifier(
                DestinationBridgeAdapter(
                    destinationCoordinator: DestinationCoordinator(
                        isPresented: isPresented.wrappedValue,
                        dismissBlock: { [weak self] in self?.pop($0, $1) }
                    )
                )
            )
            transition.update(viewController)
        }
    }

    func pop(_ count: Int, _ transaction: Transaction) {
        onPop(count, transaction)
    }

    private struct Context<Coordinator> {
        // Only `UIViewRepresentable` uses V4
        struct V4 {
            struct RepresentableContextValues {
                enum EnvironmentStorage {
                    case eager(EnvironmentValues)
                    case lazy(() -> EnvironmentValues)
                }
                var preferenceBridge: AnyObject?
                var transaction: Transaction
                var environmentStorage: EnvironmentStorage
            }

            var values: RepresentableContextValues
            var coordinator: Coordinator

            var environment: EnvironmentValues {
                get {
                    switch values.environmentStorage {
                    case .eager(let environment):
                        return environment
                    case .lazy(let block):
                        return block()
                    }
                }
                set {
                    values.environmentStorage = .eager(newValue)
                }
            }
        }

        struct V1 {
            var coordinator: Coordinator
            var transaction: Transaction
            var environment: EnvironmentValues
            var preferenceBridge: AnyObject?
        }
    }

    private struct Visitor: ViewVisitor {
        var destination: Destination?
        var isPresented: Binding<Bool>
        var context: DestinationLinkAdapterBody<Destination, SourceView>.Context?
        var adapter: DestinationLinkDestinationViewControllerAdapter<Destination, SourceView>

        mutating func visit<Content>(type: Content.Type) where Content: UIViewControllerRepresentable {
            guard
                let destination = destination.map({ unsafeBitCast($0, to: Content.self) }),
                let context = context
            else {
                if let context = adapter.context, let viewController = adapter.viewController as? Content.UIViewControllerType {
                    func project<T>(_ value: T) {
                        let coordinator = unsafeBitCast(value, to: Content.Context.self).coordinator
                        Content.dismantleUIViewController(viewController, coordinator: coordinator)
                    }
                    _openExistential(context, do: project)
                }
                return
            }
            if adapter.context == nil {
                let coordinator = destination.makeCoordinator()
                let preferenceBridge: AnyObject?
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<DestinationLinkAdapterBody<Destination, SourceView>.Coordinator>.V4.self
                    ).values.preferenceBridge
                } else {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<DestinationLinkAdapterBody<Destination, SourceView>.Coordinator>.V1.self
                    ).preferenceBridge
                }
                let context = Context<Content.Coordinator>.V1(
                    coordinator: coordinator,
                    transaction: context.transaction,
                    environment: context.environment,
                    preferenceBridge: preferenceBridge
                )
                adapter.context = unsafeBitCast(context, to: Content.Context.self)
            }
            func project<T>(_ value: T) -> Content.Context {
                let destinationCoordinator = DestinationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    dismissBlock: { [weak adapter] in
                        adapter?.pop($0, $1)
                    }
                )
                var ctx = unsafeBitCast(value, to: Context<Content.Coordinator>.V1.self)
                ctx.environment.destinationCoordinator = destinationCoordinator
                return unsafeBitCast(ctx, to: Content.Context.self)
            }
            let ctx = _openExistential(adapter.context!, do: project)
            if adapter.viewController == nil {
                adapter.viewController = destination.makeUIViewController(context: ctx)
            }
            let viewController = adapter.viewController as! Content.UIViewControllerType
            destination.updateUIViewController(viewController, context: ctx)
        }
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition.Value {

    func update<Content: View>(_ viewController: HostingController<Content>) {

        viewController.hidesBottomBarWhenPushed = options.hidesBottomBarWhenPushed
        if let preferredPresentationBackgroundUIColor = options.preferredPresentationBackgroundUIColor {
            viewController.view.backgroundColor = preferredPresentationBackgroundUIColor
        }
    }
}

#endif
