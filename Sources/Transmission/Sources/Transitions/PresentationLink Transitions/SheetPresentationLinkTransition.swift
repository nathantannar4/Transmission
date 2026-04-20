//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The sheet presentation style.
    @available(iOS 15.0, *)
    public static let sheet: PresentationLinkTransition = .sheet()

    /// The sheet presentation style.
    @available(iOS 15.0, *)
    public static func sheet(
        detent: SheetPresentationLinkTransition.Detent = .large,
        prefersGrabberVisible: Bool = false,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        prefersZoomTransition: Bool = false,
        zoomTransitionOptions: ZoomTransitionOptions? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationSafeAreaInsets: EdgeInsets? = nil,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .sheet(
            .init(
                detents: [detent],
                prefersGrabberVisible: prefersGrabberVisible,
                preferredCornerRadius: preferredCornerRadius,
                prefersZoomTransition: prefersZoomTransition,
                zoomTransitionOptions: zoomTransitionOptions,
                hapticsStyle: hapticsStyle
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationSafeAreaInsets: preferredPresentationSafeAreaInsets,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }

    /// The sheet presentation style.
    @available(iOS 15.0, *)
    public static func sheet(
        selected: Binding<SheetPresentationLinkTransition.Detent.Identifier?>? = nil,
        detents: [SheetPresentationLinkTransition.Detent],
        prefersGrabberVisible: Bool = false,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        largestUndimmedDetentIdentifier: SheetPresentationLinkTransition.Detent.Identifier? = nil,
        prefersZoomTransition: Bool = false,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .sheet(
            .init(
                selected: selected,
                detents: detents,
                largestUndimmedDetentIdentifier: largestUndimmedDetentIdentifier,
                prefersGrabberVisible: prefersGrabberVisible,
                preferredCornerRadius: preferredCornerRadius,
                prefersZoomTransition: prefersZoomTransition,
                hapticsStyle: hapticsStyle
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }

    /// The sheet presentation style.
    @available(iOS 15.0, *)
    public static func sheet(
        _ transitionOptions: SheetPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init()
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .sheet(transitionOptions),
            options: options
        )
    }
}

/// The transition options for a sheet transition.
@frozen
public struct SheetPresentationLinkTransition: Sendable {

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
            public static let small = Identifier("Transmission.small")

            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static let ideal = Identifier("Transmission.ideal")

            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            func toUIKit() -> UISheetPresentationController.Detent.Identifier {
                .init(rawValue: rawValue)
            }
        }

        public struct ResolutionContext {
            var ctx: Any?

            @available(iOS 16.0, *)
            public var context: UISheetPresentationControllerDetentResolutionContext? {
                ctx as? UISheetPresentationControllerDetentResolutionContext
            }

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
        var resolution: (@MainActor @Sendable (ResolutionContext) -> CGFloat?)?

        public static func == (
            lhs: SheetPresentationLinkTransition.Detent,
            rhs: SheetPresentationLinkTransition.Detent
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

        /// Creates a small detent.
        @available(iOS 15.0, *)
        @available(macOS, unavailable)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public static let small = Detent(identifier: .small, height: 160)

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
            resolver: @MainActor @Sendable @escaping (ResolutionContext) -> CGFloat?
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
                let idealResolution: @MainActor (UISheetPresentationController) -> CGFloat = { presentationController in
                    let scale = presentationController.presentedView?.window?.screen.scale ?? 1.0
                    guard let containerView = presentationController.containerView else {
                        let idealHeight = presentationController.presentedViewController.view.intrinsicContentSize.height
                        return idealHeight.rounded(scale: scale)
                    }
                    let width = containerView.frame.width
                    @MainActor
                    func idealHeight(for viewController: UIViewController) -> CGFloat {
                        func innerIdealHeight(for viewController: UIViewController) -> CGFloat? {
                            if let navigationController = viewController as? UINavigationController,
                               let topViewController = navigationController.topViewController
                            {
                                return idealHeight(for: topViewController)
                            } else if let splitViewController = viewController as? UISplitViewController,
                                      let topViewController = splitViewController.viewController(for: .primary)
                            {
                                return idealHeight(for: topViewController)
                            } else if let tabBarController = viewController as? UITabBarController,
                                      let selectedViewController = tabBarController.selectedViewController
                            {
                                return idealHeight(for: selectedViewController)
                            } else if let pageViewController = viewController as? UIPageViewController,
                                      let selectedViewController = pageViewController.viewControllers?.first
                            {
                                return idealHeight(for: selectedViewController)
                            }
                            return nil
                        }

                        // Edge cases for when the presentedViewController does not have an ideal height
                        var height: CGFloat = 0
                        if let idealHeight = innerIdealHeight(for: viewController) {
                            height = idealHeight
                        } else if viewController is AnyHostingController,
                            viewController.children.count == 1,
                            let idealHeight = innerIdealHeight(for: viewController.children[0])
                        {
                            height = idealHeight
                        }
                        if height == 0 {
                            let bottomSafeArea = viewController.view.safeAreaInsets.bottom
                            height = viewController.view.idealHeight(for: width)
                            if height <= bottomSafeArea {
                                height = containerView.frame.height
                            }
                            height -= bottomSafeArea
                            if #available(iOS 26.0, *), !presentationController.disableSolariumInsets {
                                // 150 is the minimum before safe area gets wonky
                                height = max(height, 151)
                            }
                        }
                        return height.rounded(scale: scale)
                    }

                    let idealHeight = idealHeight(for: presentationController.presentedViewController)
                    return idealHeight
                }

                if let resolution, #available(iOS 16.0, *)  {
                    return .custom(identifier: identifier.toUIKit()) { [unowned presentationController] context in
                        let ctx = ResolutionContext(
                            ctx: context,
                            containerTraitCollection: context.containerTraitCollection,
                            maximumDetentValue: context.maximumDetentValue,
                            idealDetentValue: {
                                idealResolution(presentationController)
                            }
                        )
                        let resolved = resolution(ctx)
                        return min(ceil(resolved ?? ctx.maximumDetentValue), ctx.maximumDetentValue)
                    }
                }
                var constant: CGFloat?
                if let resolution, let maximumDetentValue = presentationController.maximumDetentValue {
                    let ctx = ResolutionContext(
                        containerTraitCollection: presentationController.traitCollection,
                        maximumDetentValue: maximumDetentValue,
                        idealDetentValue: { [unowned presentationController] in
                            idealResolution(presentationController)
                        }
                    )
                    let resolved = resolution(ctx)
                    constant = resolved.map { min(ceil($0), maximumDetentValue) }
                } else {
                    constant = height
                }
                guard let constant else { return .large() }
                // _detentWithIdentifier:constant:
                let aSelector = NSSelectorFromBase64EncodedString("X2RldGVudFdpdGhJZGVudGlmaWVyOmNvbnN0YW50Og==")
                guard UISheetPresentationController.Detent.responds(to: aSelector) else {
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        return .custom(identifier: identifier.toUIKit()) { context in
                            return constant
                        }
                    }
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
                        let resolved = resolution(ctx)
                        return min(ceil(resolved ?? max), max)
                    }
                }
                return detent
            }
        }
    }

    /// The transition options for a sheet transition.
    @frozen
    public struct Options: Sendable {
        public var selected: Binding<Detent.Identifier?>?
        public var detents: [Detent]
        public var largestUndimmedDetentIdentifier: Detent.Identifier?
        public var prefersGrabberVisible: Bool
        public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var prefersSourceViewAlignment: Bool
        public var prefersScrollingExpandsWhenScrolledToEdge: Bool
        public var prefersEdgeAttachedInCompactHeight: Bool
        public var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool
        public var prefersPageSizing: Bool
        public var shouldAdjustDetentsForKeyboard: Bool
        public var prefersSheetInset: Bool
        public var prefersZoomTransition: Bool
        public var zoomTransitionOptions: ZoomTransitionOptions?
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            selected: Binding<SheetPresentationLinkTransition.Detent.Identifier?>? = nil,
            detents: [SheetPresentationLinkTransition.Detent]? = nil,
            largestUndimmedDetentIdentifier: SheetPresentationLinkTransition.Detent.Identifier? = nil,
            prefersGrabberVisible: Bool = false,
            preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            prefersSourceViewAlignment: Bool = false,
            prefersScrollingExpandsWhenScrolledToEdge: Bool = true,
            prefersEdgeAttachedInCompactHeight: Bool = false,
            widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = false,
            prefersPageSizing: Bool = true,
            shouldAdjustDetentsForKeyboard: Bool = true,
            prefersSheetInset: Bool = true,
            prefersZoomTransition: Bool = false,
            zoomTransitionOptions: ZoomTransitionOptions? = nil,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
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
                return prefersZoomTransition ? MainActor.assumeIsolated({.screen()}) : nil
            }()
            self.prefersSourceViewAlignment = prefersSourceViewAlignment
            self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
            self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
            self.widthFollowsPreferredContentSizeWhenEdgeAttached = widthFollowsPreferredContentSizeWhenEdgeAttached
            self.prefersPageSizing = prefersPageSizing
            self.shouldAdjustDetentsForKeyboard = shouldAdjustDetentsForKeyboard
            self.prefersSheetInset = prefersSheetInset
            self.prefersZoomTransition = prefersZoomTransition
            self.zoomTransitionOptions = zoomTransitionOptions
            self.hapticsStyle = hapticsStyle
        }
    }

    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }
}

#if targetEnvironment(macCatalyst)

@available(iOS 15.0, *)
open class SheetPresentationControllerTransition: SlidePresentationControllerTransition {

    public init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            edge: .bottom,
            isPresenting: isPresenting,
            animation: animation
        )
    }
}

#else

@available(iOS 15.0, *)
open class SheetPresentationControllerTransition: PresentationControllerTransition {

    public override init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            isPresenting: isPresenting,
            animation: animation
        )
    }

    open override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentingView = transitionContext.view(forKey: isPresenting ? .from : .to) ?? presenting.view
        else {
            transitionContext.completeTransition(false)
            return
        }

        if isPresenting {
            presentedView.alpha = 0
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()
            presentedFrame = presentedView.frame

            let dy = transitionContext.containerView.frame.height - presentedFrame.origin.y
            let transform = CGAffineTransform(
                translationX: 0,
                y: dy
            )
            presentedView.frame = presentedFrame.applying(transform)
            presentedView.alpha = 1
            animator.addAnimations {
                presentedView.frame = presentedFrame
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            let frame = transitionContext.initialFrame(for: presented)
            let dy = transitionContext.containerView.frame.height - frame.origin.y
            let transform = CGAffineTransform(
                translationX: 0,
                y: dy
            )

            animator.addAnimations {
                presentedView.frame = frame.applying(transform)
            }
        }
        animator.addCompletion { animatingPosition in
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
    }
}

#endif

#endif
