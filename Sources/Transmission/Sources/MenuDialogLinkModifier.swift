//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
@frozen
public struct MenuDialogTransition: Sendable {

    @usableFromInline
    enum Value: Sendable {
        case `default`
        case alert
        case actionSheet
    }
    @usableFromInline
    var value: Value

    public var options: Options

    init(
        value: Value,
        options: Options = .init()
    ) {
        self.value = value
        self.options = options
    }

    /// The default automatic transition based on the menu
    public static let `default` = MenuDialogTransition(value: .default)

    /// The alert transition style
    public static let alert = MenuDialogTransition(value: .alert)

    /// The action sheet transition style
    public static let actionSheet = MenuDialogTransition(value: .actionSheet)

    @inlinable
    public func isInteractive(_ isInteractive: Bool) -> MenuDialogTransition {
        var copy = self
        copy.options.isInteractive = isInteractive
        return copy
    }

    @inlinable
    public func preferredColorScheme(_ preferredColorScheme: ColorScheme?) -> MenuDialogTransition {
        var copy = self
        copy.options.preferredPresentationColorScheme = preferredColorScheme
        return copy
    }
}

@available(iOS 14.0, *)
extension MenuDialogTransition {

    @frozen
    public struct Options {
        public var isInteractive: Bool
        public var preferredPresentationColorScheme: ColorScheme?

        public init(
            isInteractive: Bool = false,
            preferredPresentationColorScheme: ColorScheme? = nil
        ) {
            self.isInteractive = isInteractive
            self.preferredPresentationColorScheme = preferredPresentationColorScheme
        }
    }
}

@available(iOS 14.0, *)
@frozen
public struct MenuDialogLinkModifier<
    Header: View,
    Menu: MenuElement
>: ViewModifier {

    var transition: MenuDialogTransition
    var isPresented: Binding<Bool>
    var title: Text?
    var message: Text?
    var header: Header
    var menu: Menu

    @_disfavoredOverload
    public init(
        transition: MenuDialogTransition = .default,
        isPresented: Binding<Bool>,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey? = nil,
        header: Header = EmptyView(),
        menu: Menu
    ) {
        self.init(
            transition: transition,
            isPresented: isPresented,
            title: Text(title),
            message: Text(message),
            header: header,
            menu: menu
        )
    }

    public init(
        transition: MenuDialogTransition = .default,
        isPresented: Binding<Bool>,
        title: Text? = nil,
        message: Text? = nil,
        header: Header = EmptyView(),
        menu: Menu
    ) {
        self.transition = transition
        self.isPresented = isPresented
        self.title = title
        self.message = message
        self.header = header
        self.menu = menu
    }

    public func body(content: Content) -> some View {
        content
            .presentation(
                transition: .default(
                    options: .init(
                        isInteractive: transition.options.isInteractive,
                        shouldAutomaticallyDismissPresentedView: false,
                        preferredPresentationColorScheme: transition.options.preferredPresentationColorScheme,
                    )
                ),
                isPresented: isPresented
            ) {
                MenuDialog(
                    transition: transition,
                    title: title,
                    message: message,
                    header: header,
                    menu: menu
                )
            }
    }
}

@available(iOS 14.0, *)
extension View {

    @_disfavoredOverload
    public func menuDialog<
        Header: View,
        Menu: MenuElement
    >(
        transition: MenuDialogTransition = .default,
        isPresented: Binding<Bool>,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @MenuBuilder menu: () -> Menu
    ) -> some View {
        modifier(
            MenuDialogLinkModifier(
                transition: transition,
                isPresented: isPresented,
                title: title,
                message: message,
                header: header(),
                menu: menu()
            )
        )
    }

    public func menuDialog<
        Header: View,
        Menu: MenuElement
    >(
        transition: MenuDialogTransition = .default,
        isPresented: Binding<Bool>,
        title: Text? = nil,
        message: Text? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @MenuBuilder menu: () -> Menu
    ) -> some View {
        modifier(
            MenuDialogLinkModifier(
                transition: transition,
                isPresented: isPresented,
                title: title,
                message: message,
                header: header(),
                menu: menu()
            )
        )
    }
}

@available(iOS 14.0, *)
private struct MenuDialog<
    Header: View,
    Menu: MenuElement
>: UIViewControllerRepresentable {

    var transition: MenuDialogTransition
    var title: Text?
    var message: Text?
    var header: Header
    var menu: Menu

    func makeUIViewController(
        context: Context
    ) -> MenuDialogViewController {
        let uiViewController = MenuDialogViewController(
            title: nil,
            message: nil,
            preferredStyle: {
                switch transition.value {
                case .default:
                    return .alert
                case .alert:
                    return .alert
                case .actionSheet:
                    return .actionSheet
                }
            }()
        )
        let context = MenuRepresentableContext(
            transaction: context.transaction,
            environment: context.environment
        )
        menu._updateUIAlertController(uiViewController, context: context)
        return uiViewController
    }

    func updateUIViewController(
        _ uiViewController: MenuDialogViewController,
        context: Context
    ) {
        if #available(iOS 15.0, *) {
            uiViewController.view.tintColor = context.environment.tintColor?.toUIColor(in: context.environment)
        }
        uiViewController.title = title?.resolve(in: context.environment)
        uiViewController.message = message?.resolve(in: context.environment)
        uiViewController.isInteractive = transition.options.isInteractive

        if header.isEmptyView {
            uiViewController.contentViewController = nil
        } else {
            if let contentViewController = uiViewController.contentViewController as? HostingController<Header> {
                contentViewController.content = header
            } else {
                let hostingController = HostingController(content: header)
                hostingController.view.backgroundColor = nil
                uiViewController.contentViewController = hostingController
            }
        }
    }
}

class MenuDialogViewController: UIAlertController {

    var isInteractive: Bool = false

    @objc
    private func _dismissFromPopoverDimmingView() {
        guard isInteractive else { return }
        cancel()
    }

    @objc
    private func _attemptAnimatedDismissWithGestureRecognizer(_ gesture: UIGestureRecognizer) {
        guard isInteractive else { return }
        cancel()
    }

    @objc
    private func _canDismissWithGestureRecognizer() -> Bool {
        return isInteractive
    }

    private func cancel() {
        let action = actions.first(where: { $0.style == .cancel })
        if isBeingPresented {
            if let presentationController,
                // _currentInteractionController
                let aSelector = NSStringFromBase64EncodedString("X2N1cnJlbnRJbnRlcmFjdGlvbkNvbnRyb2xsZXI="),
                presentationController.responds(to: NSSelectorFromString(aSelector)),
                let interactionController = presentationController.value(forKey: aSelector) as? UIPercentDrivenInteractiveTransition
            {
                interactionController.pause()
                interactionController.cancel()
                presentationController.delegate?.presentationControllerDidDismiss?(presentationController)
                if let action {
                    action.handler?(action)
                }
            }
        } else {
            dismiss(animated: true) {
                guard let action else { return }
                action.handler?(action)
            }
        }
    }
}

extension UIAlertAction {

    var handler: ((UIAlertAction) -> Void)? {
        guard
            // handler
            let aSelector = NSStringFromBase64EncodedString("aGFuZGxlcg=="),
            responds(to: NSSelectorFromString(aSelector)),
            let handler = value(forKey: aSelector) as? AnyObject
        else {
            return nil
        }
        typealias Handler = @convention(block) (UIAlertAction) -> Void
        return unsafeBitCast(handler, to: Handler.self)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MenuDialogModifier_Previews: PreviewProvider {

    struct Preview: View {

        @State var isInteractive = false
        @State var isAlertPresented = false
        @State var isActionSheetPresented = false

        var body: some View {
            ZStack {
                Color.blue.opacity(isAlertPresented ? 1 : 0)
                    .ignoresSafeArea()

                VStack {
                    Toggle(isOn: $isInteractive) {
                        Text("isInteractive")
                        Text("Taps outside the menu dialog dismiss")
                    }

                    Button {
                        withAnimation {
                            isAlertPresented = true
                        }
                    } label: {
                        Text("Alert")
                    }
                    .menuDialog(
                        transition: .alert.isInteractive(isInteractive),
                        isPresented: $isAlertPresented,
                        title: Text("Title"),
                        message: Text("Message")
                    ) {
                        Text("Header")
                    } menu: {
                        Menu()
                    }

                    Button {
                        withAnimation {
                            isActionSheetPresented = true
                        }
                    } label: {
                        Text("Action Sheet")
                    }
                    .menuDialog(
                        transition: .actionSheet.isInteractive(isInteractive),
                        isPresented: $isActionSheetPresented,
                        title: Text("Title"),
                        message: Text("Message")
                    ) {
                        Text("Header")
                    } menu: {
                        Menu()
                    }
                }
                .padding()
            }
        }

        struct Menu: MenuElement {
            var body: some MenuElement {
                MenuButton(role: .confirm) {
                    print("Confirm")
                } label: {
                    Text("Confirm")
                }

                MenuButton(attributes: .destructive) {
                    print("Delete")
                } label: {
                    Image(systemName: "trash")
                    Text("Delete")
                }

                MenuButton {
                    print("Action")
                } label: {
                    Text("Action")
                }

                if #available(iOS 16.0, *) {
                    MenuElementView {
                        print("Custom View Action")
                    } content: {
                        ZStack {
                            Color.blue
                                .opacity(0.3)

                            Text("Custom View")
                        }
                    }

                    MenuElementView(attributes: .destructive) {
                        print("Custom View Destructive Action")
                    } content: {
                        Text("Custom Destructive View")
                    }
                }

                MenuButton(role: .cancel) {
                    print("Cancel")
                } label: {
                    Text("Cancel")
                }
            }
        }
    }

    static var previews: some View {
        ZStack {
            Preview()
        }
    }
}

#endif
