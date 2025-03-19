//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

/// The transition and presentation style for a ``PresentationLink`` or ``PresentationLinkModifier``.
@available(iOS 14.0, *)
public struct PresentationLinkTransition: Sendable {
    enum Value: @unchecked Sendable {
        case `default`(Options)
        case sheet(SheetTransitionOptions)
        case currentContext(Options)
        case fullscreen(Options)
        case popover(PopoverTransitionOptions)
        case slide(SlideTransitionOptions)
        case card(CardTransitionOptions)
        case matchedGeometry(MatchedGeometryTransitionOptions)
        case toast(ToastTransitionOptions)
        case zoom(Options)
        case representable(Options, any PresentationLinkTransitionRepresentable)

        @available(*, deprecated)
        case custom(Options, PresentationLinkCustomTransition)

        var options: Options {
            switch self {
            case .default(let options):
                return options
            case .sheet(let options):
                return options.options
            case .popover(let options):
                return options.options
            case .slide(let options):
                return options.options
            case .card(let options):
                return options.options
            case .matchedGeometry(let options):
                return options.options
            case .toast(let options):
                return options.options
            case .currentContext(let options),
                .fullscreen(let options),
                .representable(let options, _),
                .zoom(let options),
                .custom(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the `UIViewController`.
    public static let `default` = PresentationLinkTransition(value: .default(.init()))

    /// The sheet presentation style.
    public static let sheet = PresentationLinkTransition(value: .sheet(.init()))

    /// The current context presentation style.
    public static let currentContext = PresentationLinkTransition(value: .currentContext(.init()))

    /// The fullscreen presentation style.
    public static let fullscreen = PresentationLinkTransition(value: .fullscreen(.init()))

    /// The popover presentation style.
    public static let popover = PresentationLinkTransition(value: .popover(.init()))

    /// The slide presentation style.
    public static let slide = PresentationLinkTransition(value: .slide(.init()))

    /// The card presentation style.
    public static let card = PresentationLinkTransition(value: .card(.init()))

    /// The matched geometry presentation style.
    public static let matchedGeometry = PresentationLinkTransition(value: .matchedGeometry(.init()))

    /// The toast presentation style.
    public static let toast = PresentationLinkTransition(value: .toast(.init()))

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static let zoom = PresentationLinkTransition(value: .zoom(.init()))

    /// A custom presentation style.
    public static func custom<
        T: PresentationLinkTransitionRepresentable
    >(
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .representable(.init(), transition))
    }

    /// A custom presentation style.
    @available(*, deprecated)
    public static func custom<
        T: PresentationLinkCustomTransition
    >(
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .custom(.init(), transition))
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The transition options.
    @frozen
    public struct Options: Sendable {
        /// Used when the presentation delegate asks if it should dismiss
        public var isInteractive: Bool
        /// When `true`, the destination will not be deallocated when dismissed and instead reused for subsequent presentations.
        public var isDestinationReusable: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        /// When `true`, the destination will be presented after dismissing the view the presentation source is already presenting.
        public var shouldAutomaticallyDismissPresentedView: Bool
        public var modalPresentationCapturesStatusBarAppearance: Bool
        public var preferredPresentationBackgroundColor: Color?

        public init(
            isInteractive: Bool = true,
            isDestinationReusable: Bool = false,
            shouldAutomaticallyDismissDestination: Bool = true,
            shouldAutomaticallyDismissPresentedView: Bool = true,
            modalPresentationCapturesStatusBarAppearance: Bool = false,
            preferredPresentationBackgroundColor: Color? = nil
        ) {
            self.isInteractive = isInteractive
            self.isDestinationReusable = isDestinationReusable
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
            self.shouldAutomaticallyDismissPresentedView = shouldAutomaticallyDismissPresentedView
            self.modalPresentationCapturesStatusBarAppearance = modalPresentationCapturesStatusBarAppearance
            self.preferredPresentationBackgroundColor = preferredPresentationBackgroundColor
        }

        var preferredPresentationBackgroundUIColor: UIColor? {
            preferredPresentationBackgroundColor?.toUIColor()
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The transition options for a sheet transition.
    @frozen
    public struct SheetTransitionOptions {
        /// The detent of the sheet transition
        @frozen
        public struct Detent: Equatable {
            /// The identifier of a detent
            @frozen
            public struct Identifier: Equatable, ExpressibleByStringLiteral, CustomDebugStringConvertible, RawRepresentable {
                public var rawValue: String

                public init(rawValue: String) {
                    self.rawValue = rawValue
                }

                public init(_ rawValue: String) {
                    self.rawValue = rawValue
                }

                public init(stringLiteral value: StringLiteralType) {
                    self.init(value)
                }

                public var debugDescription: String {
                    if #available(iOS 15.0, *) {
                        switch self {
                        case .large:
                            return "large"
                        case .medium:
                            return "medium"
                        default:
                            return rawValue
                        }
                    }
                    return rawValue
                }

                var isCustom: Bool {
                    if #available(iOS 15.0, *) {
                        switch self {
                        case .large, .medium, .ideal:
                            return false
                        default:
                            break
                        }
                    }
                    return true
                }

                @available(iOS 15.0, *)
                @available(macOS, unavailable)
                @available(tvOS, unavailable)
                @available(watchOS, unavailable)
                public static let large = Identifier(UISheetPresentationController.Detent.Identifier.large.rawValue)

                @available(iOS 15.0, *)
                @available(macOS, unavailable)
                @available(tvOS, unavailable)
                @available(watchOS, unavailable)
                public static let medium = Identifier(UISheetPresentationController.Detent.Identifier.medium.rawValue)

                @available(iOS 15.0, *)
                @available(macOS, unavailable)
                @available(tvOS, unavailable)
                @available(watchOS, unavailable)
                public static let ideal = Identifier("ideal")

                @available(iOS 15.0, *)
                @available(macOS, unavailable)
                @available(tvOS, unavailable)
                @available(watchOS, unavailable)
                func toUIKit() -> UISheetPresentationController.Detent.Identifier {
                    .init(rawValue: rawValue)
                }
            }

            public struct ResolutionContext {
                /// The trait collection of the sheet's containerView. Effectively the
                /// same as the window's traitCollection, and does not include overrides
                /// from the sheet's overrideTraitCollection.
                public let containerTraitCollection: UITraitCollection

                /// The maximum value a detent can have.
                public let maximumDetentValue: CGFloat

                /// The ideal value a detent would have.
                public let idealDetentValue: () -> CGFloat
            }

            public var identifier: Identifier

            var height: CGFloat?
            var resolution: (@Sendable (ResolutionContext) -> CGFloat?)?

            public static func == (
                lhs: PresentationLinkTransition.SheetTransitionOptions.Detent,
                rhs: PresentationLinkTransition.SheetTransitionOptions.Detent
            ) -> Bool {
                if lhs.identifier != rhs.identifier {
                    return false
                }
                if lhs.height != rhs.height {
                    return false
                }
                if (lhs.resolution != nil && rhs.resolution == nil) || (lhs.resolution == nil && rhs.resolution != nil) {
                    return false
                }
                return true
            }

            /// Creates a large detent.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static let large = Detent(identifier: .large)

            /// Creates a medium detent.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static let medium = Detent(identifier: .medium)

            /// Creates a detent with an auto-resolved height of the views ideal size.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static let ideal = Detent(identifier: .ideal) { ctx in
                return ctx.idealDetentValue()
            }

            /// Creates a detent with an auto-resolved height of the views ideal size bounded between a min/max.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func ideal(
                minimum: CGFloat? = nil,
                maximum: CGFloat? = nil
            ) -> Detent {
                return Detent(identifier: .ideal) { ctx in
                    let ideal = ctx.idealDetentValue()
                    let minimum = minimum ?? ideal
                    let maximum = maximum ?? ctx.maximumDetentValue
                    return max(minimum, min(ideal, maximum))
                }
            }

            /// Creates a detent with a constant height.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func constant(
                _ identifier: Identifier,
                height: CGFloat
            ) -> Detent {
                precondition(identifier.isCustom, "A custom detent identifier must be provided.")
                return Detent(identifier: identifier, height: height)
            }

            /// Creates a detent with a height relative to the maximum detent height.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func percentage(
                _ identifier: Identifier,
                multiplier: CGFloat
            ) -> Detent {
                precondition(identifier.isCustom, "A custom detent identifier must be provided.")
                return Detent(identifier: identifier) { ctx in
                    return ctx.maximumDetentValue * multiplier
                }
            }

            /// Creates a detent that's height is lazily resolved.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func custom(
                _ identifier: Identifier,
                resolver: @Sendable @escaping (ResolutionContext) -> CGFloat?
            ) -> Detent {
                precondition(identifier.isCustom, "A custom detent identifier must be provided.")
                return Detent(identifier: identifier, resolution: resolver)
            }

            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public func toUIKit(
                in presentationController: UISheetPresentationController
            ) -> UISheetPresentationController.Detent {
                switch identifier {
                case .large:
                    return .large()
                case .medium:
                    return .medium()
                default:
                    let idealResolution: (UIPresentationController) -> CGFloat = { presentationController in
                        guard let containerView = presentationController.containerView else {
                            let idealHeight = presentationController.presentedViewController.view.intrinsicContentSize.height.rounded(.up)
                            return idealHeight
                        }
                        func idealHeight(for view: UIView) -> CGFloat {
                            var height = view
                                .systemLayoutSizeFitting(CGSize(width: containerView.frame.width, height: .infinity))
                                .height
                            if height == .infinity {
                                height = view
                                    .sizeThatFits(CGSize(width: containerView.frame.width, height: .infinity))
                                    .height
                            }
                            return min(height, containerView.frame.height)
                        }
                        func idealHeight(for viewController: UIViewController) -> CGFloat {
                            // Edge cases for when the presentedViewController does not have an ideal height
                            var height: CGFloat = 0
                            if let navigationController = viewController as? UINavigationController,
                               let topViewController = navigationController.topViewController
                            {
                                height = idealHeight(for: topViewController)
                            } else if let splitViewController = viewController as? UISplitViewController,
                                      let topViewController = splitViewController.viewController(for: .primary)
                            {
                                height = idealHeight(for: topViewController)
                            } else if let tabBarController = viewController as? UITabBarController,
                                      let selectedViewController = tabBarController.selectedViewController
                            {
                                height = idealHeight(for: selectedViewController)
                            } else if let pageViewController = viewController as? UIPageViewController,
                                      let selectedViewController = pageViewController.viewControllers?.first
                            {
                                height = idealHeight(for: selectedViewController)
                            } else if viewController is AnyHostingController, viewController.children.count == 1, let firstChild = viewController.children.first {
                                height = idealHeight(for: firstChild)
                            }
                            if height == 0 {
                                let bottomSafeArea = viewController.view.safeAreaInsets.bottom
                                height = idealHeight(for: viewController.view)
                                if height <= bottomSafeArea {
                                    height = containerView.frame.height
                                }
                                let idealHeight = (height - bottomSafeArea).rounded(.up)
                                height = idealHeight
                            }
                            return height
                        }

                        let idealHeight = idealHeight(for: presentationController.presentedViewController)
                        return min(idealHeight, containerView.frame.height)
                    }

                    if let resolution, #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)  {
                        return .custom(identifier: identifier.toUIKit()) { [unowned presentationController] context in
                            let ctx = ResolutionContext(
                                containerTraitCollection: context.containerTraitCollection,
                                maximumDetentValue: context.maximumDetentValue,
                                idealDetentValue: {
                                    idealResolution(presentationController)
                                }
                            )
                            let max = context.maximumDetentValue
                            return min(ceil(resolution(ctx) ?? max), max)
                        }
                    }
                    let sel = NSSelectorFromString(String(":tnatsnoc:reifitnedIhtiWtneted_".reversed()))
                    var constant: CGFloat?
                    if let resolution, let containerView = presentationController.containerView {
                        // This seems to match the `maximumDetentValue` computed by UIKit
                        let maximumDetentValue = containerView.frame.inset(by: containerView.safeAreaInsets).height - 10
                        let ctx = ResolutionContext(
                            containerTraitCollection: presentationController.traitCollection,
                            maximumDetentValue: maximumDetentValue,
                            idealDetentValue: { [unowned presentationController] in
                                idealResolution(presentationController)
                            }
                        )
                        constant = resolution(ctx).map { ceil($0) }
                    } else {
                        constant = height
                    }
                    guard let constant, UISheetPresentationController.Detent.responds(to: sel) else {
                        return .large()
                    }
                    let result = UISheetPresentationController.Detent.perform(
                        sel,
                        with: identifier.rawValue,
                        with: constant
                    )
                    guard let detent = result?.takeUnretainedValue() as? UISheetPresentationController.Detent else {
                        return .large()
                    }
                    if let resolution {
                        detent.resolution = { containerTraitCollection, maximumDetentValue in
                            let ctx = ResolutionContext(
                                containerTraitCollection: containerTraitCollection,
                                maximumDetentValue: maximumDetentValue,
                                idealDetentValue: { [unowned presentationController] in
                                    idealResolution(presentationController)
                                }
                            )
                            let max = maximumDetentValue
                            return min(ceil(resolution(ctx) ?? max), max)
                        }
                    }
                    return detent
                }
            }
        }

        public var options: Options
        public var selected: Binding<Detent.Identifier?>?
        public var detents: [Detent]
        public var largestUndimmedDetentIdentifier: Detent.Identifier?
        public var prefersGrabberVisible: Bool
        public var preferredCornerRadius: CGFloat?
        public var prefersSourceViewAlignment: Bool
        public var prefersScrollingExpandsWhenScrolledToEdge: Bool
        public var prefersEdgeAttachedInCompactHeight: Bool
        public var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool

        public init(
            selected: Binding<SheetTransitionOptions.Detent.Identifier?>? = nil,
            detents: [SheetTransitionOptions.Detent]? = nil,
            largestUndimmedDetentIdentifier: SheetTransitionOptions.Detent.Identifier? = nil,
            isInteractive: Bool? = nil,
            prefersGrabberVisible: Bool = false,
            preferredCornerRadius: CGFloat? = nil,
            prefersSourceViewAlignment: Bool = false,
            prefersScrollingExpandsWhenScrolledToEdge: Bool = true,
            prefersEdgeAttachedInCompactHeight: Bool = false,
            widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = false,
            options: Options = .init()
        ) {
            self.options = options
            if let isInteractive {
                self.options.isInteractive = isInteractive
            }
            self.selected = selected
            if #available(iOS 15.0, *) {
                self.detents = detents ?? [.large]
            } else {
                self.detents = []
            }
            self.largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier
            self.prefersGrabberVisible = prefersGrabberVisible
            self.preferredCornerRadius = preferredCornerRadius
            self.prefersSourceViewAlignment = prefersSourceViewAlignment
            self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
            self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
            self.widthFollowsPreferredContentSizeWhenEdgeAttached = widthFollowsPreferredContentSizeWhenEdgeAttached
        }
    }

    @frozen
    public struct PopoverTransitionOptions {
        public typealias PermittedArrowDirections = Edge.Set

        public var options: Options
        public var permittedArrowDirections: PermittedArrowDirections
        public var canOverlapSourceViewRect: Bool
        public var adaptiveTransition: SheetTransitionOptions?

        public init(
            permittedArrowDirections: PermittedArrowDirections = .all,
            canOverlapSourceViewRect: Bool = false,
            adaptiveTransition: SheetTransitionOptions? = nil,
            isInteractive: Bool? = nil,
            options: PresentationLinkTransition.Options = .init()
        ) {
            self.options = options
            if let isInteractive {
                self.options.isInteractive = isInteractive
            }
            self.permittedArrowDirections = permittedArrowDirections
            self.canOverlapSourceViewRect = canOverlapSourceViewRect
            self.adaptiveTransition = adaptiveTransition
        }

        func permittedArrowDirections(layoutDirection: UITraitEnvironmentLayoutDirection) -> UIPopoverArrowDirection {
            var directions: UIPopoverArrowDirection = .any
            if !permittedArrowDirections.contains(.top) {
                directions.subtract(.up)
            }
            if !permittedArrowDirections.contains(.bottom) {
                directions.subtract(.down)
            }
            if !permittedArrowDirections.contains(.leading) {
                directions.subtract(layoutDirection == .leftToRight ? .left : .right)
            }
            if !permittedArrowDirections.contains(.trailing) {
                directions.subtract(layoutDirection == .leftToRight ? .right : .left)
            }
            return directions
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The transition options for a slide transition.
    @frozen
    public struct SlideTransitionOptions {

        public var options: Options
        public var edge: Edge
        public var prefersScaleEffect: Bool
        public var preferredCornerRadius: CGFloat?

        public init(
            edge: Edge = .bottom,
            prefersScaleEffect: Bool = true,
            preferredCornerRadius: CGFloat? = nil,
            isInteractive: Bool? = nil,
            options: Options = .init(modalPresentationCapturesStatusBarAppearance: true)
        ) {
            self.options = options
            if let isInteractive {
                self.options.isInteractive = isInteractive
            }
            self.edge = edge
            self.prefersScaleEffect = prefersScaleEffect
            self.preferredCornerRadius = preferredCornerRadius
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The transition options for a card transition.
    @frozen
    public struct CardTransitionOptions {

        public var options: Options
        public var preferredEdgeInset: CGFloat?
        public var preferredCornerRadius: CGFloat?
        /// A `nil` aspect ratio will size the cards height to it's ideal size
        public var preferredAspectRatio: CGFloat?

        public init(
            preferredEdgeInset: CGFloat? = nil,
            preferredCornerRadius: CGFloat? = nil,
            preferredAspectRatio: CGFloat? = 1,
            isInteractive: Bool? = nil,
            options: Options = .init(modalPresentationCapturesStatusBarAppearance: true)
        ) {
            self.options = options
            if let isInteractive {
                self.options.isInteractive = isInteractive
            }
            self.preferredEdgeInset = preferredEdgeInset
            self.preferredCornerRadius = preferredCornerRadius
            self.preferredAspectRatio = preferredAspectRatio
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The transition options for a matched geometry transition.
    @frozen
    public struct MatchedGeometryTransitionOptions {

        public var options: Options
        public var edges: Edge.Set
        public var preferredCornerRadius: CGFloat?
        public var prefersScaleEffect: Bool
        public var minimumScaleFactor: CGFloat
        public var initialOpacity: CGFloat

        public init(
            edges: Edge.Set = .all,
            preferredCornerRadius: CGFloat? = nil,
            prefersScaleEffect: Bool = false,
            minimumScaleFactor: CGFloat = 0.8,
            initialOpacity: CGFloat = 1,
            options: Options = .init(modalPresentationCapturesStatusBarAppearance: true)
        ) {
            self.options = options
            self.edges = edges
            self.preferredCornerRadius = preferredCornerRadius
            self.prefersScaleEffect = prefersScaleEffect
            self.minimumScaleFactor = minimumScaleFactor
            self.initialOpacity = initialOpacity
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The transition options for a matched geometry transition.
    @frozen
    public struct ToastTransitionOptions {

        public var options: Options
        public var edge: Edge

        public init(
            edge: Edge = .bottom,
            options: Options = .init(preferredPresentationBackgroundColor: .clear)
        ) {
            self.options = options
            self.edge = edge
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {
    /// The default presentation style of the `UIViewController`.
    public static func `default`(
        options: PresentationLinkTransition.Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .default(options))
    }

    /// The sheet presentation style.
    public static func sheet(
        selected: Binding<SheetTransitionOptions.Detent.Identifier?>? = nil,
        detents: [SheetTransitionOptions.Detent]
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .sheet(
                .init(
                    selected: selected,
                    detents: detents
                )
            )
        )
    }

    /// The sheet presentation style.
    public static func sheet(
        options: SheetTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .sheet(options))
    }

    /// The current context presentation style.
    public static func currentContext(
        options: PresentationLinkTransition.Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .currentContext(options))
    }

    /// The fullscreen presentation style.
    public static func fullscreen(
        options: PresentationLinkTransition.Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .fullscreen(options))
    }

    /// The popover presentation style.
    public static func popover(
        permittedArrowDirections: PresentationLinkTransition.PopoverTransitionOptions.PermittedArrowDirections,
        canOverlapSourceViewRect: Bool = false
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .popover(.init(permittedArrowDirections: permittedArrowDirections, canOverlapSourceViewRect: canOverlapSourceViewRect)))
    }

    /// The popover presentation style.
    public static func popover(
        options: PopoverTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .popover(options))
    }

    /// The slide presentation style.
    public static func slide(
        edge: Edge
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .slide(.init(edge: edge)))
    }

    /// The slide presentation style.
    public static func slide(
        options: SlideTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .slide(options))
    }

    /// The card presentation style.
    public static func card(
        options: CardTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .card(options))
    }

    /// The matched geometry presentation style.
    public static func matchedGeometry(
        options: MatchedGeometryTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .matchedGeometry(options))
    }

    /// The toast presentation style.
    public static func toast(
        edge: Edge
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .toast(.init(edge: edge)))
    }

    /// The toast presentation style.
    public static func toast(
        options: ToastTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .toast(options))
    }

    @available(iOS 18.0, *)
    public static func zoom(
        options: Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .zoom(options))
    }

    /// A custom presentation style.
    public static func custom<
        T: PresentationLinkTransitionRepresentable
    >(
        options: PresentationLinkTransition.Options,
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .representable(options, transition))
    }

    /// A custom presentation style.
    @available(*, deprecated)
    public static func custom<
        T: PresentationLinkCustomTransition
    >(
        options: PresentationLinkTransition.Options,
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .custom(options, transition))
    }
}

// MARK: - Custom

/// A protocol that defines a custom transition for a ``PresentationLinkTransition``
///
/// > Important: Conforming types should be a struct or an enum
///
@available(iOS 14.0, *)
@available(*, deprecated, renamed: "PresentationLinkTransitionRepresentable")
@MainActor @preconcurrency
public protocol PresentationLinkCustomTransition {

    /// The presentation controller to use for the transition.
    @MainActor @preconcurrency func presentationController(
        sourceView: UIView,
        presented: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationController

    /// The animation controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?

    /// The animation controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?

    /// The interaction controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    /// 
    @MainActor @preconcurrency func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?

    /// The presentation style to use for an adaptive presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `.none`
    ///
    @MainActor @preconcurrency func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle

    /// The presentation controller to use for an adaptive presentation.
    ///
    /// > Note: This protocol implementation is optional
    ///
    @MainActor @preconcurrency func presentationController(
        _ presentationController: UIPresentationController,
        prepare adaptivePresentationController: UIPresentationController
    )
}

@available(iOS 14.0, *)
@available(*, deprecated, renamed: "PresentationLinkTransitionRepresentable")
extension PresentationLinkCustomTransition {
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }

    public func presentationController(
        _ presentationController: UIPresentationController,
        prepare adaptivePresentationController: UIPresentationController
    ) {

    }
}

#endif
