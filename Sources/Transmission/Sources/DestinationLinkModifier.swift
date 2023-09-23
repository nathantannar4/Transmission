//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore
import Turbocharger

/// A modifier that pushes a destination view in a new `UIViewController`.
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
///  - ``TransitionReader``
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct DestinationLinkModifier<
    Destination: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var destination: Destination
    var transition: DestinationLinkTransition

    public init(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        content.background(
            DestinationLinkModifierBody(
                transition: transition,
                isPresented: isPresented,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    /// A modifier that pushes a destination view in a new `UIViewController`.
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
    public func destination<Destination: View>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that pushes a destination view in a new `UIViewController`.
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
    public func destination<T, Destination: View>(
        _ value: Binding<T?>,
        transition: DestinationLinkTransition = .default,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        self.destination(transition: transition, isPresented: value.isNotNil()) {
            OptionalAdapter(value, content: destination)
        }
    }

    /// A modifier that pushes a destination `UIViewController`.
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
    @_disfavoredOverload
    public func destination<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        self.destination(transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(makeUIViewController: destination)
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct DestinationLinkModifierBody<
    Destination: View
>: UIViewRepresentable {

    var transition: DestinationLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination

    @WeakState var presentingViewController: UIViewController?

    typealias DestinationViewController = HostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(
            presentingViewController: $presentingViewController
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        if let presentingViewController = presentingViewController, isPresented.wrappedValue {

            context.coordinator.isPresented = isPresented

            let isAnimated = context.transaction.isAnimated || (presentingViewController.transitionCoordinator?.isAnimated ?? false)
            context.coordinator.isAnimated = isAnimated

            if let adapter = context.coordinator.adapter {
                adapter.update(
                    destination: destination,
                    isPresented: isPresented,
                    context: context
                )
            } else if let navigationController = presentingViewController.navigationController {

                let adapter = DestinationLinkDestinationViewControllerAdapter(
                    destination: destination,
                    isPresented: isPresented,
                    transition: transition.value,
                    context: context
                )
                context.coordinator.adapter = adapter
                switch adapter.transition {
                case .`default`:
                    break

                case .custom(_, let transition):
                    assert(!isClassType(transition), "DestinationLinkCustomTransition must be value types (either a struct or an enum); it was a class")
                    context.coordinator.sourceView = uiView
                }

                navigationController.delegates.add(delegate: context.coordinator, for: adapter.viewController)
                navigationController.pushViewController(adapter.viewController, animated: isAnimated)
            }
        } else if let adapter = context.coordinator.adapter,
            !isPresented.wrappedValue
        {
            let isAnimated = context.transaction.isAnimated || DestinationCoordinator.transaction.isAnimated
            let viewController = adapter.viewController!
            if let presented = viewController.presentedViewController {
                presented.dismiss(animated: isAnimated) {
                    viewController._popViewController(animated: isAnimated)
                    DestinationCoordinator.transaction = nil
                }
            } else {
                viewController._popViewController(animated: isAnimated)
                DestinationCoordinator.transaction = nil
            }
            context.coordinator.adapter = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }

    final class Coordinator: NSObject,
        UIAdaptivePresentationControllerDelegate,
        UINavigationControllerDelegate
    {
        var isPresented: Binding<Bool>
        var adapter: DestinationLinkDestinationViewControllerAdapter<Destination>?
        var isAnimated = false
        unowned var sourceView: UIView!

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        // MARK: - UINavigationControllerDelegate

        func navigationController(
            _ navigationController: UINavigationController,
            didShow viewController: UIViewController,
            animated: Bool
        ) {
            if let viewController = adapter?.viewController,
                !navigationController.viewControllers.contains(viewController)
            {
                withCATransaction {
                    var transaction = Transaction()
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
            case .custom(_, let transition):
                return transition.navigationController(
                    navigationController,
                    interactionControllerFor: animationController
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
            case .custom(_, let transition):
                return transition.navigationController(
                    navigationController,
                    animationControllerFor: operation,
                    from: fromVC,
                    to: toVC,
                    sourceView: sourceView
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
                    adapter.viewController._popViewController(animated: coordinator.isAnimated)
                }
            }
            coordinator.adapter = nil
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

    init(for navigationController: UINavigationController) {
        super.init()
        self.delegate = navigationController.delegate
        self.navigationController = navigationController
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

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard
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
            return delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            )
        }
        return nil
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
            return delegate.navigationController?(
                navigationController,
                animationControllerFor: operation,
                from: fromVC,
                to: toVC
            )
        }
        return nil
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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class DestinationLinkDestinationViewControllerAdapter<Destination: View> {
    var viewController: UIViewController!
    var context: Any!

    typealias DestinationController = HostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    var transition: DestinationLinkTransition.Value
    var conformance: ProtocolConformance<UIViewControllerRepresentableProtocolDescriptor>? = nil

    init(
        destination: Destination,
        isPresented: Binding<Bool>,
        transition: DestinationLinkTransition.Value,
        context: DestinationLinkModifierBody<Destination>.Context
    ) {
        self.transition = transition
        if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Destination.self) {
            self.conformance = conformance
            update(
                destination: destination,
                isPresented: isPresented,
                context: context
            )
        } else {
            let viewController = DestinationController(
                content: destination.modifier(
                    DestinationBridgeAdapter(
                        isPresented: isPresented
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
        isPresented: Binding<Bool>,
        context: DestinationLinkModifierBody<Destination>.Context
    ) {
        let isPresented = Binding<Bool>(
            get: { true },
            set: { [weak viewController] newValue, transaction in
                if !newValue, let viewController = viewController {
                    let isAnimated = transaction.isAnimated
                        || viewController.transitionCoordinator?.isAnimated == true
                        || DestinationCoordinator.transaction.isAnimated
                    viewController._popViewController(animated: isAnimated) {
                        DestinationCoordinator.transaction = nil
                    }
                }
            }
        )

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
                    isPresented: isPresented
                )
            )
            transition.update(viewController)
        }
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
        var context: DestinationLinkModifierBody<Destination>.Context?
        var adapter: DestinationLinkDestinationViewControllerAdapter<Destination>

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
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<DestinationLinkModifierBody<Destination>.Coordinator>.V4.self
                    ).values.preferenceBridge
                } else {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<DestinationLinkModifierBody<Destination>.Coordinator>.V1.self
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
                let isPresented = self.isPresented
                let destinationCoordinator = DestinationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    dismissBlock: {
                        isPresented.wrappedValue = false
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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DestinationLinkTransition.Value {

    func update<Content: View>(_ viewController: HostingController<Content>) {

        viewController.view.backgroundColor = options.preferredPresentationBackgroundUIColor ?? .systemBackground
    }
}


#endif
