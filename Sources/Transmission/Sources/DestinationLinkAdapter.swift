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
                    sourceView: uiView,
                    context: context,
                    isPresented: isPresented
                )
            } else if let navigationController = presentingViewController.navigationController {

                let adapter = DestinationLinkDestinationViewControllerAdapter(
                    destination: destination,
                    sourceView: uiView,
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
                             DestinationLinkDelegate
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

        func navigationControllerShouldBeginInteractivePop(
            _ navigationController: UINavigationController
        ) -> Bool {
            return adapter?.transition.options.isInteractive ?? true
        }

        // MARK: - UINavigationControllerDelegate

        func navigationController(
            _ navigationController: UINavigationController,
            didShow viewController: UIViewController,
            animated: Bool
        ) {
            guard let viewController = adapter?.viewController else { return }
            if navigationController.viewControllers.contains(viewController) {
                viewController.fixSwiftUIHitTesting()
            } else if !isPushing, isPresented.wrappedValue {
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
            willShow viewController: UIViewController,
            animated: Bool
        ) {
            guard !isPushing, navigationController.interactivePopGestureRecognizer?.isInteracting == true else { return }
            sourceView?.alpha = 1
        }

        func navigationController(
            _ navigationController: UINavigationController,
            interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
            switch adapter?.transition {

            case .representable(let options, let transition):
                if isPushing {
                    return transition.navigationController(
                        navigationController,
                        interactionControllerForPush: animationController,
                        context: makeContext(options: options)
                    )

                } else {
                    return transition.navigationController(
                        navigationController,
                        interactionControllerForPop: animationController,
                        context: makeContext(options: options)
                    )
                }

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
                switch operation {
                case .push:
                    return transition.navigationController(
                        navigationController,
                        pushing: toVC,
                        from: fromVC,
                        context: makeContext(options: options)
                    )

                case .pop:
                    let animationController = transition.navigationController(
                        navigationController,
                        popping: fromVC,
                        to: toVC,
                        context: makeContext(options: options)
                    )
                    if let transition = animationController as? UIPercentDrivenInteractiveTransition, transition.wantsInteractiveStart {
                        transition.wantsInteractiveStart = options.isInteractive
                    }
                    return animationController

                default:
                    return nil
                }

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

@objc
protocol DestinationLinkDelegate: UINavigationControllerDelegate{

    func navigationControllerShouldBeginInteractivePop(
        _ navigationController: UINavigationController
    ) -> Bool
}

@available(iOS 14.0, *)
final class DestinationLinkDelegateProxy: NSObject,
    UINavigationControllerDelegate,
    UIGestureRecognizerDelegate
{

    private weak var navigationController: UINavigationController?
    private weak var delegate: UINavigationControllerDelegate?
    private var delegates = [ObjectIdentifier: ObjCWeakBox<DestinationLinkDelegate>]()

    var transitioningId: ObjectIdentifier?
    var transition: UIPercentDrivenInteractiveTransition?
    private weak var popGestureDelegate: UIGestureRecognizerDelegate?
    private var interactivePopGestureRecognizer: UIScreenEdgePanGestureRecognizer!

    private var wantsInteractiveTransition = false

    init(for navigationController: UINavigationController) {
        super.init()
        self.delegate = navigationController.delegate
        popGestureDelegate = navigationController.interactivePopGestureRecognizer?.delegate
        self.navigationController = navigationController
        navigationController.delegate = self
        navigationController.interactivePopGestureRecognizer?.delegate = self
        interactivePopGestureRecognizer = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(panGestureDidChange(_:))
        )
        interactivePopGestureRecognizer.delegate = self
        if let builtinGesture = navigationController.interactivePopGestureRecognizer as? UIScreenEdgePanGestureRecognizer {
            interactivePopGestureRecognizer.edges = builtinGesture.edges
        } else {
            interactivePopGestureRecognizer.edges = [.left]
        }
        navigationController.view.addGestureRecognizer(interactivePopGestureRecognizer)
    }

    func add(
        delegate: DestinationLinkDelegate,
        for viewController: UIViewController
    ) {
        delegates[ObjectIdentifier(viewController)] = ObjCWeakBox(value: delegate)
    }

    @objc
    private func panGestureDidChange(
        _ gestureRecognizer: UIScreenEdgePanGestureRecognizer
    ) {
        guard
            let view = gestureRecognizer.view,
            let navigationController,
            let transition
        else {
            gestureRecognizer.isEnabled = false
            gestureRecognizer.isEnabled = true
            return
        }
        let viewTranslation = gestureRecognizer.translation(in: view)
        let percentage = min(max(0, viewTranslation.x / view.bounds.width), 1)

        switch gestureRecognizer.state {
        case .began:
            navigationController.popViewController(animated: true)

        case .changed:
            transition.update(percentage)

        case .cancelled, .ended, .failed:
            // Dismiss if:
            // - Drag over 50% and not moving up
            // - Large enough down vector
            let velocity = gestureRecognizer.velocity(in: view)
            var shouldFinish = false
            if gestureRecognizer.state == .ended {
                if gestureRecognizer.edges.contains(.left), !shouldFinish {
                    shouldFinish = (percentage >= 0.5 && velocity.x > 0) || (percentage > 0 && velocity.x >= 1000)
                }
                if gestureRecognizer.edges.contains(.right), !shouldFinish {
                    shouldFinish = (percentage >= 0.5 && velocity.x < 0) || (percentage > 0 && velocity.x <= -1000)
                }
            }
            if shouldFinish {
                transition.finish()
            } else {
                if abs(velocity.x) <= 1000 {
                    transition.completionSpeed = percentage >= 0.5 ? 1 - percentage : percentage
                }
                transition.cancel()
            }
            self.transition = nil

        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard
            let navigationController = navigationController,
            navigationController.viewControllers.count > 1,
            let fromVC = navigationController.topViewController
        else {
            return false
        }

        guard
            let delegate = delegates[ObjectIdentifier(fromVC)]?.value,
            delegate.navigationControllerShouldBeginInteractivePop(navigationController)
        else {
            return false
        }

        if gestureRecognizer == interactivePopGestureRecognizer {
            wantsInteractiveTransition = true; defer { wantsInteractiveTransition = false }
            let animationController = self.navigationController(
                navigationController,
                animationControllerFor: .pop,
                from: fromVC,
                to: navigationController.viewControllers[navigationController.viewControllers.count - 2]
            )
            guard
                let interactiveTransition = animationController as? UIPercentDrivenInteractiveTransition,
                interactiveTransition.wantsInteractiveStart
            else {
                transitioningId = nil
                return false
            }
            transition = interactiveTransition
            return true
        } else {
            let canBegin = popGestureDelegate?.gestureRecognizerShouldBegin?(
                gestureRecognizer
            )
            return canBegin ?? true
        }
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
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        let shouldBeRequiredToFailBy = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldBeRequiredToFailBy: otherGestureRecognizer
        )
        return shouldBeRequiredToFailBy ?? false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        let shouldReceive = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldReceive: touch
        )
        return shouldReceive ?? true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive press: UIPress
    ) -> Bool {
        let shouldReceive = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldReceive: press
        )
        return shouldReceive ?? true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive event: UIEvent
    ) -> Bool {
        let shouldReceive = popGestureDelegate?.gestureRecognizer?(
            gestureRecognizer,
            shouldReceive: event
        )
        return shouldReceive ?? true
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
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
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        transitioningId = nil
        transition = nil
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

        guard let transitioningId else { return nil }
        let delegate = delegates[transitioningId]?.value
        let interactionController = delegate?.navigationController?(
            navigationController,
            interactionControllerFor: animationController
        )
        return interactionController
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        let id = ObjectIdentifier(operation == .push ? toVC : fromVC)
        if let transition, transitioningId == id {
            return transition as? UIViewControllerAnimatedTransitioning
        }

        let delegate = delegates[id]?.value
        let animationController = delegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
        if operation == .pop, !wantsInteractiveTransition, let transition = animationController as? UIPercentDrivenInteractiveTransition {
            transition.wantsInteractiveStart = false
        }
        transitioningId = animationController != nil ? id : nil
        return animationController
    }
}

@available(iOS 14.0, *)
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
        sourceView: UIView,
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
                sourceView: sourceView,
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
            transition.update(
                viewController,
                context: DestinationLinkTransitionRepresentableContext(
                    sourceView: sourceView,
                    options: transition.options,
                    environment: context.environment,
                    transaction: context.transaction
                )
            )
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
        sourceView: UIView,
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
            transition.update(
                viewController,
                context: DestinationLinkTransitionRepresentableContext(
                    sourceView: sourceView,
                    options: transition.options,
                    environment: context.environment,
                    transaction: context.transaction
                )
            )
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

    func update<Content: View>(
        _ viewController: DestinationHostingController<Content>,
        context: @autoclosure () -> DestinationLinkTransitionRepresentableContext
    ) {

        viewController.hidesBottomBarWhenPushed = options.hidesBottomBarWhenPushed
        if let preferredPresentationBackgroundUIColor = options.preferredPresentationBackgroundUIColor {
            viewController.view.backgroundColor = preferredPresentationBackgroundUIColor
        }

        if case .representable(_, let representable) = self {
            representable.updateHostingController(
                presenting: viewController,
                context: context()
            )
        }
    }
}

#endif
