//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

/// The window level for a presented ``WindowLink`` destination
@available(iOS 14.0, *)
public struct WindowLinkLevel: Sendable {
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

/// The transition style for a ``WindowLink`` and ``WindowLinkModifier``.
@available(iOS 14.0, *)
public struct WindowLinkTransition: Sendable {
    indirect enum Value: Equatable, Sendable {
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
extension WindowLinkTransition {
    public func combined(with other: WindowLinkTransition) -> WindowLinkTransition {
        WindowLinkTransition(value: .union(value, other.value), options: options)
    }
}

@available(iOS 14.0, *)
extension WindowLinkTransition {
    /// The transition options.
    @frozen
    public struct Options: Sendable {
        /// When `true`, the destination will not be deallocated when dismissed and instead reused for subsequent presentations.
        public var isDestinationReusable: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool

        public init(
            isDestinationReusable: Bool = false,
            shouldAutomaticallyDismissDestination: Bool = true
        ) {
            self.isDestinationReusable = isDestinationReusable
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
        }
    }
}

@available(iOS 14.0, *)
extension WindowLinkTransition.Value {
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

    func toUIKit(isPresented: Bool) -> (alpha: CGFloat?, t: CGAffineTransform) {
        switch self {
        case .identity:
            return (nil, .identity)
        case .opacity:
            return (isPresented ? 1 : 0, .identity)
        case .move(let edge):
            let result: CGAffineTransform = {
                if !isPresented {
                    let size = UIScreen.main.bounds.size
                    switch edge {
                    case .top:
                        return CGAffineTransform(translationX: 0, y: -size.height)
                    case .bottom:
                        return CGAffineTransform(translationX: 0, y: size.height)
                    case .leading:
                        return CGAffineTransform(translationX: -size.width, y: 0)
                    case .trailing:
                        return CGAffineTransform(translationX: size.width, y: 0)
                    }
                } else {
                    return .identity
                }
            }()
            return (nil, result)
        case .scale(let multiplier):
            let result: CGAffineTransform = {
                if !isPresented {
                    return CGAffineTransform(scaleX: multiplier, y: multiplier)
                } else {
                    return .identity
                }
            }()
            return (nil, result)
        case .union(let first, let second):
            let first = first.toUIKit(
                isPresented: isPresented
            )
            let second = second.toUIKit(
                isPresented: isPresented
            )
            return (first.alpha ?? second.alpha, first.t.concatenating(second.t))
        }
    }
}

@available(iOS 14.0, *)
struct WindowBridgeAdapter: ViewModifier {
    var isPresented: Binding<Bool>
    var transition: WindowLinkTransition.Value

    init(
        isPresented: Binding<Bool>,
        transition: WindowLinkTransition.Value
    ) {
        self.isPresented = isPresented
        self.transition = transition
    }

    func body(content: Content) -> some View {
        content
            .modifier(PresentationBridgeAdapter(isPresented: isPresented))
            .frame(maxHeight: .infinity, alignment: transition.toSwiftUIAlignment())
    }
}

#endif
