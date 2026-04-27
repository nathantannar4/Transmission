//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public protocol MenuElementRepresentable: PrimitiveMenuElement {

    associatedtype UIMenuElementType: UIMenuElement

    @MainActor @preconcurrency func makeUIMenuElement(context: Context) -> UIMenuElementType
    @MainActor @preconcurrency func updateUIMenuElement(_ element: inout UIMenuElementType, context: Context)

    typealias Context = MenuRepresentableContext
}

@available(iOS 14.0, *)
extension MenuElementRepresentable {

    public func _makeUIMenuElement(context: MenuRepresentableContext) -> UIMenuElement {
        makeUIMenuElement(context: context)
    }

    public func _updateUIMenuElement(_ element: inout UIMenuElement, context: MenuRepresentableContext) {
        if var updated = element as? UIMenuElementType {
            updateUIMenuElement(&updated, context: context)
            element = updated
        } else {
            element = makeUIMenuElement(context: context)
        }
    }
}

@available(iOS 14.0, *)
extension MenuElementRepresentable where UIMenuElementType: UIMenu {

    public func _makeUIMenu(context: MenuRepresentableContext) -> UIMenu {
        return makeUIMenuElement(context: context)
    }

    public func _updateUIMenu(_ menu: inout UIMenu, context: MenuRepresentableContext) {
        var updated = menu as! UIMenuElementType
        updateUIMenuElement(&updated, context: context)
        menu = updated
    }

    public func _updateVisibleUIMenu(_ menu: inout UIMenu, context: Context, stop: inout Bool) {
        if var updated = menu as? UIMenuElementType {
            updateUIMenuElement(&updated, context: context)
            menu = updated
            stop = true
        }
    }
}

#endif
