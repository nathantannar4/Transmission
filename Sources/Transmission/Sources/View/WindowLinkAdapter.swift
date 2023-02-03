//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct WindowLinkAdapter<
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
                WindowLinkAdapterBody(
                    isPresented: isPresented,
                    destination: destination,
                    level: level,
                    transition: transition
                )
            )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {

    /// A modifier that presents a destination view in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkAdapter``
    ///
    public func window<Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            WindowLinkAdapter(
                level: level,
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkAdapter``
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
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct WindowLinkAdapterBody<
    Destination: View
>: UIViewRepresentable {

    var isPresented: Binding<Bool>
    var destination: Destination
    var level: WindowLinkLevel
    var transition: WindowLinkTransition

    @WeakState var presentingWindow: UIWindow?

    typealias DestinationContent = ModifiedContent<Destination, WindowBridgeAdapter>

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

            let isAnimated = context.transaction.isAnimated
                || uiView.viewController?.transitionCoordinator?.isAnimated == true
            let destination = destination.modifier(
                WindowBridgeAdapter(
                    isPresented: isPresented,
                    transition: transition,
                    animation: isAnimated ? context.transaction.animation ?? .default : nil
                )
            )
            if let window = context.coordinator.window, !context.coordinator.isBeingReused {
                window.content = destination
            } else {
                let window: HostingWindow<DestinationContent>
                if let oldValue = context.coordinator.window {
                    window = oldValue
                    context.coordinator.isBeingReused = false
                    window.content = destination
                } else {
                    window = HostingWindow(windowScene: windowScene, content: destination)
                    context.coordinator.window = window
                }
                switch level.rawValue {
                case .relative(let offset):
                    window.windowLevel = .init(rawValue: presentingWindow.windowLevel.rawValue + CGFloat(offset))
                case .fixed(let level):
                    window.windowLevel = .init(rawValue: CGFloat(level))
                }

                if transition.value != .identity,
                    uiView.viewController?._transitionCoordinator?.isAnimated == true
                {
                    window.alpha = 0
                }

                presentingWindow.present(window, animated: isAnimated)
            }
        } else if let window = context.coordinator.window, !isPresented.wrappedValue {
            let isAnimated = context.transaction.isAnimated
                || (presentingWindow?.presentedViewController?._transitionCoordinator?.isAnimated ?? false)
            window.content.modifier = WindowBridgeAdapter(
                isPresented: isPresented,
                transition: transition,
                animation: isAnimated ? context.transaction.animation ?? .default : nil
            )
            window.dismiss(animated: isAnimated)
            if transition.options.isDestinationReusable {
                context.coordinator.isBeingReused = true
            } else {
                context.coordinator.window = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }

    final class Coordinator: NSObject {
        var isPresented: Binding<Bool>
        var window: HostingWindow<DestinationContent>?
        var isBeingReused = false

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        let transition = coordinator.window?.content.modifier.transition.value
        coordinator.window?.dismiss(animated: true, transition: {
            withCATransaction {
                coordinator.isPresented.wrappedValue = false
            }
            if transition != .identity {
                coordinator.window?.alpha = 0
            }
        })
        coordinator.window = nil
    }
}

#endif
