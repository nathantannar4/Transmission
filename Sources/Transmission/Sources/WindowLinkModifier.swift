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
extension WindowLinkModifier {

    public init<T, _Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        value: Binding<T?>,
        destination: (Binding<T>) -> _Destination
    ) where Destination == Optional<_Destination> {
        self.init(
            level: level,
            transition: transition,
            isPresented: value.isNotNil(),
            destination: Optional(value, content: destination)
        )
    }

    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            isPresented: isPresented,
            destination: ViewControllerRepresentableAdapter(destination)
        )
    }

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            isPresented: isPresented,
            destination: ViewControllerRepresentableAdapter(destination)
        )
    }

    public init<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) where Destination == Optional<ViewControllerRepresentableAdapter<ViewController>> {
        self.init(
            level: level,
            transition: transition,
            value: value
        ) { $value in
            ViewControllerRepresentableAdapter { ctx in
                destination($value, ctx)
            }
        }
    }

    @_disfavoredOverload
    public init<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController
    ) where Destination == Optional<ViewControllerRepresentableAdapter<ViewController>> {
        self.init(
            level: level,
            transition: transition,
            value: value
        ) { $value in
            ViewControllerRepresentableAdapter {
                destination($value)
            }
        }
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
    public func window<T, Destination: View>(
        _ value: Binding<T?>,
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                value: value,
                destination: destination
            )
        )
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
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                isPresented: isPresented,
                destination: destination
            )
        )
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
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                isPresented: isPresented,
                destination: destination
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
    public func window<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                value: value,
                destination: destination
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
    public func window<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                value: value,
                destination: destination
            )
        )
    }
}

#endif
