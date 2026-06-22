//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that presents a destination view in a new `UIWindow`.
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
public struct WindowLink<
    Label: View,
    Destination: View
>: View {

    var label: Label
    var destination: Destination
    var level: WindowLinkLevel
    var transition: WindowLinkTransition
    var animation: Animation?

    @StateOrBinding var isPresented: Bool

    public init(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.level = level
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(false)
    }

    public init(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.level = level
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        Button {
            withAnimation(animation) {
                isPresented.toggle()
            }
        } label: {
            label
        }
        .modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                isPresented: $isPresented,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
extension WindowLink {

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        destination: @escaping () -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            animation: animation
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            animation: animation
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<T, _Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: (Binding<T>) -> _Destination,
        @ViewBuilder label: () -> Label
    ) where Destination == Optional<_Destination> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            isPresented: value.isNotNil()
        ) {
            Optional(value, content: destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            isPresented: isPresented
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            isPresented: isPresented
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == Optional<ViewControllerRepresentableAdapter<ViewController>> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            value: value
        ) { $value in
            ViewControllerRepresentableAdapter { ctx in
                destination($value, ctx)
            }
        } label: {
            label()
        }
    }

    @_disfavoredOverload
    public init<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == Optional<ViewControllerRepresentableAdapter<ViewController>> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            value: value
        ) { $value in
            ViewControllerRepresentableAdapter {
                destination($value)
            }
        } label: {
            label()
        }
    }
}

#endif
