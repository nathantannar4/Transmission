//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore

/// A modifier that pushes a destination view in a new `UIViewController`.
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
public struct DestinationLinkModifier<
    Destination: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var destination: Destination
    var transition: DestinationLinkTransition

    public init(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        content.background(
            DestinationLinkAdapter(
                transition: transition,
                isPresented: isPresented
            ) {
                destination
            }
        )
    }
}

@available(iOS 14.0, *)
extension View {
    /// A modifier that pushes a destination view in a new `UIViewController`.
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
    public func destination<Destination: View>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            DestinationLinkModifier(
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that pushes a destination view in a new `UIViewController`.
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
    public func destination<T, Destination: View>(
        _ value: Binding<T?>,
        transition: DestinationLinkTransition = .default,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        self.destination(transition: transition, isPresented: value.isNotNil()) {
            OptionalAdapter(value, content: destination)
        }
    }

    /// A modifier that pushes a destination `UIViewController`.
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
    public func destination<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        self.destination(transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(destination)
        }
    }

    /// A modifier that pushes a destination `UIViewController`.
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
    public func destination<ViewController: UIViewController>(
        transition: DestinationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) -> some View {
        self.destination(
            transition: transition,
            isPresented: isPresented,
            destination: { _ in
                destination()
            }
        )
    }

    /// A modifier that pushes a destination `UIViewController`.
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
    public func destination<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        transition: DestinationLinkTransition = .default,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        self.destination(transition: transition, isPresented: value.isNotNil()) {
            ViewControllerRepresentableAdapter<ViewController> { context in
                guard let value = value.unwrap() else { fatalError() }
                return destination(value, context)
            }
        }
    }

    /// A modifier that pushes a destination `UIViewController`.
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
    public func destination<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        transition: DestinationLinkTransition = .default,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        self.destination(
            value,
            transition: transition,
            destination: { value, _ in
                destination(value)
            }
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
                ForEach(1...5, id: \.self) { index in
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
                Binding<Int?>(
                    get: { value == 4 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .yellow
                return uiViewController
            }
            .destination(
                Binding<Int?>(
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
        NavigationView {
            Preview()
        }
    }
}

#endif
