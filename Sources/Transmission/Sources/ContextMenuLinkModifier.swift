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

    var transition: ContextMenuLinkPreviewTransition
    var isPresented: Binding<Bool>
    var menu: Menu
    var preview: Preview
    var accessoryViews: AccessoryViews

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) {
        self.transition = transition
        self.isPresented = isPresented
        self.menu = menu()
        self.preview = preview()
        self.accessoryViews = accessoryViews()
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ContextMenuLinkAdapter(
                    transition: transition,
                    isPresented: isPresented
                ) {
                    menu
                } preview: {
                    preview
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
        Menu: MenuElement,
        AccessoryViews: View,
        Preview: View
    >(
        transition: ContextMenuLinkPreviewTransition = .default,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) -> some View {
        modifier(
            ContextMenuLinkModifier(
                transition: transition,
                isPresented: isPresented,
                menu: menu,
                preview: preview,
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
            } preview: {
                Color.white
                    .frame(width: 300, height: 300)
            } accessoryViews: {
                ContextMenuAccessoryView(
                    location: .preview,
                    alignment: .topLeading,
                    anchor: .top,
                    trackingAxis: [.horizontal, .vertical]
                ) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 300, height: 44)
                }
            }
        }
    }
}

#endif
