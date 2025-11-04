//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The window level for a presented ``WindowLink`` destination
@available(iOS 14.0, *)
public struct WindowLinkLevel: Hashable, Sendable {
    enum Value: Hashable, Sendable {
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
        case scale(scale: CGFloat)
        case offset(x: CGFloat, y: CGFloat)
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

    /// The offset transition.
    public static func offset(x: CGFloat, y: CGFloat) -> WindowLinkTransition {
        WindowLinkTransition(value: .offset(x: x, y: y), options: .init())
    }

    /// The scale transition.
    public static let scale = WindowLinkTransition(value: .scale(scale: .leastNonzeroMagnitude), options: .init())

    /// The scale transition.
    public static func scale(scale: CGFloat) -> WindowLinkTransition {
        WindowLinkTransition(value: .scale(scale: scale), options: .init())
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

    /// The offset transition.
    public static func offset(
        x: CGFloat,
        y: CGFloat,
        options: Options
    ) -> WindowLinkTransition {
        WindowLinkTransition(value: .offset(x: x, y: y), options: options)
    }


    /// The scale transition.
    public static func scale(
        scale: CGFloat,
        options: Options
    ) -> WindowLinkTransition {
        WindowLinkTransition(value: .scale(scale: scale), options: options)
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

    /// The scale transition.
    @available(*, deprecated, renamed: "scale(scale:)")
    public static func scale(
        _ multiplier: CGFloat
    ) -> WindowLinkTransition {
        .scale(scale: multiplier)
    }

    /// The scale transition.
    @available(*, deprecated, renamed: "scale(scale:options:)")
    public static func scale(
        _ multiplier: CGFloat,
        options: Options
    ) -> WindowLinkTransition {
        .scale(scale: multiplier, options: options)
    }
}

@available(iOS 14.0, *)
extension WindowLinkTransition {
    /// The transition options.
    @frozen
    public struct Options: Sendable {
        public var preferredPresentationColorScheme: ColorScheme?
        /// When `true`, the destination will not be deallocated when dismissed and instead reused for subsequent presentations.
        public var isDestinationReusable: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool

        public init(
            preferredPresentationColorScheme: ColorScheme? = nil,
            isDestinationReusable: Bool = false,
            shouldAutomaticallyDismissDestination: Bool = true
        ) {
            self.preferredPresentationColorScheme = preferredPresentationColorScheme
            self.isDestinationReusable = isDestinationReusable
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
        }
    }
}

@available(iOS 14.0, *)
extension WindowLinkTransition.Value {

    func toSwiftUIAlignment() -> Alignment? {
        switch self {
        case .identity, .opacity, .scale:
            return nil
        case .offset(let x, let y):
            var alignment = Alignment.center
            if x < 0 {
                alignment.horizontal = .leading
            } else if x > 0 {
                alignment.horizontal = .trailing
            }
            if y < 0 {
                alignment.vertical = .top
            } else if y > 0 {
                alignment.vertical = .bottom
            }
            return alignment
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
        case .union(let first, let second):
            return first.toSwiftUIAlignment() ?? second.toSwiftUIAlignment()
        }
    }

    func toSwiftUIAnchor() -> UnitPoint? {
        switch self {
        case .identity, .opacity, .scale:
            return nil
        case .offset(let x, let y):
            var anchor = UnitPoint.center
            if x < 0 {
                anchor.x = 0
            } else if x > 0 {
                anchor.x = 1
            }
            if y < 0 {
                anchor.y = 0
            } else if y > 0 {
                anchor.y = 1
            }
            return anchor
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
        case .union(let first, let second):
            return first.toSwiftUIAnchor() ?? second.toSwiftUIAnchor()
        }
    }

    @MainActor
    func toUIKit(
        isPresented: Bool,
        window: UIWindow
    ) -> (alpha: CGFloat?, t: CGAffineTransform) {
        toUIKit(
            isPresented: isPresented,
            window: window,
            anchor: toSwiftUIAnchor() ?? .center
        )
    }

    @MainActor
    private func toUIKit(
        isPresented: Bool,
        window: UIWindow,
        anchor: UnitPoint
    ) -> (alpha: CGFloat?, t: CGAffineTransform) {
        switch self {
        case .identity:
            return (nil, .identity)
        case .opacity:
            return (isPresented ? 1 : 0, .identity)
        case .move(let edge):
            let result: CGAffineTransform = {
                if !isPresented {
                    let size = window.rootViewController?.view.idealSize(for: window.bounds.width) ?? window.frame.size
                    let insets = window.rootViewController?.view.safeAreaInsets ?? .zero
                    switch edge {
                    case .top:
                        let offset = size.height - insets.bottom
                        return CGAffineTransform(translationX: 0, y: -offset)
                    case .bottom:
                        let offset = size.height - insets.top
                        return CGAffineTransform(translationX: 0, y: offset)
                    case .leading:
                        let offset = size.width - insets.right
                        return CGAffineTransform(translationX: -offset, y: 0)
                    case .trailing:
                        let offset = size.width - insets.left
                        return CGAffineTransform(translationX: offset, y: 0)
                    }
                } else {
                    return .identity
                }
            }()
            return (nil, result)
        case .offset(let x, let y):
            let result: CGAffineTransform = {
                if !isPresented {
                    return CGAffineTransform(translationX: x, y: y)
                } else {
                    return .identity
                }
            }()
            return (nil, result)
        case .scale(let scale):
            let result: CGAffineTransform = {
                if !isPresented {
                    let size = window.bounds.size
                    let anchorPoint = CGPoint(
                        x: (1 - scale) * size.width * (0.5 - anchor.x),
                        y: -(1 - scale) * size.height * (1 - anchor.y) / 2
                    )
                    return CGAffineTransform.identity
                        .scaledBy(x: scale, y: scale)
                        .translatedBy(x: anchorPoint.x, y: anchorPoint.y)

                } else {
                    return .identity
                }
            }()
            return (nil, result)
        case .union(let first, let second):
            let first = first.toUIKit(
                isPresented: isPresented,
                window: window,
                anchor: anchor
            )
            let second = second.toUIKit(
                isPresented: isPresented,
                window: window,
                anchor: anchor
            )
            return (first.alpha ?? second.alpha, first.t.concatenating(second.t))
        }
    }
}

@available(iOS 14.0, *)
struct WindowBridgeAdapter: ViewModifier {
    var presentationCoordinator: PresentationCoordinator
    var transition: WindowLinkTransition.Value
    var colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .modifier(
                PresentationBridgeAdapter(
                    presentationCoordinator: presentationCoordinator,
                    colorScheme: colorScheme
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: transition.toSwiftUIAlignment() ?? .center)
    }
}

#endif
