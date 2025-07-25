//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A modifier that presents a destination view in a new `UIWindow`.
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
/// The destination view is presented with the provided `transition`
/// and `level`. By default, the ``WindowLinkTransition/opacity``
/// transition and ``WindowLinkLevel/default`` are used.
///
/// See Also:
///  - ``WindowLinkTransition``
///  - ``WindowLinkLevel``
///
@available(iOS 14.0, *)
@frozen
public struct WindowLinkModifier<
    Destination: View
>: ViewModifier {

    var level: WindowLinkLevel
    var transition: WindowLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination

    public init(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.level = level
        self.transition = transition
        self.isPresented = isPresented
        self.destination = destination
    }

    public func body(content: Content) -> some View {
        content
            .background(
                WindowLinkModifierBody(
                    isPresented: isPresented,
                    destination: destination,
                    level: level,
                    transition: transition
                )
            )
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that presents a destination view in a new `UIWindow`
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
    ///  - ``WindowLinkModifier``
    ///
    public func window<Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIWindow`
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
    ///  - ``WindowLinkModifier``
    ///
    public func window<T, D: View>(
        _ value: Binding<T?>,
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        @ViewBuilder destination: (Binding<T>) -> D
    ) -> some View {
        window(level: level, transition: transition, isPresented: value.isNotNil()) {
            OptionalAdapter(value, content: destination)
        }
    }

    /// A modifier that presents a destination `UIViewController` in a new `UIWindow`
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
    ///  - ``WindowLinkModifier``
    ///
    public func window<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        window(level: level, transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(destination)
        }
    }

    /// A modifier that presents a destination `UIViewController` in a new `UIWindow`
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
    ///  - ``WindowLinkModifier``
    ///
    public func window<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) -> some View {
        window(
            level: level,
            transition: transition,
            isPresented: isPresented,
            destination: { _ in
                destination()
            }
        )
    }

    /// A modifier that presents a destination view in a new `UIWindow`
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
    ///  - ``WindowLinkModifier``
    ///
    public func window<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        window(level: level, transition: transition, isPresented: value.isNotNil()) {
            ViewControllerRepresentableAdapter<ViewController> { context in
                guard let value = value.unwrap() else { fatalError() }
                return destination(value, context)
            }
        }
    }

    /// A modifier that presents a destination view in a new `UIWindow`
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
    ///  - ``WindowLinkModifier``
    ///
    public func window<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        window(
            value,
            level: level,
            transition: transition,
            destination: { value, _ in
                destination(value)
            }
        )
    }
}

@available(iOS 14.0, *)
private struct WindowLinkModifierBody<
    Destination: View
>: UIViewRepresentable {

    var isPresented: Binding<Bool>
    var destination: Destination
    var level: WindowLinkLevel
    var transition: WindowLinkTransition

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
                    isPresented: isPresented,
                    context: context
                )
            } else {
                let adapter: WindowLinkDestinationWindowAdapter<Destination>
                if let oldValue = context.coordinator.adapter {
                    adapter = oldValue
                    adapter.transition = transition
                    adapter.update(
                        destination: destination,
                        isPresented: isPresented,
                        context: context
                    )
                    context.coordinator.isBeingReused = false
                } else {
                    adapter = WindowLinkDestinationWindowAdapter(
                        windowScene: windowScene,
                        destination: destination,
                        isPresented: isPresented,
                        transition: transition
                    )
                    context.coordinator.adapter = adapter
                }
                switch level.rawValue {
                case .relative(let offset):
                    adapter.window.windowLevel = .init(rawValue: presentingWindow.windowLevel.rawValue + CGFloat(offset))
                case .fixed(let level):
                    adapter.window.windowLevel = .init(rawValue: CGFloat(level))
                }

                let fromTransition = transition.value.toUIKit(
                    isPresented: false,
                    window: adapter.window
                )
                let toTransition = transition.value.toUIKit(
                    isPresented: true,
                    window: adapter.window
                )
                let isAnimated = context.transaction.isAnimated
                    || uiView.viewController?.transitionCoordinator?.isAnimated == true
                let animation = context.transaction.animation
                    ?? (isAnimated ? .default : nil)
                context.coordinator.animation = animation
                presentingWindow.present(
                    adapter.window,
                    animation: animation,
                    transition: { isPresented in
                        if isPresented {
                            adapter.window.alpha = toTransition.alpha ?? 1
                            adapter.window.transform = toTransition.t
                        } else {
                            adapter.window.alpha = fromTransition.alpha ?? 1
                            adapter.window.transform = fromTransition.t
                        }
                    }
                )
            }
        } else if let adapter = context.coordinator.adapter,
            !isPresented.wrappedValue
        {
            let animation = context.transaction.animation
            let toTransition = transition.value.toUIKit(
                isPresented: false,
                window: adapter.window
            )
            adapter.window.dismiss(
                animation: animation,
                transition: {
                    adapter.window.alpha = toTransition.alpha ?? 1
                    adapter.window.transform = toTransition.t
                }
            )
            if transition.options.isDestinationReusable {
                context.coordinator.isBeingReused = true
            } else {
                context.coordinator.adapter = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }

    final class Coordinator: NSObject {
        var isPresented: Binding<Bool>
        var adapter: WindowLinkDestinationWindowAdapter<Destination>?
        var animation: Animation?
        var isBeingReused = false

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        if let adapter = coordinator.adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                let toTransition = adapter.transition.value.toUIKit(
                    isPresented: false,
                    window: adapter.window
                )
                withCATransaction {
                    adapter.window.dismiss(
                        animation: coordinator.animation,
                        transition: {
                            adapter.window.alpha = toTransition.alpha ?? 1
                            adapter.window.transform = toTransition.t
                        },
                        completion: { _ in
                            withCATransaction {
                                coordinator.isPresented.wrappedValue = false
                            }
                        }
                    )
                }
                coordinator.adapter = nil
            } else {
                adapter.coordinator = coordinator
            }
        }
    }
}

@available(iOS 14.0, *)
private class WindowLinkDestinationWindowAdapter<
    Destination: View
> {

    typealias DestinationWindow = PresentationHostingWindow<ModifiedContent<Destination, WindowBridgeAdapter>>

    var window: DestinationWindow!
    var transition: WindowLinkTransition
    var isPresented: Binding<Bool>

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: WindowLinkModifierBody<Destination>.Coordinator?

    init(
        windowScene: UIWindowScene,
        destination: Destination,
        isPresented: Binding<Bool>,
        transition: WindowLinkTransition
    ) {
        self.transition = transition
        self.isPresented = isPresented
        self.window = DestinationWindow(
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
    }

    func update(
        destination: Destination,
        isPresented: Binding<Bool>,
        context: WindowLinkModifierBody<Destination>.Context
    ) {
        self.isPresented = isPresented
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

    func dismiss(_ count: Int, _ transaction: Transaction) {
        guard let window else { return }

        // Break the retain cycle
        coordinator = nil

        let toTransition = transition.value.toUIKit(
            isPresented: false,
            window: window
        )
        window.dismiss(
            animation: transaction.animation,
            transition: {
                window.alpha = toTransition.alpha ?? 1
                window.transform = toTransition.t
            }
        ) { _ in 
            withTransaction(transaction) {
                self.isPresented.wrappedValue = false
            }
        }
    }
}

#endif
