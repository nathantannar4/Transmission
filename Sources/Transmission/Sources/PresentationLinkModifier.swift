//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that presents a destination view in a new `UIViewController`.
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
/// The destination view is presented with the provided `transition`.
/// By default, the ``PresentationLinkTransition/default`` transition is used.
///
/// See Also:
///  - ``PresentationLink``
///  - ``PresentationLinkTransition``
///  - ``PresentationLinkAdapter``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with a `UIPresentationController` and/or
/// `UIViewControllerInteractiveTransitioning` with the ``PresentationLinkTransition/custom(_:)``
///  transition.
///
@available(iOS 14.0, *)
@frozen
public struct PresentationLinkModifier<
    Destination: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var destination: Destination
    var transition: PresentationLinkTransition

    public init(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        content.background(
            PresentationLinkAdapter(
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
    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<Destination: View>(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///  
    public func presentation<T, Destination: View>(
        _ value: Binding<T?>,
        transition: PresentationLinkTransition = .default,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        presentation(transition: transition, isPresented: value.isNotNil()) {
            OptionalAdapter(value, content: destination)
        }
    }

    /// A modifier that presents a destination `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    @_disfavoredOverload
    public func presentation<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        presentation(transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(destination)
        }
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    @_disfavoredOverload
    public func presentation<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        transition: PresentationLinkTransition = .default,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<UIViewController>.Context) -> UIViewController
    ) -> some View {
        presentation(transition: transition, isPresented: value.isNotNil()) {
            ViewControllerRepresentableAdapter { context in
                guard let value = value.unwrap() else { return UIViewController() }
                return destination(value, context)
            }
        }
    }
}

#endif
