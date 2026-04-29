//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
@frozen
public struct MenuIdentifier: Hashable, ExpressibleByStringLiteral {

    public var id: UIMenu.Identifier

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.id = UIMenu.Identifier(value)
    }

    @inlinable
    public init(rawValue value: String) {
        self.id = UIMenu.Identifier(value)
    }

    @inlinable
    public init(id: UIMenu.Identifier) {
        self.id = id
    }

    func toUIKit() -> UIMenu.Identifier {
        return id
    }
}

@available(iOS 14.0, *)
@frozen
public struct MenuOptions: OptionSet {
    public var rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Show children inline in parent, instead of hierarchically
    public static let displayInline = MenuOptions(rawValue: 1 << 0)

    /// Indicates whether the menu should be rendered with a destructive appearance in its parent
    public static let destructive = MenuOptions(rawValue: 1 << 1)

    /// Indicates whether the menu (and any submenus) should only allow a single "on" menu item.
    @available(iOS 15.0, *)
    public static let singleSelection = MenuOptions(rawValue: 1 << 2)

    /// Indicates that this menu should be rendered as a palette.
    @available(iOS 17.0, *)
    public static let displayAsPalette = MenuOptions(rawValue: 1 << 3)

    func toUIKit() -> UIMenu.Options {
        var options = UIMenu.Options()
        if contains(.displayInline) { options.insert(.displayInline) }
        if contains(.destructive) { options.insert(.destructive) }
        if #available(iOS 15.0, *) {
            if contains(.singleSelection) { options.insert(.singleSelection) }
        }
        if #available(iOS 17.0, *) {
            if contains(.displayAsPalette) { options.insert(.displayAsPalette) }
        }
        return options
    }
}

@available(iOS 14.0, *)
@frozen
public struct MenuDisplayPreferences {

    @usableFromInline
    var preferredLineLimit: Int?

    @available(iOS 17.4, *)
    public var lineLimit: Int? {
        get { preferredLineLimit }
        set { preferredLineLimit = newValue }
    }

    @inlinable
    public init(
        preferredLineLimit: Int? = nil
    ) {
        self.preferredLineLimit = preferredLineLimit
    }
}

@frozen
public struct MenuSize {
    @usableFromInline
    enum Value {
        case small
        case medium
        case large
        case automatic
    }
    @usableFromInline
    var value: Value

    @available(iOS 16.0, *)
    public static var small: MenuSize {
        MenuSize(value: .small)
    }

    @available(iOS 16.0, *)
    public static var medium: MenuSize {
        MenuSize(value: .medium)
    }

    @available(iOS 16.0, *)
    public static var large: MenuSize {
        MenuSize(value: .large)
    }

    /// Automatically determine the appropriate element size for the current context.
    public static var automatic: MenuSize {
        MenuSize(value: .automatic)
    }

    @available(iOS, deprecated: 16.0, renamed: "small")
    public static var prefersSmall: MenuSize {
        if #available(iOS 16.0, *) {
            return .small
        }
        return .automatic
    }

    @available(iOS, deprecated: 16.0, renamed: "medium")
    public static var prefersMedium: MenuSize {
        if #available(iOS 16.0, *) {
            return .medium
        }
        return .automatic
    }

    @available(iOS, deprecated: 16.0, renamed: "large")
    public static var prefersLarge: MenuSize {
        if #available(iOS 16.0, *) {
            return .large
        }
        return .automatic
    }

    @available(iOS 16.0, *)
    func toUIKit() -> UIMenu.ElementSize {
        switch value {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .automatic:
            if #available(iOS 17.0, *) {
                return .automatic
            }
            return .large
        }
    }
}

@frozen
@available(iOS 14.0, *)
public struct MenuGroup<Content: MenuElement>: MenuElementRepresentable {

    public typealias ID = MenuIdentifier

    public var label: LabelElement
    public var id: ID?
    public var options: MenuOptions
    public var size: MenuSize
    public var displayPreferences: MenuDisplayPreferences
    public var layoutProperties: MenuElementLayoutProperties
    public var content: Content

    @inlinable
    public init(
        id: ID? = nil,
        options: MenuOptions = [],
        size: MenuSize = .automatic,
        displayPreferences: MenuDisplayPreferences = MenuDisplayPreferences(),
        order: MenuElementsOrder = .automatic,
        @MenuBuilder content: () -> Content,
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.label = label()
        self.id = id
        self.options = options
        self.size = size
        self.displayPreferences = displayPreferences
        self.layoutProperties = MenuElementLayoutProperties(order: order)
        self.content = content()
    }

    @inlinable
    public init(
        id: ID? = nil,
        options: MenuOptions = [.displayInline],
        size: MenuSize = .automatic,
        displayPreferences: MenuDisplayPreferences = MenuDisplayPreferences(),
        order: MenuElementsOrder = .automatic,
        @MenuBuilder content: () -> Content
    ) {
        self.init(
            id: id,
            options: options,
            size: size,
            displayPreferences: displayPreferences,
            order: order,
            content: content,
            label: { }
        )
    }

    public typealias Menu = MenuBuilderMenu<Self>

    public func makeUIMenuElement(context: Context) -> Menu {
        let children = content._makeUIMenuElements(context: context)
        let menu: Menu
        if #available(iOS 16.0, *) {
            menu = Menu(
                title: label.title?.resolve(in: context.environment) ?? "",
                subtitle: label.subtitle?.resolve(in: context.environment),
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                options: options.toUIKit(),
                preferredElementSize: size.toUIKit(),
                children: children
            )
        } else if #available(iOS 15.0, *) {
            menu = Menu(
                title: label.title?.resolve(in: context.environment) ?? "",
                subtitle: label.subtitle?.resolve(in: context.environment),
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                options: options.toUIKit(),
                children: children
            )
        } else {
            menu = Menu(
                title: label.title?.resolve(in: context.environment) ?? "",
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                options: options.toUIKit(),
                children: children
            )
        }
        if #available(iOS 17.4, *) {
            let preferences = UIMenuDisplayPreferences()
            preferences.maximumNumberOfTitleLines = displayPreferences.lineLimit ?? 0
            menu.displayPreferences = preferences
        }
        return menu
    }

    public func updateUIMenuElement(_ element: inout Menu, context: Context) {
        if let id {
            element.setValue(id.toUIKit(), forKey: "identifier")
        }
        element.setValue(label.title?.resolve(in: context.environment) ?? "", forKey: "title")
        if #available(iOS 15.0, *) {
            element.setValue(label.subtitle?.resolve(in: context.environment), forKey: "subtitle")
        }
        element.setValue(label.image?.toUIImage(in: context.environment), forKey: "image")
        element.setValue(options.toUIKit().rawValue, forKey: "options")
        if #available(iOS 16.0, *) {
            element.setValue(size.toUIKit().rawValue, forKey: "preferredElementSize")
        }
        if #available(iOS 17.4, *) {
            element.displayPreferences?.maximumNumberOfTitleLines = displayPreferences.lineLimit ?? 0
        }

        var updated = element.children
        content._updateUIMenuElements(&updated, context: context)
        element = element.replacingChildren(updated) as! Menu
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        if var updated = menu as? Menu, menu.identifier.rawValue.hasPrefix("com.apple.menu.dynamic") || id?.toUIKit() == menu.identifier {
            updateUIMenuElement(&updated, context: context)
            menu = updated
            stop = true
        } else {
            content._updateVisibleUIMenu(&menu, context: context, stop: &stop)
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuGroup_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isLarge = false

        @MenuBuilder
        var options: some MenuElement {
            MenuButton(isSelected: !isLarge) {
                withAnimation {
                    isLarge = false
                }
            } label: {
                Image(systemName: "textformat.size.smaller")
                Text("Small")
            }

            MenuButton(isSelected: isLarge) {
                withAnimation {
                    isLarge = true
                }
            } label: {
                Image(systemName: "textformat.size.larger")
                Text("Large")
            }
        }

        var body: some View {
            MenuSourceViewLink {
                MenuGroup(options: .displayInline, size: .prefersSmall) {
                    options
                } label: {
                    Text("Options")
                }

                MenuGroup(options: .displayInline, size: .prefersMedium) {
                    options
                } label: {
                    Text("Options")
                }

                MenuGroup(options: .displayInline, size: .prefersLarge) {
                    options
                } label: {
                    Text("Options")
                }

                MenuGroup {
                    MenuButton {

                    } label: {
                        Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat.")
                    }
                }

                MenuGroup {
                    MenuButton {

                    } label: {
                        Text("Action")
                    }
                } label: {
                    Image(systemName: "character.text.justify")
                    Text("More")
                }
            } label: {
                Text("Menu")
            }
        }
    }
}

#endif
