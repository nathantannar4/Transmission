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
    public struct ID: Hashable, Sendable, ExpressibleByStringLiteral {
        var id: UIAction.Identifier

        public init(stringLiteral value: StringLiteralType) {
            self.id = UIAction.Identifier(value)
        }

        public init(rawValue value: String) {
            self.id = UIAction.Identifier(value)
        }

        public init(id: UIAction.Identifier) {
            self.id = id
        }

        func toUIKit() -> UIAction.Identifier {
            return id
        }
    }

    @frozen
    public enum Role: Equatable, Sendable {
        case confirm
        case cancel
    }

    @frozen
    public enum State: Sendable {
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
    public var role: Role?
    public var state: State
    public var attributes: MenuElementAttributes
    public var action: (@MainActor () -> Void)?

    @_disfavoredOverload
    @inlinable
    public init(
        role: Role,
        attributes: MenuElementAttributes = [],
        action: (@MainActor () -> Void)? = nil,
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.label = label()
        self.role = role
        self.state = .off
        self.attributes = attributes
        self.action = action
    }

    @inlinable
    public init(
        id: ID? = nil,
        state: State = .off,
        attributes: MenuElementAttributes = [],
        action: @MainActor @escaping () -> Void,
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.label = label()
        self.id = id
        self.state = state
        self.attributes = attributes
        self.action = action
    }

    @inlinable
    public init(
        id: ID? = nil,
        isSelected: Bool,
        attributes: MenuElementAttributes = [.prefersKeepsMenuPresented],
        action: @MainActor @escaping () -> Void,
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.init(
            id: id,
            state: isSelected ? .on : .off,
            attributes: attributes,
            action: action,
            label: label
        )
    }

    public func makeUIMenuElement(
        context: Context
    ) -> UIAction {
        if #available(iOS 15.0, *) {
            return UIAction(
                title: label.title?.resolve(in: context.environment) ?? "",
                subtitle: label.subtitle?.resolve(in: context.environment),
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                attributes: attributes.toUIKit(),
                state: state.toUIKit()
            ) { _ in
                action?()
            }
        } else {
            return UIAction(
                title: label.title?.resolve(in: context.environment) ?? "",
                image: label.image?.toUIImage(in: context.environment),
                identifier: id?.toUIKit(),
                attributes: attributes.toUIKit(),
                state: state.toUIKit()
            ) { _ in
                action?()
            }
        }
    }

    public func updateUIMenuElement(
        _ element: inout UIAction,
        context: Context
    ) {
        element.title = label.title?.resolve(in: context.environment) ?? ""
        if #available(iOS 16.0, *) {
            element.subtitle = label.subtitle?.resolve(in: context.environment)
        } else if #available(iOS 15.0, *), element.responds(to: NSSelectorFromString("setSubtitle:")) {
            let subtitle = label.subtitle?.resolve(in: context.environment)
            element.setValue(subtitle, forKey: "subtitle")
        }
        element.image = label.image?.toUIImage(in: context.environment)
        element.state = state.toUIKit()
        element.attributes = attributes.toUIKit()
        element.handler = { _ in action?() }
    }

    public func _updateUIAlertController(
        _ alert: UIAlertController,
        context: Context
    ) {
        guard !attributes.contains(.hidden) else { return }
        let element = UIAlertAction(
            title: label.title?.resolve(in: context.environment),
            style: {
                if role == nil, attributes.contains(.destructive) {
                    return .destructive
                } else if role == .cancel, alert.preferredStyle != .actionSheet {
                    return .cancel
                }
                return .default
            }(),
            handler: action.map({ action in return { _ in action() } })
        )
        if let image = label.image?.toUIImage(in: context.environment),
            // setImage:
            let aSelector = NSSelectorFromBase64EncodedString("c2V0SW1hZ2U6"),
            element.responds(to: aSelector)
        {
            element.perform(aSelector, with: image)
        }
        element.isEnabled = !attributes.contains(.disabled)
        alert.addAction(element)
        if alert.preferredAction == nil, role == .confirm {
            alert.preferredAction = element
        }
    }
}

@available(iOS 14.0, *)
extension MenuButton {

    public func disabled(_ disabled: Bool) -> MenuButton {
        var copy = self
        if disabled {
            copy.attributes.formUnion(.disabled)
        } else {
            copy.attributes.subtract(.disabled)
        }
        return copy
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

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isSelected = false

        var body: some View {
            MenuSourceViewLink {
                MenuButton(
                    isSelected: isSelected
                ) {
                    withAnimation {
                        isSelected.toggle()
                    }
                } label: {
                    Text("isSelected")
                }

                MenuButton(
                    isSelected: !isSelected
                ) {
                    withAnimation {
                        isSelected.toggle()
                    }
                } label: {
                    Text("!isSelected")
                }

                MenuButton(
                    state: .mixed,
                    attributes: .disabled
                ) {

                } label: {
                    Image(systemName: "info.triangle")
                    Text("Title")
                    Text("Subtitle")
                }

                MenuButton(
                    attributes: .destructive
                ) {

                } label: {
                    Image(systemName: "trash")
                    Text("Delete")
                }
            } label: {
                Text("Menu")
            }
        }
    }
}

#endif
