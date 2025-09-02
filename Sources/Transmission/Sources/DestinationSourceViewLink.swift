//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that presents a destination view in a new `UIViewController`. The presentation is
/// sourced from this view.
///
/// Use ``DestinationLink`` if the transition does not require animating the source view. For
/// example, the `.zoom` transition morphs the source view into the destination view, so using
/// ``DestinationSourceViewLink`` allows the transition to animate the source view.
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
///  - ``DestinationLink``
///  - ``DestinationLinkTransition``
///  - ``DestinationLinkAdapter``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with the ``DestinationLinkTransition/custom(_:)``
///  transition.
///
@available(iOS 14.0, *)
@frozen
public struct DestinationSourceViewLink<
    Label: View,
    Destination: View
>: View {
    var label: Label
    var destination: Destination
    var transition: DestinationLinkTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var animation: Animation?

    @StateOrBinding var isPresented: Bool

    public init(
        transition: DestinationLinkTransition = .zoomIfAvailable,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        animation: Animation? = .default,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.animation = animation
        self._isPresented = .init(false)
    }

    public init(
        transition: DestinationLinkTransition = .zoomIfAvailable,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.animation = animation
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        DestinationLinkAdapter(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
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

@available(iOS 14.0, *)
extension DestinationSourceViewLink {
    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        destination: @escaping () -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            isPresented: isPresented
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            isPresented: isPresented
        ) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }
}


#endif
