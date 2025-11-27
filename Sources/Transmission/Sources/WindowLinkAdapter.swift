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
                let window = adapter.window
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
>: ViewControllerAdapter<Destination, WindowLinkAdapterBody<Destination>> {

    typealias DestinationController = PresentationHostingWindowController<ModifiedContent<Destination, WindowBridgeAdapter>>

    let window: UIWindow

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
        let window = PassthroughWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .init(transition.options.preferredPresentationColorScheme)
        self.window = window
        self.transition = transition
        self.environment = context.environment
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        super.init(content: destination, context: context)
        window.rootViewController = viewController
    }

    func update(
        destination: Destination,
        context: WindowLinkAdapterBody<Destination>.Context,
        isPresented: Binding<Bool>
    ) {
        self.isPresented = isPresented
        self.environment = context.environment
        self.window.overrideUserInterfaceStyle = .init(transition.options.preferredPresentationColorScheme)
        super.updateViewController(content: destination, context: context)
    }

    override func makeHostingController(
        content: Destination,
        context: WindowLinkAdapterBody<Destination>.Context
    ) -> UIViewController {
        let modifier = WindowBridgeAdapter(
            presentationCoordinator: PresentationCoordinator(
                isPresented: isPresented.wrappedValue,
                sourceView: nil,
                seed: unsafeBitCast(self, to: UInt.self),
                dismissBlock: { [weak self] in self?.dismiss($0, $1) }
            ),
            transition: transition.value
        )
        let hostingController = DestinationController(content: content.modifier(modifier))
        hostingController.presentingWindow = window
        return hostingController
    }

    override func updateHostingController(
        content: Destination,
        context: WindowLinkAdapterBody<Destination>.Context
    ) {
        let modifier = WindowBridgeAdapter(
            presentationCoordinator: PresentationCoordinator(
                isPresented: isPresented.wrappedValue,
                sourceView: nil,
                seed: unsafeBitCast(self, to: UInt.self),
                dismissBlock: { [weak self] in self?.dismiss($0, $1) }
            ),
            transition: transition.value
        )
        let hostingController = viewController as! DestinationController
        hostingController.content = content.modifier(modifier)
    }

    override func transformViewControllerEnvironment(
        _ environment: inout EnvironmentValues
    ) {
        let presentationCoordinator = PresentationCoordinator(
            isPresented: isPresented.wrappedValue,
            sourceView: nil,
            seed: unsafeBitCast(self, to: UInt.self),
            dismissBlock: { [weak self] in self?.dismiss($0, $1) }
        )
        environment.presentationCoordinator = presentationCoordinator
    }

    func dismiss(_ count: Int, _ transaction: Transaction) {
        onDismiss(count, transaction)
    }
}

#endif
