//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that manages the presentation of a destination view in a new `UIViewController`.
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
///  - ``ConditionalLinkModifier``
///  - ``PresentationLink``
///  - ``PresentationLinkTransition``
///  - ``PresentationSourceViewLink``
///  - ``DestinationLink``
///  - ``DestinationLinkTransition``
///  - ``DestinationSourceViewLink``
///  - ``TransitionReader``
///
@available(iOS 14.0, *)
@frozen
public struct ConditionalLinkModifier<
    Value,
    Destination: View
>: ViewModifier {

    var value: Binding<Value?>
    var destination: (Value) -> Destination
    var transition: (Value) -> ConditionalLinkTransition

    public init(
        value: Binding<Value?>,
        transition: @escaping (Value) -> ConditionalLinkTransition,
        destination: @escaping (Value) -> Destination
    ) {
        self.value = value
        self.destination = destination
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        content.background(
            ConditionalLinkAdapter(
                value: value,
                transition: transition,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that manages the presentation of a destination view in a new `UIViewController`.
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
    ///  - ``DestinationLinkModifier``
    ///
    public func transition<Value, Destination: View>(
        value: Binding<Value?>,
        transition: @escaping (Value) -> ConditionalLinkTransition,
        @ViewBuilder destination: @escaping (Value) -> Destination
    ) -> some View {
        modifier(
            ConditionalLinkModifier(
                value: value,
                transition: transition,
                destination: destination
            )
        )
    }
}

#endif
