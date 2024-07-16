//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that pushes a destination view in a new `UIViewController`.
///
/// See Also:
///  - ``TransitionReader``
///
@available(iOS 14.0, *)
@frozen
public struct DestinationLink<
    Label: View,
    Destination: View
>: View {
    var label: Label
    var destination: Destination
    var transition: DestinationLinkTransition
    var animation: Animation?
    @StateOrBinding var isPresented: Bool

    public init(
        transition: DestinationLinkTransition = .default,
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
        transition: DestinationLinkTransition = .default,
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
        Button {
            withAnimation(animation) {
                isPresented.toggle()
            }
        } label: {
            label
        }
        .modifier(
            DestinationLinkModifier(
                transition: transition,
                isPresented: $isPresented,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
extension DestinationLink {
    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        destination: @escaping () -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(destination)
        } label: {
            label()
        }
    }
}

#endif
