//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
@frozen
public struct MenuDialogLink<
    Label: View,
    Header: View,
    Menu: MenuElement
>: View {
    var label: Label
    var title: Text?
    var message: Text?
    var header: Header
    var menu: Menu
    var transition: MenuDialogTransition
    var animation: Animation?

    @StateOrBinding var isPresented: Bool

    public init(
        transition: MenuDialogTransition = .default,
        animation: Animation? = .default,
        title: Text? = nil,
        message: Text? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.title = title
        self.message = message
        self.header = header()
        self.menu = menu()
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(false)
    }

    public init(
        transition: MenuDialogTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        title: Text? = nil,
        message: Text? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.title = title
        self.message = message
        self.header = header()
        self.menu = menu()
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        Button {
            withAnimation(animation) {
                isPresented.toggle()
            }
        } label: {
            label
        }
        .modifier(
            MenuDialogLinkModifier(
                transition: transition,
                isPresented: $isPresented,
                title: title,
                message: message,
                header: header,
                menu: menu
            )
        )
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuDialogLink_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MenuDialogLink(
                transition: .alert,
            ) {
                MenuButton {

                } label: {
                    Text("Action")
                }
            } label: {
                Text("Alert")
            }

            MenuDialogLink(
                transition: .actionSheet
            ) {
                MenuButton {

                } label: {
                    Text("Action")
                }
            } label: {
                Text("Action Sheet")
            }
        }
    }
}

#endif
