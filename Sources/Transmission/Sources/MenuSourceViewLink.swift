//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A view that manages the presentation of a context menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``MenuLinkAdapter``
///  - ``MenuLinkModifier``
///  - ``MenuSourceViewLink``
///
@available(iOS 14.0, *)
@frozen
public struct MenuSourceViewLink<
    Menu: MenuElement,
    Label: View
>: View {

    var label: Label
    var menu: Menu
    var primaryAction: MenuLinkPrimaryAction
    var cornerRadius: CornerRadiusOptions?
    var background: MenuLinkBackgroundStyle
    var visibleInset: CGFloat

    @StateOrBinding var isPresented: Bool

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label,
        primaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            primaryAction: primaryAction.map { .custom($0) } ?? .showMenu,
            menu: menu,
            label: label
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        primaryAction: MenuLinkPrimaryAction,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.menu = menu()
        self.primaryAction = primaryAction
        self.cornerRadius = cornerRadius
        self.background = background
        self.visibleInset = visibleInset
        self._isPresented = .init(false)
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label,
        primaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            isPresented: isPresented,
            primaryAction: primaryAction.map { .custom($0) } ?? .showMenu,
            menu: menu,
            label: label
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        background: MenuLinkBackgroundStyle = .plain,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        primaryAction: MenuLinkPrimaryAction,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.menu = menu()
        self.primaryAction = primaryAction
        self.cornerRadius = cornerRadius
        self.background = background
        self.visibleInset = visibleInset
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        MenuLinkAdapter(
            primaryAction: primaryAction,
            cornerRadius: cornerRadius,
            background: background,
            visibleInset: visibleInset,
            isPresented: $isPresented
        ) {
            menu
        } content: {
            label
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuSourceViewLink_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                MenuSourceViewLink {

                } label: {
                    Text("Empty Menu")
                }

                MenuSourceViewLink {
                    MenuGroup {

                    }
                } label: {
                    Text("Empty Menu")
                }
            }

            MenuSourceViewLink {
                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }
            } label: {
                Text("Single Action Menu")
            }

            MenuSourceViewLink {
                MenuButton(attributes: .destructive) {

                } label: {
                    Text("Delete")
                }

                MenuButton(attributes: .disabled) {

                } label: {
                    Text("Disabled")
                }

                MenuButton(attributes: .hidden) { }
            } label: {
                Text("Multi Action Menu")
            }

            MenuSourceViewLink {
                for item in ["A", "B", "C"] {
                    MenuButton {

                    } label: {
                        Text("Action \(item)")
                    }
                }
            } label: {
                Text("For loop Action Menu")
            }

            MenuSourceViewLink {
                MenuGroup {
                    for item in ["A", "B", "C"] {
                        MenuButton {

                        } label: {
                            Text("Action \(item)")
                        }
                    }
                }
            } label: {
                Text("For loop Group Menu")
            }

            if #available(iOS 16.0, *) {
                StateAdapter(initialValue: false) { $isEnabled in
                    MenuSourceViewLink {
                        MenuGroup {
                            if isEnabled {
                                MenuButton(attributes: .keepsMenuPresented) {
                                    withAnimation {
                                        isEnabled = false
                                    }
                                } label: {
                                    Text("Turn Off")
                                }
                            } else {
                                MenuButton(attributes: .keepsMenuPresented) {
                                    withAnimation {
                                        isEnabled = true
                                    }
                                } label: {
                                    Text("Turn On")
                                }
                            }
                        }

                        MenuGroup {
                            MenuButton(attributes: .keepsMenuPresented) {
                                withAnimation {
                                    isEnabled.toggle()
                                }
                            } label: {
                                Text("Toggle")
                            }

                            if isEnabled {
                                MenuButton(attributes: .disabled) {

                                } label: {
                                    Text("Option A")
                                }
                            } else {
                                MenuButton(attributes: .disabled) {

                                } label: {
                                    Text("Option B")
                                }
                            }
                        } label: {
                            Text(isEnabled ? "Enabled Details" : "Disabled Details")
                        }

                        MenuButton(attributes: .keepsMenuPresented) {
                            withAnimation {
                                isEnabled.toggle()
                            }
                        } label: {
                            Text("Toggle")
                        }
                    } label: {
                        Text("Conditional Menu")
                    }
                }

                StateAdapter(initialValue: 1) { $selection in
                    MenuSourceViewLink {
                        for item in 1...(selection + 1) {
                            MenuButton(
                                attributes: .keepsMenuPresented,
                                state: selection == item ? .on : .off
                            ) {
                                withAnimation {
                                    selection = item
                                }
                            } label: {
                                Text("Action \(item)")
                            }
                        }

                        MenuGroup(id: "a") {
                            for item in 1...(selection + 1) {
                                MenuButton(
                                    attributes: .keepsMenuPresented,
                                    state: selection == item ? .on : .off
                                ) {
                                    withAnimation {
                                        selection = item
                                    }
                                } label: {
                                    Text("Action \(item)")
                                }
                            }
                        } label: {
                            Text("Sub Selection A")
                        }

                        MenuGroup(id: "b") {
                            for item in 1...(selection + 1) {
                                MenuButton(
                                    attributes: .keepsMenuPresented,
                                    state: selection == item ? .on : .off
                                ) {
                                    withAnimation {
                                        selection = item
                                    }
                                } label: {
                                    Text("Action \(item)")
                                }
                            }
                        } label: {
                            Text("Sub Selection B")
                        }
                    } label: {
                        Text("Select Action Menu")
                    }
                }
            }

            MenuSourceViewLink {
                MenuGroup {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                }
            } label: {
                Text("Single Action SubMenu")
            }

            MenuSourceViewLink {
                MenuGroup(id: "a") {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                } label: {
                    Image(systemName: "apple.logo")
                    Text("Submenu 1")
                }

                MenuGroup(id: "b") {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                } label: {
                    Image(systemName: "apple.logo")
                    Text("Submenu 2")
                }
            } label: {
                Text("Multi Menu")
            }

            if #available(iOS 16.0, *) {
                MenuSourceViewLink {
                    MenuGroup(size: .medium) {
                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option C")
                        }
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "apple.logo")
                        Text("Option D")
                    }
                } label: {
                    Text("Medium Menu")
                }

                MenuSourceViewLink {
                    MenuGroup(size: .small) {
                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Image(systemName: "apple.logo")
                            Text("Option C")
                        }
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "apple.logo")
                        Text("Option D")
                    }
                } label: {
                    Text("Small Menu")
                }

                MenuSourceViewLink {
                    MenuGroup(order: .fixed) {
                        MenuButton {

                        } label: {
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Text("Option C")
                        }
                    }
                } label: {
                    Text("Fixed Order Menu")
                }

                MenuSourceViewLink {
                    MenuGroup(order: .priority) {
                        MenuButton {

                        } label: {
                            Text("Option A")
                        }

                        MenuButton {

                        } label: {
                            Text("Option B")
                        }

                        MenuButton {

                        } label: {
                            Text("Option C")
                        }
                    }
                } label: {
                    Text("Priority Order Menu")
                }
            }
        }
    }
}

#endif
