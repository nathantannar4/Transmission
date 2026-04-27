//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A modifier that manages the presentation of a menu. The presentation is
/// sourced from this view, but does not moprh the view with the presented menu.
///
/// The menu is only presented via the `isPresented` binding.
///
/// See Also:
///  - ``MenuLinkAdapter``
///  - ``MenuSourceViewLink``
///
@available(iOS 14.0, *)
@frozen
public struct MenuLinkModifier<
    Menu: MenuElement,
>: ViewModifier {

    var isPresented: Binding<Bool>
    var menu: Menu

    public init(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu
    ) {
        self.isPresented = isPresented
        self.menu = menu()
    }

    public func body(content: Content) -> some View {
        content
            .background(
                MenuLinkAdapter(
                    primaryAction: .disabled,
                    isPresented: isPresented
                ) {
                    menu
                } content: {
                    EmptyView()
                }
            )
    }
}

extension View {

    /// A modifier that manages the presentation of a menu
    @available(iOS 14.0, *)
    public func menuLink<Menu: MenuElement>(
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu
    ) -> some View {
        modifier(MenuLinkModifier(isPresented: isPresented, menu: menu))
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuLinkModifier_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isPresented = false

        var body: some View {
            Button {
                withAnimation {
                    isPresented = true
                }
            } label: {
                Text("Menu")
            }
            .menuLink(isPresented: $isPresented) {
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
