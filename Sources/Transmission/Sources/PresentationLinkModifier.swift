//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A modifier that presents a destination view in a new `UIViewController`.
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
    var animation: Animation?

    public init(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
        self.animation = animation
    }

    public func body(content: Content) -> some View {
        content.background(
            PresentationLinkAdapter(
                transition: transition,
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
extension PresentationLinkModifier {

    public init<T, _Destination: View>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: (Binding<T>) -> _Destination
    ) where Destination == Optional<_Destination> {
        self.init(
            transition: transition,
            animation: animation,
            isPresented: value.isNotNil(),
            destination: Optional(value, content: destination)
        )
    }

    public init<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            animation: animation,
            isPresented: isPresented,
            destination: ViewControllerRepresentableAdapter(destination)
        )
    }

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            animation: animation,
            isPresented: isPresented,
            destination: ViewControllerRepresentableAdapter(destination)
        )
    }

    public init<T, ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            animation: animation,
            isPresented: value.isNotNil()
        ) { [value = value.unwrap()] ctx in
            destination(value!, ctx)
        }
    }

    @_disfavoredOverload
    public init<T, ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            animation: animation,
            isPresented: value.isNotNil()
        ) { [value = value.unwrap()] in
            destination(value!)
        }
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that presents a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<Destination: View>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<T, Destination: View>(
        _ value: Binding<T?>,
        animation: Animation? = .default,
        transition: PresentationLinkTransition = .default,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<T, ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<T, ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct PresentationLinkModifier_Previews: PreviewProvider {
    struct Preview: View {
        @State var value = 0

        func binding(for index: Int) -> Binding<Bool> {
            Binding(
                get: { value == index },
                set: { value = $0 ? index : 0 }
            )
        }

        var body: some View {
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Button(index.description) {
                        withAnimation {
                            value = index
                        }
                    }
                }
            }
            .presentation(
                isPresented: binding(for: 1)
            ) {
                Color.blue
            }
            .presentation(
                isPresented: binding(for: 2)
            ) {
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .blue
                return uiViewController
            }
            .presentation(
                isPresented: binding(for: 3)
            ) { ctx in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .red
                return uiViewController
            }
            .presentation(
                value: Binding<Int?>(
                    get: { value == 4 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .yellow
                return uiViewController
            }
            .presentation(
                value: Binding<Int?>(
                    get: { value == 5 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value, ctx in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .orange
                return uiViewController
            }
        }
    }

    static var previews: some View {
        ZStack {
            Preview()
        }
    }
}

#endif
