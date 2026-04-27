//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that manages the presentation of a context menu. The presentation is
/// sourced from this view, but does not raise a view with the presented menu.
///
/// The context menu is only presented via the `isPresented` binding.
///
/// See Also:
///  - ``ContextMenuLinkAdapter``
///  - ``ContextMenuSourceViewLink``
///  - ``ContextMenuAccessoryView``
///
@available(iOS 14.0, *)
@frozen
public struct ContextMenuLinkModifier<
    Menu: MenuElement,
    AccessoryViews: View,
    Preview: View
>: ViewModifier {

    var isPresented: Binding<Bool>
    var menu: Menu
    var accessoryViews: AccessoryViews

    public init(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) where Preview == EmptyView {
        self.isPresented = isPresented
        self.menu = menu()
        self.accessoryViews = accessoryViews()
    }

    public init(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() },
    ) {
        self.isPresented = isPresented
        self.menu = menu()
        self.accessoryViews = accessoryViews()
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ContextMenuLinkAdapter(
                    transition: .default,
                    isPresented: isPresented
                ) {
                    menu
                } preview: {
                    EmptyView()
                } content: {
                    EmptyView()
                } accessoryViews: {
                    accessoryViews
                }
            )
    }
}

@available(iOS 14.0, *)
extension View {

    /// A view manages the presentation of a context menu. The presentation is
    /// sourced from this view, but does not raise a view with the presented menu.
    ///
    /// The context menu is only presented via the `isPresented` binding.
    ///
    public func contextMenuLink<
        Menu: MenuElement
    >(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                isPresented: isPresented,
                menu: menu
            )
        )
    }

    /// A view manages the presentation of a context menu. The presentation is
    /// sourced from this view, but does not raise a view with the presented menu.
    ///
    /// The context menu is only presented via the `isPresented` binding.
    ///
    public func contextMenuLink<
        Menu: MenuElement,
        AccessoryViews: View
    >(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder accessoryViews: () -> AccessoryViews,
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                isPresented: isPresented,
                menu: menu,
                accessoryViews: accessoryViews
            )
        )
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct ContextMenuLinkModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isPresented = false

        var body: some View {
            Button {
                withAnimation {
                    isPresented = true
                }
            } label: {
                Text(isPresented ? "Hide Context Menu" : "Show Context Menu")
            }
            .contextMenuLink(isPresented: $isPresented) {
                MenuButton {

                } label: {
                    Text("Option A")
                }

                MenuButton {

                } label: {
                    Text("Option B")
                }
            }
        }
    }
}

#endif
