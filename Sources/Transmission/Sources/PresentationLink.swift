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
///  - ``PresentationSourceViewLink``
///  - ``PresentationLinkTransition``
///  - ``PresentationLinkModifier``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with a `UIPresentationController` and/or
/// `UIViewControllerInteractiveTransitioning` with the ``PresentationLinkTransition/custom(_:)``
///  transition.
///
@available(iOS 14.0, *)
@frozen
public struct PresentationLink<
    Label: View,
    Destination: View
>: View {
    var label: Label
    var destination: Destination
    var transition: PresentationLinkTransition
    var animation: Animation?

    @StateOrBinding var isPresented: Bool

    public init(
        transition: PresentationLinkTransition = .default,
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
        transition: PresentationLinkTransition = .default,
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
            PresentationLinkModifier(
                transition: transition,
                isPresented: $isPresented,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
extension PresentationLink {
    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
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
        transition: PresentationLinkTransition = .default,
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
        transition: PresentationLinkTransition = .default,
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
        transition: PresentationLinkTransition = .default,
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

// MARK: - Previews

@available(iOS 15.0, *)
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
