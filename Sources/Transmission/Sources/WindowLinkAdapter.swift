//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import os.log
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

    func makeUIView(context: Context) -> WindowReader {
        let uiView = WindowReader()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: WindowReader, context: Context) {
        context.coordinator.onUpdate(
            isPresented: isPresented,
            level: level,
            transition: transition,
            destination: destination,
            context: context,
            sourceView: uiView
        )
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        coordinator.onDismantle()
    }

    typealias Coordinator = WindowLinkCoordinatorAdapter<Destination, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }
}

@MainActor @preconcurrency
@available(iOS 14.0, *)
final class WindowLinkCoordinatorAdapter<
    Destination: View,
    Representable: UIViewRepresentable
>: NSObject, WindowReaderDelegate {

    private var isPresented: Binding<Bool>
    private var adapter: WindowLinkDestinationWindowAdapter<Destination, Representable>?
    private var level: WindowLinkLevel = .default
    private var animation: Animation?
    private var isBeingReused = false

    weak var presentingWindow: UIWindow?

    init(isPresented: Binding<Bool>) {
        self.isPresented = isPresented
    }

    func windowReaderDidMoveToWindow(_ view: UIView) {
        guard presentingWindow == nil else { return }
        if let window = view.window {
            presentingWindow = window
            if let adapter {
                let isAnimated = animation != nil
                withCATransaction {
                    self.present(
                        adapter: adapter,
                        presentingWindow: window,
                        isAnimated: isAnimated
                    )
                }
            }
        }
    }

    func onUpdate(
        isPresented: Binding<Bool>,
        level: WindowLinkLevel,
        transition: WindowLinkTransition,
        destination: Destination,
        context: Representable.Context,
        sourceView: UIView? = nil
    ) {
        self.isPresented = isPresented
        self.level = level

        if isPresented.wrappedValue {

            let isAnimated = context.transaction.isAnimated
                || sourceView?.viewController?.transitionCoordinator?.isAnimated == true
            let animation = context.transaction.animation
                ?? (isAnimated ? .default : nil)
            self.animation = animation

            if let adapter, !isBeingReused {
                switch level.rawValue {
                case .relative(let offset):
                    if let presentingWindow {
                        adapter.window?.windowLevel = .init(rawValue: presentingWindow.windowLevel.rawValue + CGFloat(offset))
                    }
                case .fixed(let level):
                    adapter.window?.windowLevel = .init(rawValue: CGFloat(level))
                }
                adapter.transition = transition
                adapter.update(
                    destination: destination,
                    context: context,
                    isPresented: isPresented
                )
            } else {
                let adapter: WindowLinkDestinationWindowAdapter<Destination, Representable>
                if let oldValue = self.adapter {
                    adapter = oldValue
                    adapter.transition = transition
                    adapter.update(
                        destination: destination,
                        context: context,
                        isPresented: isPresented
                    )
                    self.isBeingReused = false
                } else {
                    adapter = WindowLinkDestinationWindowAdapter(
                        destination: destination,
                        transition: transition,
                        context: context,
                        isPresented: isPresented,
                        onDismiss: { [weak self] in
                            self?.onDismiss($0, transaction: $1)
                        }
                    )
                    self.adapter = adapter
                }
                if let presentingWindow {
                    present(
                        adapter: adapter,
                        presentingWindow: presentingWindow,
                        isAnimated: isAnimated
                    )
                }
            }
        } else if !isPresented.wrappedValue, adapter != nil, !isBeingReused {
            onDismiss(1, transaction: context.transaction)
        }
    }

    func onDismantle() {
        if let adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                let transaction = Transaction(animation: .default)
                withCATransaction {
                    self.onDismiss(1, transaction: transaction)
                }
            } else {
                adapter.coordinator = self
            }
        }
    }

    private func present(
        adapter: WindowLinkDestinationWindowAdapter<Destination, Representable>,
        presentingWindow: UIWindow,
        isAnimated: Bool
    ) {
        let window = adapter.makeOrGetWindow(windowScene: presentingWindow.windowScene)
        switch level.rawValue {
        case .relative(let offset):
            window.windowLevel = .init(rawValue: presentingWindow.windowLevel.rawValue + CGFloat(offset))
        case .fixed(let level):
            window.windowLevel = .init(rawValue: CGFloat(level))
        }

        let transition = adapter.transition
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
            }
        )
    }

    func onDismiss(_ count: Int, transaction: Transaction) {
        guard let window = adapter?.window else { return }
        animation = transaction.animation

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
                if transaction.animation == nil {
                    withCATransaction {
                        self.onDismiss(transaction)
                    }
                } else {
                    self.onDismiss(transaction)
                }
            }
        )
    }

    func onDismiss(_ transaction: Transaction) {
        if isPresented.wrappedValue {
            withTransaction(transaction) {
                isPresented.wrappedValue = false
            }
        }
        didDismiss()
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

@available(iOS 14.0, *)
@MainActor @preconcurrency
private class WindowLinkDestinationWindowAdapter<
    Destination: View,
    Representable: UIViewRepresentable
>: ViewControllerAdapter<Destination, Representable> {

    typealias DestinationController = PresentationHostingWindowController<ModifiedContent<Destination, WindowBridgeAdapter>>

    private(set) var window: UIWindow?

    var transition: WindowLinkTransition
    var environment: EnvironmentValues
    var isPresented: Binding<Bool>
    var conformance: ProtocolConformance<UIViewControllerRepresentableProtocolDescriptor>? = nil
    var onDismiss: (Int, Transaction) -> Void

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: WindowLinkCoordinatorAdapter<Destination, Representable>?

    init(
        destination: Destination,
        transition: WindowLinkTransition,
        context: Representable.Context,
        isPresented: Binding<Bool>,
        onDismiss: @escaping (Int, Transaction) -> Void
    ) {
        self.transition = transition
        self.environment = context.environment
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        super.init(content: destination, context: context)
    }

    func makeOrGetWindow(windowScene: UIWindowScene?) -> UIWindow {
        if let window {
            return window
        } else {
            let window: UIWindow
            if let windowScene {
                window = PassthroughWindow(windowScene: windowScene)
            } else {
                window = PassthroughWindow()
            }
            window.overrideUserInterfaceStyle = .init(transition.options.preferredPresentationColorScheme)
            window.rootViewController = viewController
            if let hostingController = viewController as? DestinationController {
                hostingController.presentingWindow = window
            }
            self.window = window
            return window
        }
    }

    func update(
        destination: Destination,
        context: Representable.Context,
        isPresented: Binding<Bool>
    ) {
        self.isPresented = isPresented
        self.environment = context.environment
        window?.overrideUserInterfaceStyle = .init(transition.options.preferredPresentationColorScheme)
        super.updateViewController(content: destination, context: context)
    }

    private func makePresentationCoordinator() -> PresentationCoordinator {
        PresentationCoordinator(
            isPresented: isPresented.wrappedValue,
            sourceView: nil,
            seed: .constant(self),
            dismissBlock: { [weak self, weak window] in
                if let self {
                    dismiss($0, $1)
                } else {
                    os_log(.debug, log: .default, "WindowLink %{public}@ became detached. Please file an issue.", String(describing: DestinationController.self))
                    window?.dismiss(animation: .default)
                }
            }
        )
    }

    override func makeHostingController(
        content: Destination,
        context: Representable.Context
    ) -> UIViewController {
        let modifier = WindowBridgeAdapter(
            presentationCoordinator: nil,
            transition: transition.value
        )
        let hostingController = DestinationController(content: content.modifier(modifier))
        return hostingController
    }

    override func updateHostingController(
        content: Destination,
        context: Representable.Context
    ) {
        let modifier = WindowBridgeAdapter(
            presentationCoordinator: makePresentationCoordinator(),
            transition: transition.value
        )
        let hostingController = viewController as! DestinationController
        hostingController.update(
            content: content.modifier(modifier),
            transaction: context.transaction
        )
    }

    override func transformViewControllerEnvironment(
        _ environment: inout EnvironmentValues
    ) {
        let presentationCoordinator = PresentationCoordinator(
            isPresented: isPresented.wrappedValue,
            sourceView: nil,
            seed: .constant(self),
            dismissBlock: { [weak self] in self?.dismiss($0, $1) }
        )
        environment.presentationCoordinator = presentationCoordinator
    }

    func dismiss(_ count: Int, _ transaction: Transaction) {
        onDismiss(count, transaction)
    }
}

#endif
