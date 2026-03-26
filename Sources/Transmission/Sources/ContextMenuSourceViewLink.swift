//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct ContextMenuLinkPreviewTransition: Sendable {

    enum Value: Sendable {
        case presentation
        case destination
        case custom(_ action: @Sendable () -> Void)
    }
    var value: Value

    public static var `default`: ContextMenuLinkPreviewTransition { .presentation }

    /// The present transition
    public static let presentation = ContextMenuLinkPreviewTransition(value: .presentation)

    /// The push transition
    public static let destination = ContextMenuLinkPreviewTransition(value: .destination)

    public static func custom(_ action: @Sendable @escaping () -> Void) -> ContextMenuLinkPreviewTransition {
        ContextMenuLinkPreviewTransition(value: .custom(action))
    }
}

/// A view manages the presentation of a context menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``ContextMenuLinkAdapter``
///  - ``ContextMenuLinkModifier``
///  - ``ContextMenuAccessoryView``
///
@frozen
@available(iOS 14.0, *)
public struct ContextMenuSourceViewLink<
    Label: View,
    Menu: ContextMenuProvider,
    AccessoryViews: View,
    Preview: View
>: View {

    var label: Label
    var menu: Menu
    var accessoryViews: AccessoryViews
    var preview: Preview
    var transition: ContextMenuLinkPreviewTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var visibleInset: CGFloat

    @StateOrBinding var isPresented: Bool

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        menu: Menu,
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews
    ) {
        self.label = label()
        self.menu = menu
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self._isPresented = .init(false)
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        menu: Menu,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews
    ) where Preview == EmptyView {
        self.init(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            menu: menu,
            preview: { EmptyView() },
            label: label,
            accessoryViews: accessoryViews
        )
    }

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        menu: Menu,
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder label: () -> Label,
    ) where AccessoryViews == EmptyView {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            menu: menu,
            preview: preview,
            label: label,
            accessoryViews: { EmptyView() }
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        menu: Menu,
        @ViewBuilder label: () -> Label,
    ) where Preview == EmptyView, AccessoryViews == EmptyView {
        self.init(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            menu: menu,
            preview: { EmptyView() },
            label: label,
            accessoryViews: { EmptyView() }
        )
    }

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews
    ) {
        self.label = label()
        self.menu = menu
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self._isPresented = .init(isPresented)
    }
    
    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews
    ) where Preview == EmptyView {
        self.init(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: isPresented,
            menu: menu,
            preview: { EmptyView() },
            label: label,
            accessoryViews: accessoryViews
        )
    }

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder label: () -> Label,
    ) where AccessoryViews == EmptyView {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: isPresented,
            menu: menu,
            preview: preview,
            label: label,
            accessoryViews: { EmptyView() }
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder label: () -> Label,
    ) where Preview == EmptyView, AccessoryViews == EmptyView {
        self.init(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: isPresented,
            menu: menu,
            preview: { EmptyView() },
            label: label,
            accessoryViews: { EmptyView() }
        )
    }

    public var body: some View {
        ContextMenuLinkAdapter(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: $isPresented,
            menu: menu
        ) {
            preview
        } label: {
            label
        } accessoryViews: {
            accessoryViews
        }
    }
}

#endif
