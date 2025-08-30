//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

/// The transition and presentation style for a ``PresentationLink`` or ``PresentationLinkModifier``.
@available(iOS 14.0, *)
@MainActor @preconcurrency
public struct PresentationLinkTransition: Sendable {

    @MainActor @preconcurrency
    enum Value: @unchecked Sendable {
        case `default`(Options)
        case sheet(SheetTransitionOptions)
        case currentContext(Options)
        case fullscreen(Options)
        case popover(PopoverTransitionOptions)
        case zoom(ZoomOptions)
        case representable(Options, any PresentationLinkTransitionRepresentable)

        var options: Options {
            switch self {
            case .default(let options):
                return options
            case .sheet(let options):
                return options.options
            case .popover(let options):
                return options.options
            case .zoom(let options):
                return options.options
            case .currentContext(let options),
                .fullscreen(let options),
                .representable(let options, _):
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

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static let zoom = PresentationLinkTransition(value: .zoom(.init()))

    /// The zoom presentation style if available, otherwise a backwards compatible variant of the matched geometry presentation style.
    public static var zoomIfAvailable: PresentationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom
        }
        return .matchedGeometryZoom
    }

    /// A custom presentation style.
    public static func custom<
        T: PresentationLinkTransitionRepresentable
    >(
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .representable(.init(), transition))
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    public typealias Shadow = ShadowOptions

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
    @MainActor @preconcurrency
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
                    if #available(iOS 18.0, *), self == .fullScreen {
                        return false
                    }
                    return true
                }

                @available(iOS 18.0, *)
                @available(macOS, unavailable)
                @available(tvOS, unavailable)
                @available(watchOS, unavailable)
                public static let fullScreen = Identifier("com.apple.UIKit.full")

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

            /// Creates a full screen detent.
            @available(iOS 18.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static let fullScreen = Detent(identifier: .fullScreen)

            /// Creates a large detent.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static let large = Detent(identifier: .large)

            /// Creates a full screen detent if preferred and available, otherwise the large detent.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func large(prefersFullScreen: Bool = false) -> Detent {
                if prefersFullScreen, #available(iOS 18.0, *) {
                    return .fullScreen
                }
                return .large
            }

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
            @MainActor
            public func toUIKit(
                in presentationController: UISheetPresentationController
            ) -> UISheetPresentationController.Detent {
                switch identifier {
                case .large:
                    return .large()
                case .medium:
                    return .medium()
                default:
                    if #available(iOS 18.0, *), self == .fullScreen {
                        return .fullScreen() ?? .large()
                    }
                    let idealResolution: @MainActor (UIPresentationController) -> CGFloat = { presentationController in
                        guard let containerView = presentationController.containerView else {
                            let idealHeight = presentationController.presentedViewController.view.intrinsicContentSize.height.rounded(.up)
                            return idealHeight
                        }
                        var width = presentationController.frameOfPresentedViewInContainerView.width
                        if width == 0 {
                            width = containerView.frame.width
                        }
                        @MainActor
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
                                height = viewController.view.idealHeight(for: width)
                                if height <= bottomSafeArea {
                                    height = containerView.frame.height
                                }
                                let idealHeight = (height - bottomSafeArea).rounded(.up)
                                height = idealHeight
                            }
                            return height
                        }

                        let idealHeight = idealHeight(for: presentationController.presentedViewController)
                        return idealHeight
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
                        constant = resolution(ctx).map { min(ceil($0), maximumDetentValue) }
                    } else {
                        constant = height
                    }
                    // _detentWithIdentifier:constant:
                    let aSelector = NSSelectorFromBase64EncodedString("X2RldGVudFdpdGhJZGVudGlmaWVyOmNvbnN0YW50Og==")
                    guard let constant, UISheetPresentationController.Detent.responds(to: aSelector) else {
                        return .large()
                    }
                    let result = UISheetPresentationController.Detent.perform(
                        aSelector,
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
        public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var preferredBackground: BackgroundOptions?
        public var prefersSourceViewAlignment: Bool
        public var prefersScrollingExpandsWhenScrolledToEdge: Bool
        public var prefersEdgeAttachedInCompactHeight: Bool
        public var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool
        public var prefersPageSizing: Bool
        public var prefersZoomTransition: Bool

        public init(
            selected: Binding<SheetTransitionOptions.Detent.Identifier?>? = nil,
            detents: [SheetTransitionOptions.Detent]? = nil,
            largestUndimmedDetentIdentifier: SheetTransitionOptions.Detent.Identifier? = nil,
            isInteractive: Bool? = nil,
            prefersGrabberVisible: Bool = false,
            preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredBackground: BackgroundOptions? = nil,
            prefersSourceViewAlignment: Bool = false,
            prefersScrollingExpandsWhenScrolledToEdge: Bool = true,
            prefersEdgeAttachedInCompactHeight: Bool = false,
            widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = false,
            prefersPageSizing: Bool = false,
            prefersZoomTransition: Bool = false,
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
            self.preferredCornerRadius = {
                if let preferredCornerRadius {
                    return preferredCornerRadius
                }
                return prefersZoomTransition ? .screen() : nil
            }()
            self.preferredBackground = preferredBackground
            self.prefersSourceViewAlignment = prefersSourceViewAlignment
            self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
            self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
            self.widthFollowsPreferredContentSizeWhenEdgeAttached = widthFollowsPreferredContentSizeWhenEdgeAttached
            self.prefersPageSizing = prefersPageSizing
            self.prefersZoomTransition = prefersZoomTransition
        }
    }

    @frozen
    @MainActor @preconcurrency
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

    /// The transition options for a zoom transition.
    @frozen
    @MainActor @preconcurrency
    public struct ZoomOptions {
        public var options: Options
        public var dimmingColor: Color?
        public var dimmingVisualEffect: UIBlurEffect.Style?
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            dimmingColor: Color? = nil,
            dimmingVisualEffect: UIBlurEffect.Style? = nil,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
            options: Options = .init()
        ) {
            self.options = options
            self.dimmingColor = dimmingColor
            self.dimmingVisualEffect = dimmingVisualEffect
            self.hapticsStyle = hapticsStyle
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
    @_disfavoredOverload
    public static func sheet(
        detent: SheetTransitionOptions.Detent,
        prefersGrabberVisible: Bool = false,
        preferredCornerRadius: CGFloat? = nil,
        prefersZoomTransition: Bool = false,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .sheet(
                .init(
                    detents: [detent],
                    prefersGrabberVisible: prefersGrabberVisible,
                    preferredCornerRadius: preferredCornerRadius.map { .rounded(cornerRadius: $0) },
                    prefersEdgeAttachedInCompactHeight: {
                        if #available(iOS 26.0, *) {
                            return detent.identifier == .ideal
                        }
                        return false
                    }(),
                    prefersZoomTransition: prefersZoomTransition,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
                    )
                )
            )
        )
    }

    /// The sheet presentation style.
    public static func sheet(
        detent: SheetTransitionOptions.Detent,
        prefersGrabberVisible: Bool = false,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredBackground: BackgroundOptions? = nil,
        prefersZoomTransition: Bool = false,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .sheet(
                .init(
                    detents: [detent],
                    prefersGrabberVisible: prefersGrabberVisible,
                    preferredCornerRadius: preferredCornerRadius,
                    preferredBackground: preferredBackground,
                    prefersZoomTransition: prefersZoomTransition,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor ?? (preferredBackground != nil ? .clear : nil)
                    )
                )
            )
        )
    }

    /// The sheet presentation style.
    @_disfavoredOverload
    public static func sheet(
        selected: Binding<SheetTransitionOptions.Detent.Identifier?>? = nil,
        detents: [SheetTransitionOptions.Detent],
        prefersGrabberVisible: Bool = false,
        preferredCornerRadius: CGFloat? = nil,
        largestUndimmedDetentIdentifier: SheetTransitionOptions.Detent.Identifier? = nil,
        prefersZoomTransition: Bool = false,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .sheet(
                .init(
                    selected: selected,
                    detents: detents,
                    largestUndimmedDetentIdentifier: largestUndimmedDetentIdentifier,
                    prefersGrabberVisible: prefersGrabberVisible,
                    preferredCornerRadius: preferredCornerRadius.map { .rounded(cornerRadius: $0) },
                    prefersZoomTransition: prefersZoomTransition,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
                    )
                )
            )
        )
    }

    /// The sheet presentation style.
    public static func sheet(
        selected: Binding<SheetTransitionOptions.Detent.Identifier?>? = nil,
        detents: [SheetTransitionOptions.Detent],
        prefersGrabberVisible: Bool = false,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredBackground: BackgroundOptions? = nil,
        largestUndimmedDetentIdentifier: SheetTransitionOptions.Detent.Identifier? = nil,
        prefersZoomTransition: Bool = false,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .sheet(
                .init(
                    selected: selected,
                    detents: detents,
                    largestUndimmedDetentIdentifier: largestUndimmedDetentIdentifier,
                    prefersGrabberVisible: prefersGrabberVisible,
                    preferredCornerRadius: preferredCornerRadius,
                    preferredBackground: preferredBackground,
                    prefersZoomTransition: prefersZoomTransition,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor ?? (preferredBackground != nil ? .clear : nil)
                    )
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
        permittedArrowDirections: PresentationLinkTransition.PopoverTransitionOptions.PermittedArrowDirections = .all,
        canOverlapSourceViewRect: Bool = false,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .popover(
                .init(
                    permittedArrowDirections: permittedArrowDirections,
                    canOverlapSourceViewRect: canOverlapSourceViewRect,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
                    )
                )
            )
        )
    }

    /// The popover presentation style.
    public static func popover(
        options: PopoverTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .popover(options))
    }

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        dimmingColor: Color? = nil,
        dimmingVisualEffect: UIBlurEffect.Style? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .zoom(
                .init(
                    dimmingColor: dimmingColor,
                    dimmingVisualEffect: dimmingVisualEffect,
                    hapticsStyle: hapticsStyle,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
                    )
                )
            )
        )
    }

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        options: ZoomOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .zoom(options))
    }

    /// The zoom presentation style if available, otherwise a backwards compatible variant of the matched geometry presentation style.
    public static func zoomIfAvailable(
        options: ZoomOptions
    ) -> PresentationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(options: options)
        }
        return .matchedGeometry(
            .init(
                prefersScaleEffect: true,
                prefersZoomEffect: true,
                initialOpacity: 0,
                preferredPresentationShadow: options.options.preferredPresentationBackgroundColor == .clear ? .clear : .prominent
            ),
            options: options.options
        )
    }

    /// The zoom presentation style if available, otherwise a fallback transition style.
    public static func zoomIfAvailable(
        options: ZoomOptions,
        otherwise fallback: PresentationLinkTransition
    ) -> PresentationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(options: options)
        }
        return fallback
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
}

#endif
