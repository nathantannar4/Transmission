//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public struct MenuTextField: MenuElement {

    public var placeholder: Text?
    public var text: Binding<String>

    public init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>
    ) {
        self.init(Text(placeholder), text: text)
    }

    public init(
        _ placeholder: Text? = nil,
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self.text = text
    }

    public var body: some MenuElement {
        EmptyMenuElement()
    }

    public func _updateUIAlertController(_ alert: UIAlertController, context: Context) {
        alert.addTextField { textField in
            textField.placeholder = placeholder?.resolve(in: context.environment)
            textField.text = text.wrappedValue
            let coordinator = MenuTextFieldCoordinator(text: text)
            textField.coordinator = coordinator
            NotificationCenter.default.addObserver(
                coordinator,
                selector: #selector(MenuTextFieldCoordinator.textFieldDidChange),
                name: UITextField.textDidChangeNotification,
                object: textField
            )
        }
    }
}

@MainActor
private class MenuTextFieldCoordinator: NSObject {

    var text: Binding<String>

    init(text: Binding<String>) {
        self.text = text
    }

    @objc
    func textFieldDidChange(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else { return }
        text.wrappedValue = textField.text ?? ""
        let text = text.wrappedValue
        if textField.text != text {
            textField.text = text
        }
    }
}

extension UITextField {

    private static var coordinatorKey: UInt = 0
    fileprivate var coordinator: MenuTextFieldCoordinator? {
        get { objc_getAssociatedObject(self, &Self.coordinatorKey) as? MenuTextFieldCoordinator }
        set { objc_setAssociatedObject(self, &Self.coordinatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

#endif
