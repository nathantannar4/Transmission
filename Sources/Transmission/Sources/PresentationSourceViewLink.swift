//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that presents a destination view in a new `UIViewController`. The presentation is
/// sourced from this view.
///
/// Use ``PresentationLink`` if the transition does not require animating the source view. For
/// example, the `.zoom` transition morphs the source view into the destination view, so using
/// ``PresentationSourceViewLink`` allows the transition to animate the source view.
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
public struct PresentationSourceViewLink<
    Label: View,
    Destination: View
>: View {
    var label: Label
    var destination: Destination
    var transition: PresentationLinkTransition
    var animation: Animation?

    @StateOrBinding var isPresented: Bool

    public init(
        transition: PresentationLinkTransition = .zoomIfAvailable,
        animation: Animation? = .default,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(false)
    }

    public init(
        transition: PresentationLinkTransition = .zoomIfAvailable,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        PresentationLinkAdapter(
            transition: transition,
            isPresented: $isPresented
        ) {
            destination
        } content: {
            Button {
                withAnimation(animation) {
                    isPresented.toggle()
                }
            } label: {
                label
            }
        }
    }
}

#endif
