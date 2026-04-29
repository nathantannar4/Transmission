//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import os.log
import Engine

@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol MenuElement {

    associatedtype Body: MenuElement
    @MenuBuilder @MainActor @preconcurrency var body: Body { get }

    @MainActor @preconcurrency func _makeUIMenuElement(context: Context) -> UIMenuElement
    @MainActor @preconcurrency func _updateUIMenuElement(_ element: inout UIMenuElement, context: Context)

    @MainActor @preconcurrency func _makeUIMenuElementsCount() -> Int?
    @MainActor @preconcurrency func _makeUIMenuElements(context: Context) -> [UIMenuElement]
    @MainActor @preconcurrency func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context)

    @MainActor @preconcurrency func _makeUIMenu(context: Context) -> UIMenu
    @MainActor @preconcurrency func _updateUIMenu(_ menu: inout UIMenu, context: Context)
    @MainActor @preconcurrency func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool)

    typealias Context = MenuRepresentableContext

    @MainActor @preconcurrency var layoutProperties: MenuElementLayoutProperties { get }
}

@available(iOS 14.0, *)
public enum MenuElementsOrder {

    /// The default order
    case automatic

    /// Allows the system to choose the appropriate ordering strategy for the current context.
    @available(iOS 16.0, *)
    case priority

    /// Order menu elements according to priority. Keeping the first element in the menu closest to user's interaction point.
    @available(iOS 16.0, *)
    case fixed
}

public struct MenuElementAttributes: OptionSet {

    public var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static var disabled: MenuElementAttributes { MenuElementAttributes(rawValue: 1 << 0) }

    public static var destructive: MenuElementAttributes { MenuElementAttributes(rawValue: 1 << 1) }

    public static var hidden: MenuElementAttributes { MenuElementAttributes(rawValue: 1 << 2) }

    @available(iOS 16.0, *)
    public static var keepsMenuPresented: MenuElementAttributes { MenuElementAttributes(rawValue: 1 << 3) }

    @available(iOS, deprecated: 16.0, renamed: "keepsMenuPresented")
    public static var prefersKeepsMenuPresented: MenuElementAttributes {
        if #available(iOS 16.0, *) {
            return .keepsMenuPresented
        }
        return []
    }

    func toUIKit() -> UIMenuElement.Attributes {
        var attributes = UIMenuElement.Attributes()
        if contains(.disabled) { attributes.insert(.disabled) }
        if contains(.destructive) { attributes.insert(.destructive) }
        if contains(.hidden) { attributes.insert(.hidden) }
        if #available(iOS 16.0, *) {
            if contains(.keepsMenuPresented) { attributes.insert(.keepsMenuPresented) }
        }
        return attributes
    }
}

@frozen
@available(iOS 14.0, *)
public struct MenuElementLayoutProperties {
    public var order: MenuElementsOrder

    @inlinable
    public init(order: MenuElementsOrder) {
        self.order = order
    }
}

@frozen
@available(iOS 14.0, *)
public struct MenuRepresentableContext {
    public var transaction: Transaction
    public var environment: EnvironmentValues
}

@available(iOS 14.0, *)
extension MenuElement {

    public func _makeUIMenuElement(context: MenuRepresentableContext) -> UIMenuElement {
        body._makeUIMenuElement(context: context)
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: MenuRepresentableContext) {
        body._updateUIMenuElement(&element, context: context)
    }

    public func _makeUIMenuElementsCount() -> Int? {
        body._makeUIMenuElementsCount()
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        body._makeUIMenuElements(context: context)
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        body._updateUIMenuElements(&elements, context: context)
    }

    public func _makeUIMenu(context: MenuRepresentableContext) -> UIMenu {
        body._makeUIMenu(context: context)
    }

    public func _updateUIMenu(_ menu: inout UIMenu, context: MenuRepresentableContext) {
        body._updateUIMenu(&menu, context: context)
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        body._updateVisibleUIMenu(&menu, context: context, stop: &stop)
    }

    public func makeUIMenu(context: Context) -> UIMenu {
        return _makeUIMenu(context: context)
    }

    public func updateVisibleUIMenu(_ menu: inout UIMenu, context: Context) {
        var stop = false
        _updateVisibleUIMenu(&menu, context: context, stop: &stop)
        if !stop {
            os_log(.error, log: .default, "Failed to update visible menu %{public}@. Please file an issue.", String(describing: Self.self))
        }
    }

    public var layoutProperties: MenuElementLayoutProperties {
        MenuElementLayoutProperties(order: .automatic)
    }
}

/// Don't use directly, instead use `MenuElement`,`MenuElementRepresentable` or `MenuRepresentable`
@available(iOS 14.0, *)
public protocol PrimitiveMenuElement: MenuElement where Body == Never {

    typealias Context = MenuRepresentableContext
}


@available(iOS 14.0, *)
extension PrimitiveMenuElement {

    @_transparent
    public var body: Never {
        fatalError("body() should not be called on \(String(describing: Self.self))")
    }

    public func _makeUIMenuElement(context: MenuRepresentableContext) -> UIMenuElement {
        _makeUIMenu(context: context)
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: MenuRepresentableContext) {
        if var updated = element as? UIMenu {
            _updateUIMenu(&updated, context: context)
            element = updated
        } else {
            element = _makeUIMenuElement(context: context)
        }
    }

    public func _makeUIMenuElementsCount() -> Int? {
        return 1
    }

    public typealias Menu = MenuBuilderMenu<Self>

    public func _makeUIMenu(context: MenuRepresentableContext) -> UIMenu {
        let children = _makeUIMenuElements(context: context)
        return Menu(inline: children)
    }

    public func _updateUIMenu(_ menu: inout UIMenu, context: MenuRepresentableContext) {
        if menu is Menu {
            var updated = menu.children
            _updateUIMenuElements(&updated, context: context)
            menu = menu.replacingChildren(updated)
        } else {
            menu = _makeUIMenu(context: context)
        }
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        if menu is Menu {
            _updateUIMenu(&menu, context: context)
            stop = true
        }
    }
}

@available(iOS 14.0, *)
extension Never: PrimitiveMenuElement { }

@available(iOS 14.0, *)
@frozen
public struct EmptyMenuElement: PrimitiveMenuElement {

    public func _makeUIMenuElement(context: MenuRepresentableContext) -> UIMenuElement {
        MenuBuilderEmptyElement()
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: MenuRepresentableContext) {
        if !(element is MenuBuilderEmptyElement) {
            element = MenuBuilderEmptyElement()
        }
    }

    public func _makeUIMenuElementsCount() -> Int? {
        return 1
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        return [
            MenuBuilderEmptyElement()
        ]
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        if elements.count != 1 || !(elements.first is MenuBuilderEmptyElement) {
            elements = [
                MenuBuilderEmptyElement()
            ]
        }
    }
}

@available(iOS 14.0, *)
@frozen
public struct MenuElementsCollection<
    Element: MenuElement
>: PrimitiveMenuElement {

    public var values: [Element]

    @inlinable
    public init(values: [Element]) {
        self.values = values
    }

    public typealias Menu = MenuBuilderMenu<Self>

    public func _makeUIMenuElement(context: Context) -> Menu {
        let children = _makeUIMenuElements(context: context)
        return Menu(inline: children)
    }

    public func _updateUIMenuElement(_ element: inout Menu, context: Context) {
        var updated = element.children
        _updateUIMenuElements(&updated, context: context)
        element = element.replacingChildren(updated) as! Menu
    }

    public func _makeUIMenuElementsCount() -> Int? {
        return values.count
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        let children = values.map { $0._makeUIMenuElement(context: context) }
        return children
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        var index = 0
        for value in values {
            if let count = value._makeUIMenuElementsCount() {
                let endIndex = index + count
                if elements.count >= endIndex {
                    var updated = Array(elements[index..<endIndex])
                    value._updateUIMenuElements(&updated, context: context)
                    elements.replaceSubrange(index..<endIndex, with: updated)
                } else {
                    let updated = value._makeUIMenuElements(context: context)
                    elements.replaceSubrange(index..<min(elements.endIndex, endIndex), with: [])
                    elements.append(contentsOf: updated)
                }
                index += count
            } else {
                if elements.count > index {
                    value._updateUIMenuElement(&elements[index], context: context)
                } else {
                    let element = value._makeUIMenuElement(context: context)
                    elements.append(element)
                }
                index += 1
            }
        }
        elements.removeLast(elements.count - index)
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        if var updated = menu as? Menu {
            _updateUIMenuElement(&updated, context: context)
            menu = updated
            stop = true
        } else {
            for value in values {
                value._updateVisibleUIMenu(&menu, context: context, stop: &stop)
                if stop {
                    break
                }
            }
        }
    }
}

@available(iOS 14.0, *)
@frozen
public struct MenuElementsTuple<
    Elements
>: PrimitiveMenuElement {

    public var children: Tuple<Elements>

    @inlinable
    public init(
        children: Elements
    ) {
        self.children = Tuple(children)!
    }

    public typealias Menu = MenuBuilderMenu<Self>

    public func _makeUIMenuElement(context: Context) -> Menu {
        let children = _makeUIMenuElements(context: context)
        return Menu(inline: children)
    }

    public func _updateUIMenuElement(_ element: inout Menu, context: Context) {
        var updated = element.children
        _updateUIMenuElements(&updated, context: context)
        element = element.replacingChildren(updated) as! Menu
    }

    public func _makeUIMenuElementsCount() -> Int? {
        return children.count
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        var visitor = ElementsVisitor(elements: [], context: context)
        children.visit(visitor: &visitor)
        return visitor.elements
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        var visitor = ElementsVisitor(elements: elements, context: context)
        children.visit(visitor: &visitor)
        elements = visitor.elements
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        if var updated = menu as? Menu {
            _updateUIMenuElement(&updated, context: context)
            menu = updated
            stop = true
        } else {
            var visitor = VisibleMenuVisitor(menu: menu, context: context)
            children.visit(visitor: &visitor)
            menu = visitor.menu
            stop = visitor.didUpdate
        }
    }

    @MainActor
    private struct ElementsVisitor: @preconcurrency TupleVisitor {
        var elements: [UIMenuElement]
        var context: MenuRepresentableContext
        var index = 0

        mutating func visit<Element>(element: Element, offset: Offset, stop: inout Bool) {
            guard let element = element as? any MenuElement else { return }
            func project<T: MenuElement>(_ element: T) {
                if let count = element._makeUIMenuElementsCount() {
                    let endIndex = index + count
                    if elements.count >= endIndex {
                        var updated = Array(elements[index..<endIndex])
                        element._updateUIMenuElements(&updated, context: context)
                        elements.replaceSubrange(index..<endIndex, with: updated)
                    } else {
                        let updated = element._makeUIMenuElements(context: context)
                        elements.replaceSubrange(index..<min(elements.endIndex, endIndex), with: [])
                        elements.append(contentsOf: updated)
                    }
                    index += count
                } else {
                    if elements.count > index {
                        element._updateUIMenuElement(&elements[index], context: context)
                    } else {
                        let element = element._makeUIMenuElement(context: context)
                        elements.append(element)
                    }
                    index += 1
                }
            }
            _openExistential(element, do: project)
            if stop {
                elements.removeLast(elements.count - index)
            }
        }
    }

    @MainActor
    private struct VisibleMenuVisitor: @preconcurrency TupleVisitor {
        var menu: UIMenu
        var context: MenuRepresentableContext
        var didUpdate = false

        mutating func visit<Element>(element: Element, offset: Offset, stop: inout Bool) {
            guard let element = element as? any MenuElement else { return }
            element._updateVisibleUIMenu(&menu, context: context, stop: &didUpdate)
            stop = didUpdate
        }
    }
}

@available(iOS 14.0, *)
extension ConditionalContent: MenuElement, PrimitiveMenuElement where TrueContent: MenuElement, FalseContent: MenuElement {

    public func _makeUIMenuElement(context: Context) -> UIMenuElement {
        switch storage {
        case .trueContent(let content):
            return content._makeUIMenuElement(context: context)
        case .falseContent(let content):
            return content._makeUIMenuElement(context: context)
        }
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: Context) {
        switch storage {
        case .trueContent(let content):
            content._updateUIMenuElement(&element, context: context)
        case .falseContent(let content):
            content._updateUIMenuElement(&element, context: context)
        }
    }

    public func _makeUIMenuElementsCount() -> Int? {
        switch storage {
        case .trueContent(let content):
            return content._makeUIMenuElementsCount()
        case .falseContent(let content):
            return content._makeUIMenuElementsCount()
        }
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        switch storage {
        case .trueContent(let content):
            return content._makeUIMenuElements(context: context)
        case .falseContent(let content):
            return content._makeUIMenuElements(context: context)
        }
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        switch storage {
        case .trueContent(let content):
            if let count = content._makeUIMenuElementsCount(), count != elements.count {
                elements = content._makeUIMenuElements(context: context)
            } else {
                content._updateUIMenuElements(&elements, context: context)
            }
        case .falseContent(let content):
            if let count = content._makeUIMenuElementsCount(), count != elements.count {
                elements = content._makeUIMenuElements(context: context)
            } else {
                content._updateUIMenuElements(&elements, context: context)
            }
        }
    }

    public func _makeUIMenu(context: Context) -> UIMenu {
        switch storage {
        case .trueContent(let content):
            return content._makeUIMenu(context: context)
        case .falseContent(let content):
            return content._makeUIMenu(context: context)
        }
    }

    public func _updateUIMenu(_ menu: inout UIMenu, context: Context) {
        switch storage {
        case .trueContent(let content):
            content._updateUIMenu(&menu, context: context)
        case .falseContent(let content):
            content._updateUIMenu(&menu, context: context)
        }
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        switch storage {
        case .trueContent(let content):
            content._updateVisibleUIMenu(&menu, context: context, stop: &stop)
        case .falseContent(let content):
            content._updateVisibleUIMenu(&menu, context: context, stop: &stop)
        }
    }
}

@available(iOS 14.0, *)
extension Optional: MenuElement, PrimitiveMenuElement where Wrapped: MenuElement {

    public func _makeUIMenuElement(context: Context) -> UIMenuElement {
        switch self {
        case .none:
            return MenuBuilderEmptyElement()
        case .some(let content):
            return content._makeUIMenuElement(context: context)
        }
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: Context) {
        switch self {
        case .none:
            if !(element is MenuBuilderEmptyElement) {
                element = MenuBuilderEmptyElement()
            }
        case .some(let content):
            content._updateUIMenuElement(&element, context: context)
        }
    }

    public func _makeUIMenuElementsCount() -> Int? {
        switch self {
        case .none:
            return 1
        case .some(let content):
            return content._makeUIMenuElementsCount()
        }
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        switch self {
        case .none:
            return [
                MenuBuilderEmptyElement()
            ]
        case .some(let content):
            return content._makeUIMenuElements(context: context)
        }
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        switch self {
        case .none:
            if elements.count != 1 || !(elements.first is MenuBuilderEmptyElement) {
                elements = [
                    MenuBuilderEmptyElement()
                ]
            }
        case .some(let content):
            if let count = content._makeUIMenuElementsCount(), count != elements.count {
                elements = content._makeUIMenuElements(context: context)
            } else {
                content._updateUIMenuElements(&elements, context: context)
            }
        }
    }

    public func _makeUIMenu(context: Context) -> UIMenu {
        switch self {
        case .none:
            return MenuBuilderMenu<Self>()
        case .some(let content):
            return content._makeUIMenu(context: context)
        }
    }

    public func _updateUIMenu(_ menu: inout UIMenu, context: Context) {
        switch self {
        case .none:
            if !menu.children.isEmpty {
                menu = menu.replacingChildren([])
            }
        case .some(let content):
            content._updateUIMenu(&menu, context: context)
        }
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        switch self {
        case .none:
            break
        case .some(let content):
            content._updateVisibleUIMenu(&menu, context: context, stop: &stop)
        }
    }
}

@available(iOS 14.0, *)
@frozen
public struct AnyMenuElement: PrimitiveMenuElement {

    @usableFromInline
    var makeMenuElement: @MainActor (Context) -> UIMenuElement

    @usableFromInline
    var updateMenuElement: @MainActor (inout UIMenuElement, Context) -> Void

    @usableFromInline
    var makeMenuElementsCount: @MainActor () -> Int?

    @usableFromInline
    var makeMenuElements: @MainActor (Context) -> [UIMenuElement]

    @usableFromInline
    var updateMenuElements: @MainActor (inout [UIMenuElement], Context) -> Void

    @usableFromInline
    var makeMenu: @MainActor (Context) -> UIMenu

    @usableFromInline
    var updateMenu: @MainActor (inout UIMenu, Context) -> Void

    @usableFromInline
    var updateVisibleMenu: @MainActor (inout UIMenu, Context, inout Bool) -> Void

    @inlinable
    public init<Element: MenuElement>(_ element: Element) {
        let box = Box(element)
        makeMenuElement = { box.value._makeUIMenuElement(context: $0) }
        updateMenuElement = { box.value._updateUIMenuElement(&$0, context: $1) }
        makeMenuElementsCount = { box.value._makeUIMenuElementsCount() }
        makeMenuElements = { box.value._makeUIMenuElements(context: $0) }
        updateMenuElements = { box.value._updateUIMenuElements(&$0, context: $1) }
        makeMenu = { box.value._makeUIMenu(context: $0, ) }
        updateMenu = { box.value._updateUIMenu(&$0, context: $1) }
        updateVisibleMenu = { box.value._updateVisibleUIMenu(&$0, context: $1, stop: &$2)}
    }

    public func _makeUIMenuElement(context: Context) -> UIMenuElement {
        makeMenuElement(context)
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: Context) {
        updateMenuElement(&element, context)
    }

    public func _makeUIMenuElementsCount() -> Int? {
        makeMenuElementsCount()
    }

    public func _makeUIMenuElements(context: Context) -> [UIMenuElement] {
        makeMenuElements(context)
    }

    public func _updateUIMenuElements(_ elements: inout [UIMenuElement], context: Context) {
        updateMenuElements(&elements, context)
    }

    public func _makeUIMenu(context: Context) -> UIMenu {
        makeMenu(context)
    }

    public func _updateUIMenu(_ menu: inout UIMenu, context: Context) {
        updateMenu(&menu, context)
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        updateVisibleMenu(&menu, context, &stop)
    }

    @usableFromInline
    struct Box<Value: MenuElement>: @unchecked Sendable {
        @usableFromInline
        var value: Value
        @usableFromInline
        init(_ value: Value) { self.value = value }
    }
}

@available(iOS 14.0, *)
extension ForEach {

    @MainActor
    public init<
        Menu: MenuElement
    >(
        _ data: Data,
        @MenuBuilder content: @escaping (Data.Element) -> Menu
    ) where Data.Element: Identifiable, ID == Data.Element.ID, Content == ForEachMenuElement<Menu>  {
        self.init(data) { element in
            let menu = content(element)
            ForEachMenuElement(menu: menu)
        }
    }

    @MainActor
    public init<
        Menu: MenuElement
    >(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @MenuBuilder content: @escaping (Data.Element) -> Menu
    ) where Content == ForEachMenuElement<Menu>  {
        self.init(data, id: id) { element in
            let menu = content(element)
            ForEachMenuElement(menu: menu)
        }
    }
}

/// Don't use directly, only for `ForEach` support in `MenuBuilder`
@available(iOS 14.0, *)
public struct ForEachMenuElement<Menu: MenuElement>: View {
    public var menu: Menu

    public var body: some View {
        EmptyView()
    }
}

@available(iOS 14.0, *)
@resultBuilder
@MainActor @preconcurrency
public struct MenuBuilder {

    public static func buildBlock() -> EmptyMenuElement {
        EmptyMenuElement()
    }

    public static func buildPartialBlock(
        first: Void
    ) -> EmptyMenuElement { EmptyMenuElement() }

    public static func buildPartialBlock(
        first: Never
    ) -> EmptyMenuElement { }

    public static func buildExpression<Element: MenuElement>(
        _ element: Element
    ) -> Element {
        element
    }

    public static func buildBlock<Element: MenuElement>(
        _ element: Element
    ) -> Element {
        element
    }

    @_disfavoredOverload
    public static func buildBlock<each Element: MenuElement>(
        _ element: repeat each Element
    ) -> MenuElementsTuple<(repeat each Element)> {
        MenuElementsTuple(children: (repeat each element))
    }

    public static func buildOptional<Element: MenuElement>(
        _ element: Element?
    ) -> Element? {
        element
    }

    public static func buildEither<TrueElement: MenuElement, FalseElement: MenuElement>(
        first: TrueElement
    ) -> ConditionalContent<TrueElement, FalseElement> {
        ConditionalContent(first)
    }

    public static func buildEither<TrueElement: MenuElement, FalseElement: MenuElement>(
        second: FalseElement
    ) -> ConditionalContent<TrueElement, FalseElement> {
        ConditionalContent(second)
    }

    public static func buildArray<Element: MenuElement>(
        _ elements: [Element]
    ) -> MenuElementsCollection<Element> {
        MenuElementsCollection(values: elements)
    }

    public static func buildExpression<Data: RandomAccessCollection, ID: Hashable, Element: MenuElement>(
           _ element: ForEach<Data, ID, ForEachMenuElement<Element>>
       ) -> MenuElementsCollection<Element> {
           MenuElementsCollection(values: element.data.map({ element.content($0).menu }))
       }

    public static func buildLimitedAvailability<Element: MenuElement>(
        _ element: Element
    ) -> AnyMenuElement {
        AnyMenuElement(element)
    }
}

@available(iOS 14.0, *)
public class MenuBuilderMenu<Children: MenuElement>: UIMenu {

    public convenience init(inline children: [UIMenuElement]) {
        self.init(options: .displayInline, children: children)
    }
}

public class MenuBuilderEmptyElement: UIAction {
    public convenience init() {
        self.init(attributes: .hidden, handler: { _ in })
    }
}

extension UIMenu {

    @available(iOS 16.0, *)
    public static func headerView<Content: View>(
        content: Content,
        safeAreaInsets: EdgeInsets = {
            if #available(iOS 26.0, *) {
                return EdgeInsets(top: 16, leading: 28, bottom: 2, trailing: 28)
            }
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }(),
    ) -> UIView {
        let hostingView = HostingView(
            content: MenuElementViewBody(
                content: content,
                safeAreaInsets: safeAreaInsets
            )
        )
        return hostingView
    }

    @available(iOS 16.0, *)
    public var headerView: UIView? {
        get {
            guard
                // headerViewProvider
                let aSelector = NSStringFromBase64EncodedString("aGVhZGVyVmlld1Byb3ZpZGVy"),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector)
            else {
                return nil
            }
            typealias Provider = @convention(block) () -> UIView
            let provider = unsafeBitCast(value, to: Provider.self)
            return provider()
        }
        set {
            guard
                // setHeaderViewProvider:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0SGVhZGVyVmlld1Byb3ZpZGVyOg=="),
                responds(to: aSelector)
            else {
                return
            }
            if let newValue {
                let provider: @convention(block) () -> UIView = { newValue }
                perform(aSelector, with: provider)
            } else {
                perform(aSelector, with: nil)
            }
        }
    }

    @available(iOS 14.0, *)
    @discardableResult
    func update<Menu: MenuElement>(_ menu: Menu, context: MenuRepresentableContext) -> UIMenu {
        var updated = self
        CATransaction.begin()
        CATransaction.setDisableActions(!context.transaction.isAnimated)
        menu.updateVisibleUIMenu(&updated, context: context)
        CATransaction.commit()
        return updated
    }
}

@available(iOS 14.0, *)
extension UIContextMenuInteraction {

    func update<Menu: MenuElement>(_ menu: Menu, context: MenuRepresentableContext) {
        CATransaction.begin()
        CATransaction.setDisableActions(!context.transaction.isAnimated)
        updateVisibleMenu({ visibleMenu in
            var updated = visibleMenu
            menu.updateVisibleUIMenu(&updated, context: context)
            return updated
        })
        CATransaction.commit()
    }
}

// MARK: - Previews

#endif
