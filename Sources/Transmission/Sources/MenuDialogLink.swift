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

    @_disfavoredOverload
    public init(
        transition: MenuDialogTransition = .default,
        animation: Animation? = .default,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            transition: transition,
            animation: animation,
            title: Text(title),
            message: Text(message),
            header: header,
            menu: menu,
            label: label
        )
    }

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

    @_disfavoredOverload
    public init(
        transition: MenuDialogTransition = .default,
        animation: Animation? = .default,
        isPresented: Binding<Bool>,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            transition: transition,
            animation: animation,
            isPresented: isPresented,
            title: Text(title),
            message: Text(message),
            header: header,
            menu: menu,
            label: label
        )
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
                title: "Title",
                message: "Message"
            ) {
                MenuButton {

                } label: {
                    Text("Action")
                }

                MenuTextField(
                    "Placeholder",
                    text: .constant("")
                )
            } label: {
                Text("Alert")
            }

            MenuDialogLink(
                transition: .actionSheet,
                title: "Title",
                message: "Message"
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
