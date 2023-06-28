//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The transition and presentation style for a ``PresentationLink`` or ``PresentationLinkModifier``.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PresentationLinkTransition {
    enum Value {
        case `default`(Options)
        case sheet(SheetTransitionOptions)
        case currentContext(Options)
        case fullscreen(Options)
        case popover(PopoverTransitionOptions)
        case slide(SlideTransitionOptions)
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
            case .currentContext(let options), .fullscreen(let options), .custom(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the `UIViewController`.
    public static var `default` = PresentationLinkTransition(value: .default(.init()))

    /// The sheet presentation style.
    public static let sheet = PresentationLinkTransition(value: .sheet(.init()))

    /// The current context presentation style.
    public static let currentContext = PresentationLinkTransition(value: .currentContext(.init()))

    /// The fullscreen presentation style.
    public static let fullscreen = PresentationLinkTransition(value: .fullscreen(.init()))

    /// The popover presentation style.
    public static let popover = PresentationLinkTransition(value: .popover(.init()))

    /// The slide presentation style.
    @available(xrOS, unavailable)
    public static let slide = PresentationLinkTransition(value: .slide(.init()))

    /// A custom presentation style.
    public static func custom<T: PresentationLinkCustomTransition>(_ transition: T) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .custom(.init(), transition))
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PresentationLinkTransition {
    /// The transition options.
    @frozen
    public struct Options {
        /// When `true`, the destination will not be deallocated when dismissed and instead reused for subsequent presentations.
        public var isDestinationReusable: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        public var modalPresentationCapturesStatusBarAppearance: Bool
        public var preferredPresentationBackgroundColor: Color?

        public init(
            isDestinationReusable: Bool = false,
            shouldAutomaticallyDismissDestination: Bool = true,
            modalPresentationCapturesStatusBarAppearance: Bool = false,
            preferredPresentationBackgroundColor: Color? = nil
        ) {
            self.isDestinationReusable = isDestinationReusable
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
            self.modalPresentationCapturesStatusBarAppearance = modalPresentationCapturesStatusBarAppearance
            self.preferredPresentationBackgroundColor = preferredPresentationBackgroundColor
        }

        var preferredPresentationBackgroundUIColor: UIColor? {
            guard let color = preferredPresentationBackgroundColor else {
                return nil
            }
            // Need to extract the UIColor since because SwiftUI's UIColor init
            // from a Color does not work for dynamic colors when set on UIView's
            let uiColor = Mirror(reflecting: color).children.lazy.compactMap({ child in
                Mirror(reflecting: child.value).children.first?.value as? UIColor
            }).first
            return uiColor ?? UIColor(color)
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PresentationLinkTransition {
    /// The transition options for a sheet transition.
    @frozen
    public struct SheetTransitionOptions {
        /// The detent of the sheet transition
        @available(macOS, unavailable)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
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
                    #if os(xrOS)
                    return rawValue
                    #else
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
                    #endif
                }

                @available(iOS 15.0, *)
                @available(xrOS, unavailable)
                public static let large = Identifier(UISheetPresentationController.Detent.Identifier.large.rawValue)

                @available(iOS 15.0, *)
                @available(xrOS, unavailable)
                public static let medium = Identifier(UISheetPresentationController.Detent.Identifier.medium.rawValue)

                @available(iOS 15.0, *)
                @available(xrOS, unavailable)
                public static let ideal = Identifier("ideal")

                @available(iOS 15.0, *)
                @available(xrOS, unavailable)
                func toUIKit() -> UISheetPresentationController.Detent.Identifier {
                    .init(rawValue: rawValue)
                }
            }

            public struct ResolutionContext {
                // The trait collection of the sheet's containerView. Effectively the
                // same as the window's traitCollection, and does not include overrides
                // from the sheet's overrideTraitCollection.
                public let containerTraitCollection: UITraitCollection

                // The maximum value a detent can have.
                public let maximumDetentValue: CGFloat
            }

            public var identifier: Identifier

            var height: CGFloat?
            var resolution: ((ResolutionContext) -> CGFloat?)?

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
            @available(xrOS, unavailable)
            public static let large = Detent(identifier: .large)

            /// Creates a medium detent.
            @available(iOS 15.0, *)
            @available(xrOS, unavailable)
            public static let medium = Detent(identifier: .medium)

            /// Creates a detent with an auto-resolved height of the views ideal size.
            @available(iOS 15.0, *)
            @available(xrOS, unavailable)
            public static let ideal = Detent(identifier: .ideal)

            /// Creates a detent with a constant height.
            @available(iOS 15.0, *)
            @available(xrOS, unavailable)
            public static func constant(_ identifier: Identifier, height: CGFloat) -> Detent {
                Detent(identifier: identifier, height: height)
            }

            /// Creates a detent that's height is lazily resolved.
            @available(iOS 15.0, *)
            @available(xrOS, unavailable)
            public static func custom(
                _ identifier: Identifier,
                resolver: @escaping (ResolutionContext) -> CGFloat?
            ) -> Detent {
                Detent(identifier: identifier, resolution: resolver)
            }

            @available(iOS 15.0, *)
            @available(xrOS, unavailable)
            func resolve(in presentationController: UIPresentationController) -> Detent {
                switch identifier {
                case .ideal:
                    var copy = self
                    let resolution: (UIPresentationController) -> CGFloat? = { presentationController in
                        guard let containerView = presentationController.containerView else {
                            let idealHeight = presentationController.presentedViewController.view.intrinsicContentSize.height.rounded(.up)
                            return idealHeight
                        }
                        var width = min(presentationController.presentedViewController.view.frame.width, containerView.frame.width)
                        if width == 0 {
                            width = containerView.frame.width
                        }
                        var height = presentationController.presentedViewController.view
                            .systemLayoutSizeFitting(CGSize(width: width, height: .infinity))
                            .height
                        if height == 0 || height > containerView.frame.height {
                            height = presentationController.presentedViewController.view.intrinsicContentSize.height
                        }
                        let idealHeight = (height - presentationController.presentedViewController.view.safeAreaInsets.bottom).rounded(.up)
                        return min(idealHeight, containerView.frame.height)
                    }
                    if #available(iOS 16.0, *) {
                        copy.resolution = { [weak presentationController] ctx in
                            guard let presentationController = presentationController else {
                                return ctx.maximumDetentValue
                            }
                            return resolution(presentationController)
                        }
                    } else {
                        copy.height = resolution(presentationController)
                    }
                    return copy

                default:
                    return self
                }
            }

            @available(iOS 15.0, *)
            @available(xrOS, unavailable)
            func toUIKit() -> UISheetPresentationController.Detent {
                switch identifier {
                case .large:
                    return .large()
                case .medium:
                    return .medium()
                default:
                    if let resolution = resolution, #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)  {
                        return .custom(identifier: identifier.toUIKit()) { context in
                            let ctx = ResolutionContext(
                                containerTraitCollection: context.containerTraitCollection,
                                maximumDetentValue: context.maximumDetentValue
                            )
                            let max = context.maximumDetentValue
                            return min(resolution(ctx) ?? max, max)
                        }
                    }
                    let sel = NSSelectorFromString(String(":tnatsnoc:reifitnedIhtiWtneted_".reversed()))
                    guard let height = height, UISheetPresentationController.Detent.responds(to: sel) else {
                        return .large()
                    }
                    let result = UISheetPresentationController.Detent.perform(sel, with: identifier.rawValue, with: height)
                    guard let detent = result?.takeUnretainedValue() as? UISheetPresentationController.Detent else {
                        return .large()
                    }
                    return detent
                }
            }
        }

        public var options: Options
        public var selected: Binding<Detent.Identifier?>?
        public var detents: [Detent]
        public var largestUndimmedDetentIdentifier: Detent.Identifier?
        public var isInteractive: Bool
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
            isInteractive: Bool = true,
            prefersGrabberVisible: Bool = false,
            preferredCornerRadius: CGFloat? = nil,
            prefersSourceViewAlignment: Bool = false,
            prefersScrollingExpandsWhenScrolledToEdge: Bool = true,
            prefersEdgeAttachedInCompactHeight: Bool = false,
            widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = false,
            options: Options = .init()
        ) {
            self.options = options
            self.selected = selected
            #if os(xrOS)
            self.detents = []
            #else
            if #available(iOS 15.0, *) {
                self.detents = detents ?? [.large]
            } else {
                self.detents = []
            }
            #endif
            self.largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier
            self.isInteractive = isInteractive
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
        public var isInteractive: Bool

        public init(
            permittedArrowDirections: PermittedArrowDirections = .all,
            canOverlapSourceViewRect: Bool = false,
            adaptiveTransition: SheetTransitionOptions? = nil,
            isInteractive: Bool = true,
            options: PresentationLinkTransition.Options = .init()
        ) {
            self.options = options
            self.permittedArrowDirections = permittedArrowDirections
            self.canOverlapSourceViewRect = canOverlapSourceViewRect
            self.adaptiveTransition = adaptiveTransition
            self.isInteractive = isInteractive
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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PresentationLinkTransition {
    /// The transition options for a slide transition.
    @frozen
    public struct SlideTransitionOptions {

        public var edge: Edge
        public var prefersScaleEffect: Bool
        public var preferredCornerRadius: CGFloat?
        public var isInteractive: Bool
        public var options: Options

        public init(
            edge: Edge = .bottom,
            prefersScaleEffect: Bool = true,
            preferredCornerRadius: CGFloat? = nil,
            isInteractive: Bool = true,
            options: Options = .init(modalPresentationCapturesStatusBarAppearance: true)
        ) {
            self.edge = edge
            self.prefersScaleEffect = prefersScaleEffect
            self.preferredCornerRadius = preferredCornerRadius
            self.isInteractive = isInteractive
            self.options = options
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
    @available(xrOS, unavailable)
    public static func slide(
        edge: Edge
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .slide(.init(edge: edge)))
    }

    /// The slide presentation style.
    @available(xrOS, unavailable)
    public static func slide(
        options: SlideTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .slide(options))
    }

    /// A custom presentation style.
    public static func custom<T: PresentationLinkCustomTransition>(
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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol PresentationLinkCustomTransition {

    /// The presentation controller to use for the transition.
    func presentationController(
        sourceView: UIView,
        presented: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationController

    /// The animation controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?

    /// The animation controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?

    /// The interaction controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    /// 
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?

    /// The presentation style to use for an adaptive presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `.none`
    ///
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle

    /// The presentation controller to use for an adaptive presentation.
    ///
    /// > Note: This protocol implementation is optional
    ///
    func presentationController(
        _ presentationController: UIPresentationController,
        prepare adaptivePresentationController: UIPresentationController
    )
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
