//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public struct MenuPickerOption<Selection: Hashable>: MenuElement {

    public var option: Selection
    public var selection: Binding<Selection?>
    public var attributes: MenuElementAttributes
    public var label: LabelElement

    @inlinable
    public init(
        option: Selection,
        selection: Binding<Selection?>,
        attributes: MenuElementAttributes = [],
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.option = option
        self.selection = selection
        self.attributes = attributes
        self.label = label()
    }

    public var body: some MenuElement {
        MenuButton(
            isSelected: selection.wrappedValue == option,
            attributes: attributes
        ) {
            withAnimation {
                selection.wrappedValue = option
            }
        } label: {
            label
        }
    }
}

@available(iOS 14.0, *)
extension MenuPickerOption {

    public func disabled(_ disabled: Bool) -> MenuPickerOption {
        var copy = self
        if disabled {
            copy.attributes.formUnion(.disabled)
        } else {
            copy.attributes.subtract(.disabled)
        }
        return copy
    }
}

@frozen
@available(iOS 14.0, *)
public struct MenuPicker<Selection: Hashable>: MenuElement {

    public var options: [MenuPickerOption<Selection>]

    @inlinable
    public init(
        sources: [Selection],
        selection: Binding<Selection?>,
        @LabelElementBuilder label: (Selection) -> LabelElement
    ) {
        self.options = sources.map { source in
            MenuPickerOption(
                option: source,
                selection: selection
            ) {
                label(source)
            }
        }
    }

    @inlinable
    public init(
        @MenuBuilder options: () -> MenuElementsCollection<MenuPickerOption<Selection>>
    ) {
        self.options = options().values
    }

    public var body: some MenuElement {
        ForEach(options, id: \.option) { option in
            option
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuPicker_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {

        enum Fruit: String, CaseIterable {
            case apple
            case orange
            case pear
            case mango
        }

        @State var selection: Fruit?

        var body: some View {
            VStack {
                MenuLink {
                    MenuPicker(
                        sources: Fruit.allCases,
                        selection: $selection
                    ) { fruit in
                        Text(fruit.rawValue.capitalized)
                    }

                    MenuButton(
                        isSelected: selection == nil
                    ) {
                        withAnimation {
                            selection = nil
                        }
                    } label: {
                        Text("None")
                    }
                } label: {
                    Text(selection?.rawValue.capitalized ?? "Menu")
                }

                MenuLink {
                    MenuPicker {
                        ForEach(Fruit.allCases, id: \.self) { fruit in
                            MenuPickerOption(
                                option: fruit,
                                selection: $selection,
                                attributes: .prefersKeepsMenuPresented
                            ) {
                                Text(fruit.rawValue.capitalized)
                            }
                            .disabled(fruit == .apple)
                        }
                    }

                    MenuButton(
                        isSelected: selection == nil
                    ) {
                        withAnimation {
                            selection = nil
                        }
                    } label: {
                        Text("None")
                    }
                } label: {
                    Text(selection?.rawValue.capitalized ?? "Menu")
                }
            }
        }
    }
}

#endif
