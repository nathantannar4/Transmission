//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore

/// A modifier that pushes a destination view in a new `UIViewController`.
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
public struct DestinationLinkModifier<
    Destination: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var destination: Destination
    var transition: DestinationLinkTransition
    var animation: Animation?

    public init(
        transition: DestinationLinkTransition = .default,
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
            DestinationLinkAdapter(
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
extension DestinationLinkModifier {

    public init<T, _Destination: View>(
        transition: DestinationLinkTransition = .default,
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
        transition: DestinationLinkTransition = .default,
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
        transition: DestinationLinkTransition = .default,
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
        transition: DestinationLinkTransition = .default,
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
        transition: DestinationLinkTransition = .default,
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

    /// A modifier that pushes a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``DestinationLinkLinkModifier``
    ///
    public func destination<Destination: View>(
        transition: DestinationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that pushes a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``DestinationLinkLinkModifier``
    ///
    public func destination<T, Destination: View>(
        transition: DestinationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }

    /// A modifier that pushes a destination `UIViewController`.
    ///
    /// See Also:
    ///  - ``DestinationLinkLinkModifier``
    ///
    public func destination<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination
            )
        )
    }

    /// A modifier that pushes a destination `UIViewController`.
    ///
    /// See Also:
    ///  - ``DestinationLinkLinkModifier``
    ///
    public func destination<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination
            )
        )
    }

    /// A modifier that pushes a destination `UIViewController`.
    ///
    /// See Also:
    ///  - ``DestinationLinkLinkModifier``
    ///
    public func destination<T, ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }

    /// A modifier that pushes a destination `UIViewController`.
    ///
    /// See Also:
    ///  - ``DestinationLinkLinkModifier``
    ///
    public func destination<T, ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        modifier(
            DestinationLinkModifier(
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
struct DestinationLinkModifier_Previews: PreviewProvider {
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
                ForEach(1...7, id: \.self) { index in
                    Button(index.description) {
                        withAnimation {
                            value = index
                        }
                    }
                }
            }
            .destination(
                isPresented: binding(for: 1)
            ) {
                Color.blue
            }
            .destination(
                isPresented: binding(for: 2)
            ) {
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .blue
                return uiViewController
            }
            .destination(
                isPresented: binding(for: 3)
            ) { ctx in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .red
                return uiViewController
            }
            .destination(
                value: Binding<Int?>(
                    get: { value == 4 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .yellow
                return uiViewController
            }
            .destination(
                value: Binding<Int?>(
                    get: { value == 5 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value, ctx in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .orange
                return uiViewController
            }
            .destination(
                value: Binding<Int?>(
                    get: { value == 6 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { $value in
                Text(value.description)
            }
            .destination(
                value: Binding<Int?>(
                    get: { value == 7 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { $value in
                Text(value.description)
            }
        }
    }

    static var previews: some View {
        ZStack {
            NavigationView {
                Preview()
            }
        }
    }
}

#endif
