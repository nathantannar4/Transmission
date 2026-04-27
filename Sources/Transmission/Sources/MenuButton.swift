//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public struct MenuButton: MenuElementRepresentable {

    @frozen
    public struct ID: Hashable, ExpressibleByStringLiteral {
        var id: UIAction.Identifier

        public init(stringLiteral value: StringLiteralType) {
            self.id = UIAction.Identifier(value)
        }

        public init(id: UIAction.Identifier) {
            self.id = id
        }

        func toUIKit() -> UIAction.Identifier {
            return id
        }
    }

    public struct Attributes: OptionSet {
        public var rawValue: UInt8
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static var disabled: Attributes { Attributes(rawValue: 1 << 0) }

        public static var destructive: Attributes { Attributes(rawValue: 1 << 1) }

        public static var hidden: Attributes { Attributes(rawValue: 1 << 2) }

        @available(iOS 16.0, *)
        public static var keepsMenuPresented: Attributes { Attributes(rawValue: 1 << 3) }

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

    public enum State {
        case off
        case on
        case mixed

        func toUIKit() -> UIAction.State {
            switch self {
            case .off:
                return .off
            case .on:
                return .on
            case .mixed:
                return .mixed
            }
        }
    }

    public var label: LabelElement
    public var id: ID?
    public var attributes: Attributes
    public var state: State
    public var action: @MainActor () -> Void

    @inlinable
    public init(
        image: Image? = nil,
        id: ID? = nil,
        attributes: Attributes = [],
        state: State = .off,
        action: @MainActor @escaping () -> Void,
        @LabelElementBuilder label: () -> LabelElement = { LabelElement() }
    ) {
        self.label = label()
        self.id = id
        self.attributes = attributes
        self.state = state
        self.action = action
    }

    public func makeUIMenuElement(context: Context) -> UIAction {
        if #available(iOS 15.0, *) {
            return UIAction(
                title: label.title?.resolve(in: context.environment) ?? "",
                subtitle: label.subtitle?.resolve(in: context.environment),
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                attributes: attributes.toUIKit(),
                state: state.toUIKit()
            ) { _ in
                action()
            }
        } else {
            return UIAction(
                title: label.title?.resolve(in: context.environment) ?? "",
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                attributes: attributes.toUIKit(),
                state: state.toUIKit()
            ) { _ in
                action()
            }
        }
    }

    public func updateUIMenuElement(_ element: inout UIAction, context: Context) {
        element.title = label.title?.resolve(in: context.environment) ?? ""
        if #available(iOS 15.0, *) {
            element.subtitle = label.subtitle?.resolve(in: context.environment)
        }
        element.image = label.image?.toUIImage(in: context.environment)
        element.attributes = attributes.toUIKit()
        element.state = state.toUIKit()
        element.handler = { _ in action() }
    }
}

extension UIAction {

    public var handler: UIActionHandler? {
        get {
            guard
                // handler
                let aSelector = NSStringFromBase64EncodedString("aGFuZGxlcg=="),
                responds(to: NSSelectorFromString(aSelector))
            else {
                return nil
            }
            return value(forKey: aSelector) as? UIActionHandler
        }
        set {
            guard
                // setHandler:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0SGFuZGxlcjo="),
                responds(to: aSelector)
            else {
                return
            }
            let newValue: @convention(block) (UIAction) -> Void = newValue ?? { _ in }
            perform(aSelector, with: newValue)
        }
    }
}


#endif
