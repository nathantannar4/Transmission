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
///  - ``TransitionLinkModifier``
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
public struct TransitionLinkModifier<
    Destination: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var destination: Destination
    var transition: LinkTransition
    var useHostingControllerAsSourceView: Bool

    public init(
        transition: LinkTransition,
        useHostingControllerAsSourceView: Bool = false,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
        self.useHostingControllerAsSourceView = useHostingControllerAsSourceView
    }

    public func body(content: Content) -> some View {
        content.background(
            TransitionLinkAdapter(
                transition: transition,
                useHostingControllerAsSourceView: useHostingControllerAsSourceView,
                isPresented: isPresented
            ) {
                destination
            }
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
    public func transition<Destination: View>(
        transition: LinkTransition,
        useHostingControllerAsSourceView: Bool = false,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            TransitionLinkModifier(
                transition: transition,
                useHostingControllerAsSourceView: useHostingControllerAsSourceView,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

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
    public func transition<T, Destination: View>(
        _ value: Binding<T?>,
        transition: LinkTransition,
        useHostingControllerAsSourceView: Bool = false,
        @ViewBuilder destination: (T) -> Destination
    ) -> some View {
        self.transition(transition: transition, isPresented: value.isNotNil()) {
            Optional(value, content: destination)
        }
    }
}

#endif
