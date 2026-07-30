//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that manages the presentation of a destination view in a new `UIViewController`.
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
    var animation: Animation?
    var useHostingControllerAsSourceView: Bool

    public init(
        transition: LinkTransition,
        animation: Animation? = .default,
        useHostingControllerAsSourceView: Bool = false,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
        self.animation = animation
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
            .modifier(
                OptionalAnimationModifier(
                    animation: animation,
                    value: isPresented.wrappedValue
                )
            )
        )
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that manages the presentation of a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///  - ``DestinationLinkModifier``
    ///
    public func transition<Destination: View>(
        transition: LinkTransition,
        animation: Animation? = .default,
        useHostingControllerAsSourceView: Bool = false,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            TransitionLinkModifier(
                transition: transition,
                animation: animation,
                useHostingControllerAsSourceView: useHostingControllerAsSourceView,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that manages the presentation of a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///  - ``DestinationLinkModifier``
    ///
    public func transition<T, Destination: View>(
        transition: LinkTransition,
        animation: Animation? = .default,
        value: Binding<T?>,
        useHostingControllerAsSourceView: Bool = false,
        @ViewBuilder destination: (T) -> Destination
    ) -> some View {
        self.transition(
            transition: transition,
            animation: animation,
            isPresented: value.isNotNil()
        ) {
            Optional(value, content: destination)
        }
    }
}

#endif
