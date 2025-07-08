//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that presents a destination view in a new `UIViewController`.
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

    public init(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        content.background(
            PresentationLinkAdapter(
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
    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<Destination: View>(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            PresentationLinkModifier(
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///  
    public func presentation<T, Destination: View>(
        _ value: Binding<T?>,
        transition: PresentationLinkTransition = .default,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        presentation(transition: transition, isPresented: value.isNotNil()) {
            OptionalAdapter(value, content: destination)
        }
    }

    /// A modifier that presents a destination `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        presentation(transition: transition, isPresented: isPresented) {
            ViewControllerRepresentableAdapter(destination)
        }
    }

    /// A modifier that presents a destination `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) -> some View {
        presentation(
            transition: transition,
            isPresented: isPresented,
            destination: { _ in
                destination()
            }
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        transition: PresentationLinkTransition = .default,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        presentation(transition: transition, isPresented: value.isNotNil()) {
            ViewControllerRepresentableAdapter<ViewController> { context in
                guard let value = value.unwrap() else { fatalError() }
                return destination(value, context)
            }
        }
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
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
    ///  - ``PresentationLinkModifier``
    ///
    public func presentation<T, ViewController: UIViewController>(
        _ value: Binding<T?>,
        transition: PresentationLinkTransition = .default,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        presentation(
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
                Binding<Int?>(
                    get: { value == 4 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .yellow
                return uiViewController
            }
            .presentation(
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
        Preview()
    }
}

#endif
