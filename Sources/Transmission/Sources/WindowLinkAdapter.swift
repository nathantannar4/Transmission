//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct WindowLinkAdapter<
    Destination: View
>: View {

    var level: WindowLinkLevel
    var transition: WindowLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination

    init(
        level: WindowLinkLevel,
        transition: WindowLinkTransition,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination()
        self.level = level
        self.transition = transition
    }

    public var body: some View {
        WindowLinkAdapterBody(
            level: level,
            transition: transition,
            isPresented: isPresented,
            destination: destination
        )
    }
}

@available(iOS 14.0, *)
private struct WindowLinkAdapterBody<
    Destination: View
>: UIViewRepresentable {

    var level: WindowLinkLevel
    var transition: WindowLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination

    @WeakState var presentingWindow: UIWindow?

    func makeUIView(context: Context) -> WindowReader {
        let uiView = WindowReader(
            presentingWindow: $presentingWindow
        )
        return uiView
    }

    func updateUIView(_ uiView: WindowReader, context: Context) {
        if let presentingWindow = presentingWindow,
            let windowScene = presentingWindow.windowScene,
            isPresented.wrappedValue
        {
            context.coordinator.isPresented = isPresented

            if let adapter = context.coordinator.adapter,
                !context.coordinator.isBeingReused
            {
                adapter.transition = transition
                adapter.update(
                    destination: destination,
                    context: context,
                    isPresented: isPresented
                )
            } else {
                let adapter: WindowLinkDestinationWindowAdapter<Destination>
                if let oldValue = context.coordinator.adapter {
                    adapter = oldValue
                    adapter.transition = transition
                    adapter.update(
                        destination: destination,
                        context: context,
                        isPresented: isPresented
                    )
                    context.coordinator.isBeingReused = false
                } else {
                    adapter = WindowLinkDestinationWindowAdapter(
                        windowScene: windowScene,
                        destination: destination,
                        transition: transition,
                        context: context,
                        isPresented: isPresented,
                        onDismiss: { [weak coordinator = context.coordinator] in
                            coordinator?.onDismiss($0, transaction: $1)
                        }
                    )
                    context.coordinator.adapter = adapter
                }
                switch level.rawValue {
                case .relative(let offset):
                    adapter.window.windowLevel = .init(rawValue: presentingWindow.windowLevel.rawValue + CGFloat(offset))
                case .fixed(let level):
                    adapter.window.windowLevel = .init(rawValue: CGFloat(level))
                }

                let isAnimated = context.transaction.isAnimated
                    || uiView.viewController?.transitionCoordinator?.isAnimated == true
                let animation = context.transaction.animation
                    ?? (isAnimated ? .default : nil)
                let transition = transition
                let window = adapter.window!
                context.coordinator.animation = animation
                presentingWindow.present(
                    window,
                    animation: animation,
                    animations: { isPresented in
                        let fromTransition = transition.value.toUIKit(
                            isPresented: false,
                            window: window
                        )
                        let toTransition = transition.value.toUIKit(
                            isPresented: true,
                            window: window
                        )
                        if isPresented {
                            window.alpha = toTransition.alpha ?? 1
                            window.transform = toTransition.t
                        } else {
                            window.alpha = fromTransition.alpha ?? 1
                            window.transform = fromTransition.t
                        }
                    },
                    completion: {
                        context.coordinator.didPresentAnimated = isAnimated
                    }
                )
            }
        } else if !isPresented.wrappedValue,
            context.coordinator.adapter != nil,
            !context.coordinator.isBeingReused
        {
            context.coordinator.isPresented = isPresented
            context.coordinator.onDismiss(1, transaction: context.transaction)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }

    @MainActor
    final class Coordinator: NSObject {
        var isPresented: Binding<Bool>
        var adapter: WindowLinkDestinationWindowAdapter<Destination>?
        var animation: Animation?
        var didPresentAnimated = false
        var isBeingReused = false

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        func onDismiss(_ count: Int, transaction: Transaction) {
            guard let window = adapter?.window else { return }
            animation = transaction.animation
            didPresentAnimated = false

            // Break the retain cycle
            adapter?.coordinator = nil

            let transition = adapter?.transition ?? .identity
            window.dismiss(
                animation: transaction.animation,
                animations: {
                    let toTransition = transition.value.toUIKit(
                        isPresented: false,
                        window: window
                    )
                    window.alpha = toTransition.alpha ?? 1
                    window.transform = toTransition.t
                },
                completion: {
                    withTransaction(transaction) {
                        self.isPresented.wrappedValue = false
                    }
                    self.didDismiss()
                }
            )
        }

        func didDismiss() {
            if adapter?.transition.options.isDestinationReusable == true {
                isBeingReused = true
            } else {
                adapter = nil
                isBeingReused = false
            }
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        if let adapter = coordinator.adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                let transaction = Transaction(animation: coordinator.didPresentAnimated ? .default : nil)
                withCATransaction {
                    coordinator.onDismiss(1, transaction: transaction)
                }
            } else {
                adapter.coordinator = coordinator
            }
        }
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
private class WindowLinkDestinationWindowAdapter<
    Destination: View
> {

    typealias DestinationWindow = PresentationHostingWindow<ModifiedContent<Destination, WindowBridgeAdapter>>

    var window: UIWindow!
    var context: Any!

    var transition: WindowLinkTransition
    var environment: EnvironmentValues
    var isPresented: Binding<Bool>
    var conformance: ProtocolConformance<UIViewControllerRepresentableProtocolDescriptor>? = nil
    var onDismiss: (Int, Transaction) -> Void

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: WindowLinkAdapterBody<Destination>.Coordinator?

    init(
        windowScene: UIWindowScene,
        destination: Destination,
        transition: WindowLinkTransition,
        context: WindowLinkAdapterBody<Destination>.Context,
        isPresented: Binding<Bool>,
        onDismiss: @escaping (Int, Transaction) -> Void
    ) {
        self.transition = transition
        self.environment = context.environment
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Destination.self) {
            self.conformance = conformance
            let window = PassthroughWindow(windowScene: windowScene)
            self.window = window
            update(
                destination: destination,
                context: context,
                isPresented: isPresented
            )
        } else {
            let window = DestinationWindow(
                windowScene: windowScene,
                content: destination.modifier(
                    WindowBridgeAdapter(
                        presentationCoordinator: PresentationCoordinator(
                            isPresented: isPresented.wrappedValue,
                            sourceView: nil,
                            dismissBlock: { [weak self] in
                                self?.dismiss($0, $1)
                            }
                        ),
                        transition: transition.value
                    )
                )
            )
            self.window = window
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
        context: WindowLinkAdapterBody<Destination>.Context,
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
            let window = window as! DestinationWindow
            window.content = destination.modifier(
                WindowBridgeAdapter(
                    presentationCoordinator: PresentationCoordinator(
                        isPresented: isPresented.wrappedValue,
                        sourceView: nil,
                        dismissBlock: { [weak self] in
                            self?.dismiss($0, $1)
                        }
                    ),
                    transition: transition.value
                )
            )
        }
    }

    func dismiss(_ count: Int, _ transaction: Transaction) {
        onDismiss(count, transaction)
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

    @MainActor
    private struct Visitor: @preconcurrency ViewVisitor {
        nonisolated(unsafe) var destination: Destination?
        nonisolated(unsafe) var isPresented: Binding<Bool>
        nonisolated(unsafe) var context: WindowLinkAdapterBody<Destination>.Context?
        nonisolated(unsafe) var adapter: WindowLinkDestinationWindowAdapter<Destination>

        mutating func visit<Content>(type: Content.Type) where Content: UIViewControllerRepresentable {
            guard
                let destination = destination.map({ unsafeBitCast($0, to: Content.self) }),
                let context = context
            else {
                if let context = adapter.context, let viewController = adapter.window.rootViewController as? Content.UIViewControllerType {
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
                        to: Context<WindowLinkAdapterBody<Destination>.Coordinator>.V4.self
                    ).values.preferenceBridge
                } else {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<WindowLinkAdapterBody<Destination>.Coordinator>.V1.self
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
                let presentationCoordinator = PresentationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    sourceView: nil,
                    dismissBlock: { [weak adapter] in
                        adapter?.dismiss($0, $1)
                    }
                )
                var ctx = unsafeBitCast(value, to: Context<Content.Coordinator>.V1.self)
                ctx.environment.presentationCoordinator = presentationCoordinator
                return unsafeBitCast(ctx, to: Content.Context.self)
            }
            let ctx = _openExistential(adapter.context!, do: project)
            if adapter.window?.rootViewController == nil {
                let viewController = destination.makeUIViewController(context: ctx)
                adapter.window?.rootViewController = viewController
            }
            let viewController = adapter.window.rootViewController as! Content.UIViewControllerType
            destination.updateUIViewController(viewController, context: ctx)
        }
    }
}

#endif
