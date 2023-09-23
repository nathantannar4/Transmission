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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct DestinationLink<
    Label: View,
    Destination: View
>: View {
    var label: Label
    var destination: Destination
    var transition: DestinationLinkTransition
    @StateOrBinding var isPresented: Bool

    public init(
        transition: DestinationLinkTransition = .default,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self._isPresented = .init(false)
    }

    public init(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        Button {
            withAnimation {
                isPresented = true
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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DestinationLink {
    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition) {
            ViewControllerRepresentableAdapter(makeUIViewController: destination)
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
            ViewControllerRepresentableAdapter(makeUIViewController: destination)
        } label: {
            label()
        }
    }
}

#endif
