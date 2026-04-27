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
    public var layoutProperties: MenuElementLayoutProperties
    public var content: Content

    @inlinable
    public init(
        id: ID? = nil,
        options: MenuOptions = .init(),
        size: MenuSize = .automatic,
        order: MenuElementsOrder = .automatic,
        @MenuBuilder content: () -> Content,
        @LabelElementBuilder label: () -> LabelElement = { LabelElement() }
    ) {
        let label = label()
        self.label = label
        self.id = id
        self.options = {
            var options = options
            if label.title == nil, label.subtitle == nil, label.image == nil {
                options.insert(.displayInline)
            }
            return options
        }()
        self.size = size
        self.layoutProperties = MenuElementLayoutProperties(order: order)
        self.content = content()
    }

    public typealias Menu = MenuBuilderMenu<Self>

    public func makeUIMenuElement(context: Context) -> Menu {
        let element = content._makeUIMenuElement(context: context)
        if let menu = element as? MenuBuilderMenu<Content> {
            _updateUIMenuElement(menu, displayInline: true, context: context)
        }
        if #available(iOS 16.0, *) {
            let menu = Menu(
                title: label.title?.resolve(in: context.environment) ?? "",
                subtitle: label.subtitle?.resolve(in: context.environment),
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                options: options.toUIKit(),
                preferredElementSize: size.toUIKit(),
                children: [element]
            )
            return menu
        } else if #available(iOS 15.0, *) {
            let menu = Menu(
                title: label.title?.resolve(in: context.environment) ?? "",
                subtitle: label.subtitle?.resolve(in: context.environment),
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                options: options.toUIKit(),
                children: [element]
            )
            return menu
        } else {
            let menu = Menu(
                title: label.title?.resolve(in: context.environment) ?? "",
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                options: options.toUIKit(),
                children: [element]
            )
            return menu
        }
    }

    private func _updateUIMenuElement(_ element: UIMenu, displayInline: Bool, context: Context) {
        if displayInline {
            let options: MenuOptions = .displayInline
            element.setValue(options.toUIKit().rawValue, forKey: "options")
            if #available(iOS 16.0, *) {
                element.setValue(size.toUIKit().rawValue, forKey: "preferredElementSize")
            }
        } else {
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
        }
    }

    public func updateUIMenuElement(_ element: inout Menu, context: Context) {
        _updateUIMenuElement(element, displayInline: false, context: context)
        var updated = element.children
        if updated.count == 1, let menu = updated.first as? MenuBuilderMenu<Content> {
            _updateUIMenuElement(menu, displayInline: true, context: context)
        }
        if updated.count > 0 {
            content._updateUIMenuElement(&updated[0], context: context)
        } else {
            updated = [
                content._makeUIMenuElement(context: context)
            ]
        }
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

#endif
