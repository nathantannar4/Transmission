//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A view manages the presentation of a context menu. The presentation is
/// sourced from this view, but does not raise a view with the presented menu.
///
/// See Also:
///  - ``ContextMenuLinkAdapter``
///  - ``ContextMenuSourceViewLink``
///  - ``ContextMenuAccessoryView``
///
@available(iOS 14.0, *)
@frozen
public struct ContextMenuLinkModifier<
    Menu: ContextMenuProvider,
    AccessoryViews: View,
    Preview: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var menu: Menu
    var accessoryViews: AccessoryViews
    var preview: Preview
    var transition: ContextMenuLinkPreviewTransition

    public init(
        isPresented: Binding<Bool>,
        menu: Menu,
        accessoryViews: AccessoryViews = EmptyView()
    ) where Preview == EmptyView {
        self.isPresented = isPresented
        self.menu = menu
        self.accessoryViews = accessoryViews
        self.preview = EmptyView()
        self.transition = .default
    }

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        isPresented: Binding<Bool>,
        menu: Menu,
        accessoryViews: AccessoryViews = EmptyView(),
        preview: Preview
    ) {
        self.isPresented = isPresented
        self.menu = menu
        self.accessoryViews = accessoryViews
        self.preview = preview
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        content.background(
            ContextMenuLinkAdapter(
                transition: transition,
                isPresented: isPresented,
                menu: menu,
                preview: { preview },
                label: { EmptyView() },
                accessoryViews: { accessoryViews }
            )
        )
    }
}

@available(iOS 14.0, *)
extension View {

    public func contextMenuLink<
        Menu: ContextMenuProvider
    >(
        isPresented: Binding<Bool>,
        menu: Menu
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                isPresented: isPresented,
                menu: menu
            )
        )
    }

    public func contextMenuLink<
        Menu: ContextMenuProvider,
        AccessoryViews: View
    >(
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder accessoryViews: () -> AccessoryViews,
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                isPresented: isPresented,
                menu: menu,
                accessoryViews: accessoryViews()
            )
        )
    }

    public func contextMenuLink<
        Menu: ContextMenuProvider,
        Preview: View
    >(
        transition: ContextMenuLinkPreviewTransition = .default,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder preview: () -> Preview,
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                transition: transition,
                isPresented: isPresented,
                menu: menu,
                preview: preview()
            )
        )
    }

    public func contextMenuLink<
        Menu: ContextMenuProvider,
        AccessoryViews: View,
        Preview: View
    >(
        transition: ContextMenuLinkPreviewTransition = .default,
        isPresented: Binding<Bool>,
        menu: Menu,
        @ViewBuilder accessoryViews: () -> AccessoryViews,
        @ViewBuilder preview: () -> Preview,
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                transition: transition,
                isPresented: isPresented,
                menu: menu,
                accessoryViews: accessoryViews(),
                preview: preview()
            )
        )
    }
}

#endif
