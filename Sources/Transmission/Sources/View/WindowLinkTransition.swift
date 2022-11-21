//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

/// The window level for a presented ``WindowLink`` destination
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct WindowLinkLevel {
    enum Value {
        case relative(Int)
        case fixed(CGFloat)
    }
    var rawValue: Value

    /// The default level, which is the same as the presenting window's level.
    public static let `default` = WindowLinkLevel(rawValue: .relative(0))

    /// The overlay level, which is one unit higher than the presenting window's level.
    public static let overlay = WindowLinkLevel(rawValue: .relative(1))

    /// The background level, which is one unit lower than the presenting window's level.
    public static let background = WindowLinkLevel(rawValue: .relative(-1))

    /// The alert window level
    public static let alert = WindowLinkLevel(rawValue: .fixed(UIWindow.Level.alert.rawValue))

    /// A custom level
    public static func custom(_ level: CGFloat) -> WindowLinkLevel {
        WindowLinkLevel(rawValue: .fixed(level))
    }
}

/// The transition style for a ``WindowLink`` and ``WindowLinkAdapter``.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct WindowLinkTransition {
    indirect enum Value: Equatable {
        case identity
        case opacity
        case move(edge: Edge)
        case scale(multiplier: CGFloat)
        case union(Value, Value)
    }
    var value: Value
    var options: Options

    /// The identity transition.
    public static let identity = WindowLinkTransition(value: .identity, options: .init())

    /// The opacity transition.
    public static let opacity = WindowLinkTransition(value: .opacity, options: .init())

    /// The move transition.
    public static func move(edge: Edge) -> WindowLinkTransition {
        WindowLinkTransition(value: .move(edge: edge), options: .init())
    }

    /// The scale transition.
    public static func scale(_ multiplier: CGFloat) -> WindowLinkTransition {
        WindowLinkTransition(value: .scale(multiplier: multiplier), options: .init())
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension WindowLinkTransition {

    /// The identity transition.
    public static func identity(
        options: Options
    ) -> WindowLinkTransition {
        WindowLinkTransition(value: .identity, options: options)
    }

    /// The opacity transition.
    public static func opacity(
        options: Options
    ) -> WindowLinkTransition {
        WindowLinkTransition(value: .opacity, options: options)
    }

    /// The move transition.
    public static func move(
        edge: Edge,
        options: Options
    ) -> WindowLinkTransition {
        WindowLinkTransition(value: .move(edge: edge), options: options)
    }

    /// The scale transition.
    public static func scale(
        _ multiplier: CGFloat,
        options: Options
    ) -> WindowLinkTransition {
        WindowLinkTransition(value: .scale(multiplier: multiplier), options: options)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension WindowLinkTransition {
    public func combined(with other: WindowLinkTransition) -> WindowLinkTransition {
        WindowLinkTransition(value: .union(value, other.value), options: options)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension WindowLinkTransition {
    /// The transition options.
    @frozen
    public struct Options {
        /// When `true`, the destination will not be deallocated when dismissed and instead reused for subsequent presentations.
        public var isDestinationReusable: Bool

        public init(isDestinationReusable: Bool = false) {
            self.isDestinationReusable = isDestinationReusable
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension WindowLinkTransition {
    struct AnimatedValue {
        var value: Value
        var animation: Animation?
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension WindowLinkTransition.Value {
    func toSwiftUITransition() -> AnyTransition {
        switch self {
        case .identity:
            return .identity
        case .opacity:
            return .opacity
        case .move(let edge):
            return .move(edge: edge)
        case .scale(let multiplier):
            return .modifier(active: ScaleModifier(multiplier: multiplier), identity: ScaleModifier(multiplier: 1))
        case .union(let first, let second):
            return first.toSwiftUITransition().combined(with: second.toSwiftUITransition())
        }
    }

    func toSwiftUIAlignment() -> Alignment {
        switch self {
        case .identity, .opacity, .scale:
            return .center
        case .move(let edge):
            switch edge {
            case .top:
                return .top
            case .bottom:
                return .bottom
            case .leading:
                return .leading
            case .trailing:
                return .trailing
            }
        case .union(let first, _):
            return first.toSwiftUIAlignment()
        }
    }

    struct ScaleModifier: ViewModifier {
        var multiplier: CGFloat

        func body(content: Content) -> some View {
            content
                .scaleEffect(multiplier)
                .ignoresSafeArea()
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct WindowBridgeAdapter: ViewModifier {
    var isPresented: Binding<Bool>
    weak var host: UIView?
    var transition: WindowLinkTransition.AnimatedValue

    init(isPresented: Binding<Bool>, host: UIView? = nil, transition: WindowLinkTransition, animation: Animation?) {
        self.isPresented = isPresented
        self.host = host
        self.transition = WindowLinkTransition.AnimatedValue(value: transition.value, animation: animation)
    }

    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                if transaction.animation == nil, !transaction.disablesAnimations {
                    transaction.animation = transition.animation
                }
            }
            .modifier(
                AppearanceTransitionModifier(
                    transition: transition.value.toSwiftUITransition(),
                    animation: transition.animation,
                    isPresented: isPresented
                )
            )
            .modifier(
                AppearanceTransitionModifier(
                    transition: transition.value.toSwiftUITransition(),
                    animation: transition.animation
                )
            )
            .modifier(PresentationBridgeAdapter(isPresented: isPresented, host: host))
            .frame(maxHeight: .infinity, alignment: transition.value.toSwiftUIAlignment())
    }
}

#endif
