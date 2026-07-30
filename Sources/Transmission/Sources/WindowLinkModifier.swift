//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A modifier that presents a destination view in a new `UIWindow`.
///
/// The destination view is presented with the provided `transition`
/// and `level`. By default, the ``WindowLinkTransition/opacity``
/// transition and ``WindowLinkLevel/default`` are used.
///
/// See Also:
///  - ``WindowLinkTransition``
///  - ``WindowLinkLevel``
///
@available(iOS 14.0, *)
@frozen
public struct WindowLinkModifier<
    Destination: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var destination: Destination
    var level: WindowLinkLevel
    var transition: WindowLinkTransition
    var animation: Animation?

    public init(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.isPresented = isPresented
        self.destination = destination
        self.level = level
        self.transition = transition
        self.animation = animation
    }

    public func body(content: Content) -> some View {
        content
            .background(
                WindowLinkAdapter(
                    level: level,
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
extension WindowLinkModifier {

    public init<T, _Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: (Binding<T>) -> _Destination
    ) where Destination == Optional<_Destination> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            isPresented: value.isNotNil(),
            destination: Optional(value, content: destination)
        )
    }

    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            isPresented: isPresented,
            destination: ViewControllerRepresentableAdapter(destination)
        )
    }

    @_disfavoredOverload
    public init<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            isPresented: isPresented,
            destination: ViewControllerRepresentableAdapter(destination)
        )
    }

    public init<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) where Destination == Optional<ViewControllerRepresentableAdapter<ViewController>> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            value: value
        ) { $value in
            ViewControllerRepresentableAdapter { ctx in
                destination($value, ctx)
            }
        }
    }

    @_disfavoredOverload
    public init<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController
    ) where Destination == Optional<ViewControllerRepresentableAdapter<ViewController>> {
        self.init(
            level: level,
            transition: transition,
            animation: animation,
            value: value
        ) { $value in
            ViewControllerRepresentableAdapter {
                destination($value)
            }
        }
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that presents a destination view in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkModifier``
    ///
    public func window<Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkModifier``
    ///
    public func window<T, Destination: View>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination `UIViewController` in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkModifier``
    ///
    public func window<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination `UIViewController` in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkModifier``
    ///
    public func window<ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                animation: animation,
                isPresented: isPresented,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkModifier``
    ///
    public func window<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>, ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                animation: animation,
                value: value,
                destination: destination
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIWindow`
    ///
    /// See Also:
    ///  - ``WindowLinkModifier``
    ///
    public func window<T, ViewController: UIViewController>(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        animation: Animation? = .default,
        value: Binding<T?>,
        destination: @escaping (Binding<T>) -> ViewController
    ) -> some View {
        modifier(
            WindowLinkModifier(
                level: level,
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
struct WindowLinkModifier_Previews: PreviewProvider {
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
            .window(
                isPresented: binding(for: 1)
            ) {
                Color.blue
            }
            .window(
                isPresented: binding(for: 2)
            ) {
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .blue
                return uiViewController
            }
            .window(
                isPresented: binding(for: 3)
            ) { ctx in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .red
                return uiViewController
            }
            .window(
                value: Binding<Int?>(
                    get: { value == 4 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .yellow
                return uiViewController
            }
            .window(
                value: Binding<Int?>(
                    get: { value == 5 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { value, ctx in
                let uiViewController = UIViewController()
                uiViewController.view.backgroundColor = .orange
                return uiViewController
            }
            .window(
                value: Binding<Int?>(
                    get: { value == 6 ? value : nil },
                    set: { value = $0 ?? 0 }
                )
            ) { $value in
                Text(value.description)
            }
            .window(
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
            Preview()
        }
    }
}

#endif
