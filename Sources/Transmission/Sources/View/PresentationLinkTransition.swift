//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The transition and presentation style for a ``PresentationLink`` or ``PresentationLinkAdapter``.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PresentationLinkTransition {
    enum Value {
        case `default`
        case sheet(SheetTransitionOptions)
        case currentContext(Options)
        case fullscreen(Options)
        case popover(PopoverTransitionOptions)
        case custom(Options, PresentationLinkCustomTransition)

        var options: Options {
            switch self {
            case .default:
                return Options()
            case .sheet(let options):
                return options.options
            case .popover(let options):
                return options.options
            case .currentContext(let options), .fullscreen(let options), .custom(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the system.
    public static var `default` = PresentationLinkTransition(value: .default)

    /// The sheet presentation style.
    public static let sheet = PresentationLinkTransition(value: .sheet(.init()))

    /// The current context presentation style.
    public static let currentContext = PresentationLinkTransition(value: .currentContext(.init()))

    /// The fullscreen presentation style.
    public static let fullscreen = PresentationLinkTransition(value: .fullscreen(.init()))

    /// The popover presentation style.
    public static let popover = PresentationLinkTransition(value: .popover(.init()))

    /// A custom presentation style.
    public static func custom<T: PresentationLinkCustomTransition>(_ transition: T) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .custom(.init(), transition))
    }
}

// MARK: - Base

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
        public var modalPresentationCapturesStatusBarAppearance: Bool

        public init(
            isDestinationReusable: Bool = false,
            modalPresentationCapturesStatusBarAppearance: Bool = false
        ) {
            self.isDestinationReusable = isDestinationReusable
            self.modalPresentationCapturesStatusBarAppearance = modalPresentationCapturesStatusBarAppearance
        }
    }
}

// MARK: - Sheet

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
                // The trait collection of the sheet's containerView. Effectively the
                // same as the window's traitCollection, and does not include overrides
                // from the sheet's overrideTraitCollection.
                public let containerTraitCollection: UITraitCollection

                // The maximum value a detent can have.
                public let maximumDetentValue: CGFloat
            }

            public var identifier: Identifier

            var height: Int?
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
            public static let ideal = Detent(identifier: .ideal)

            /// Creates a detent with a constant height.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func constant(_ identifier: Identifier, height: Int) -> Detent {
                Detent(identifier: identifier, height: height)
            }

            /// Creates a detent that's height is lazily resolved.
            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public static func custom(
                _ identifier: Identifier,
                resolver: @escaping (ResolutionContext) -> CGFloat?
            ) -> Detent {
                Detent(identifier: identifier, resolution: resolver)
            }

            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            func resolve(in presentationController: UISheetPresentationController) -> Detent {
                switch identifier {
                case .ideal:
                    var copy = self
                    let resolution: () -> CGFloat = { [unowned presentationController] in
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
                        copy.resolution = { _ in resolution() }
                    } else {
                        copy.height = Int(resolution())
                    }
                    return copy

                default:
                    return self
                }
            }

            @available(iOS 15.0, *)
            @available(macOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
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
                            return resolution(ctx)
                        }
                    }
                    // https://github.com/pookjw/CustomSPCDetent/blob/main/CustomSPCDetent/UISheetPresentationControllerDetent%2BPrivate.h
                    let sel = NSSelectorFromString(String(":tnatsnoc:reifitnedIhtiWtneted_".reversed()))
                    guard let height = height, UISheetPresentationController.Detent.responds(to: sel) else {
                        return .large()
                    }
                    let result = UISheetPresentationController.Detent.perform(sel, with: identifier.rawValue, with: CGFloat(height))
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
        public var largestUndimmedDetent: Detent?
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
            largestUndimmedDetent: SheetTransitionOptions.Detent? = nil,
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
            if #available(iOS 15.0, *) {
                self.detents = detents ?? [.large]
            } else {
                self.detents = []
            }
            self.largestUndimmedDetent = largestUndimmedDetent
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
        public var options: Options
        public var isAdaptive: Bool
        public var canOverlapSourceViewRect: Bool

        public init(
            canOverlapSourceViewRect: Bool = false,
            isAdaptive: Bool = false,
            options: PresentationLinkTransition.Options = .init()
        ) {
            self.options = options
            self.isAdaptive = isAdaptive
            self.canOverlapSourceViewRect = canOverlapSourceViewRect
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PresentationLinkTransition {
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
        options: PopoverTransitionOptions
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .popover(options))
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
}

// MARK: - Previews

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PartialSheetTransitionCoordinator_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            VStack(spacing: 20) {
                PresentationLink(transition: .sheet) {
                    Preview()
                } label: {
                    Text("Present Sheet")
                }

                PresentationLink(transition: .sheet(detents: [.medium])) {
                    Preview()
                } label: {
                    Text("Present Partial Sheet")
                }
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
