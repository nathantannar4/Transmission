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
                WindowLinkAdapter(
                    level: level,
                    transition: transition,
                    isPresented: isPresented
                ) {
                    destination
                }
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

#endif
