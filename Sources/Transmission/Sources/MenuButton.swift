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
    public var state: State
    public var attributes: MenuElementAttributes
    public var action: @MainActor () -> Void

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
        element.state = state.toUIKit()
        element.attributes = attributes.toUIKit()
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
