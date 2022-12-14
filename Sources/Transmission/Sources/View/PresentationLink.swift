//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that presents a destination view in a new `UIViewController`.
///
/// The destination view is presented with the provided `transition`.
/// By default, the ``PresentationLinkTransition/default`` transition is used.
///
/// See Also:
///  - ``PresentationLinkTransition``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with a `UIPresentationController` and/or
/// `UIViewControllerInteractiveTransitioning` with the ``PresentationLinkTransition/custom(_:)``
///  transition.
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct PresentationLink<
    Label: View,
    Destination: View
>: View {
    var label: Label
    var destination: Destination
    var transition: PresentationLinkTransition
    @StateOrBinding var isPresented: Bool

    public init(
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.init(transition: .default, destination: destination, label: label)
    }

    public init(
        transition: PresentationLinkTransition = .default,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.destination = destination()
        self.transition = transition
        self._isPresented = .init(false)
    }

    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.init(transition: .default, isPresented: isPresented, destination: destination, label: label)
    }

    public init(
        transition: PresentationLinkTransition,
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
            PresentationLinkAdapter(
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
extension PresentationLink {
    public init<ViewController: UIViewController>(
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == _ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: .default, destination: destination, label: label)
    }

    public init<ViewController: UIViewController>(
        transition: PresentationLinkTransition,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == _ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition) {
            _ViewControllerRepresentableAdapter(makeUIViewController: destination)
        } label: {
            label()
        }
    }

    public init<ViewController: UIViewController>(
        isPresented: Binding<Bool>,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == _ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: .default, isPresented: isPresented, destination: destination, label: label)
    }

    public init<ViewController: UIViewController>(
        transition: PresentationLinkTransition,
        isPresented: Binding<Bool>,
        destination: @escaping (Destination.Context) -> ViewController,
        @ViewBuilder label: () -> Label
    ) where Destination == _ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition, isPresented: isPresented) {
            _ViewControllerRepresentableAdapter(makeUIViewController: destination)
        } label: {
            label()
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PresentationLink_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            VStack(spacing: 20) {
                PresentationLink {
                    Preview()
                } label: {
                    Text("Default")
                }

                PresentationLink(
                    transition: .sheet(detents: [.medium])
                ) {
                    Preview()
                } label: {
                    Text("Present Partial Sheet")
                }

                PresentationLink(
                    transition: .fullscreen
                ) {
                    Preview()
                } label: {
                    Text("Present Fullscreen")
                }

                PresentationLink(
                    transition: .popover
                ) {
                    Preview()
                } label: {
                    Text("Present Popover")
                }
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
