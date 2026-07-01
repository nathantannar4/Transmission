//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 16.0, *)
public struct MenuElementView<Content: View>: MenuElementRepresentable {

    public var content: Content
    public var attributes: MenuElementAttributes
    public var action: (@MainActor () -> Void)?

    @inlinable
    public init(
        attributes: MenuElementAttributes = [],
        action: (@MainActor () -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.attributes = attributes
        self.action = action
    }

    public typealias UIMenuElementType = UIMenuElement & UIMenuLeaf

    public func makeUIMenuElement(
        context: Context
    ) -> UIMenuElementType {
        let element = UIMenuElement.customView(
            content: content
        )
        if let element {
            element.attributes = attributes.toUIKit()
            element.primaryAction = action
            return element
        }
        return UIAction(attributes: .hidden) { _ in }
    }

    public func updateUIMenuElement(
        _ element: inout UIMenuElementType,
        context: Context
    ) {
        // Can't reuse the element or there is a noticible flicker as the menu reloads
        element = makeUIMenuElement(context: context)
    }

    public func _updateUIMenuElement(
        _ element: inout UIMenuElement,
        context: MenuRepresentableContext
    ) {
        if let aClass = UICustomViewMenuElement, element.isKind(of: aClass), var updated = element as? UIMenuElementType {
            updateUIMenuElement(&updated, context: context)
            element = updated
        } else {
            element = makeUIMenuElement(context: context)
        }
    }

    public func _updateUIAlertController(
        _ alert: UIAlertController,
        context: Context
    ) {
        guard !attributes.contains(.hidden) else { return }
        let element = UIAlertAction.customView(
            content: content,
            style: attributes.contains(.destructive) ? .destructive : .default,
            handler: action.map({ action in return { _ in action() } })
        )
        if let element {
            element.isEnabled = !attributes.contains(.disabled)
            alert.addAction(element)
        }
    }
}

@available(iOS 16.0, *)
class MenuElementHostingView<Content: View>: HostingView<MenuElementViewBody<Content>> {

    override init(content: MenuElementViewBody<Content>) {
        super.init(content: content)

        disablesSafeArea = true
        automaticallyAllowUIKitAnimationsForNextUpdate = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


@available(iOS 16.0, *)
struct MenuElementViewBody<Content: View>: View {
    var content: Content
    var safeAreaInsets: EdgeInsets
    weak var element: UIMenuLeaf?

    @ScaledMetric var scale: CGFloat = 1

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .safeAreaInsets(
                EdgeInsets(
                    top: safeAreaInsets.top * scale,
                    leading: safeAreaInsets.leading,
                    bottom: safeAreaInsets.bottom * scale,
                    trailing: safeAreaInsets.trailing
                )
            )
            .tint(element?.attributes.contains(.destructive) == true ? .red : nil)
            .foregroundStyle(Color.red, isEnabled: element?.attributes.contains(.destructive) == true)
            .disabled(element?.attributes.contains(.disabled) ?? false)
    }
}

// UICustomViewMenuElement
let UICustomViewMenuElement = NSClassFromBase64EncodedString("VUlDdXN0b21WaWV3TWVudUVsZW1lbnQ=")

extension UIMenuElement {

    @available(iOS 16.0, *)
    public static func customView<Content: View>(
        content: Content,
        safeAreaInsets: EdgeInsets = {
            if #available(iOS 26.0, *) {
                return EdgeInsets(top: 10, leading: 28, bottom: 10, trailing: 28)
            }
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }(),
    ) -> (UIMenuElement & UIMenuLeaf)? {
        let hostingView = MenuElementHostingView(
            content: MenuElementViewBody(
                content: content,
                safeAreaInsets: safeAreaInsets
            )
        )
        let element = Self.customView(
            contentView: hostingView
        )
        hostingView.content.element = element
        return element
    }

    @available(iOS 16.0, *)
    public static func customView(
        contentView: UIView
    ) -> (UIMenuElement & UIMenuLeaf)? {
        guard
            let aClass = UICustomViewMenuElement,
            // elementWithViewProvider:
            let aSelector = NSSelectorFromBase64EncodedString("ZWxlbWVudFdpdGhWaWV3UHJvdmlkZXI6"),
            aClass.responds(to: aSelector)
        else {
            return nil
        }
        let provider: @convention(block) () -> UIView = { contentView }
        guard
            let element = aClass.perform(aSelector, with: provider).takeUnretainedValue() as? UIMenuElement & UIMenuLeaf
        else {
            return nil
        }
        return element
    }

    public var primaryAction: (() -> Void)? {
        get {
            guard
                // primaryActionHandler
                let aSelector = NSStringFromBase64EncodedString("cHJpbWFyeUFjdGlvbkhhbmRsZXI="),
                responds(to: NSSelectorFromString(aSelector))
            else {
                return nil
            }
            return value(forKey: aSelector) as? () -> Void
        }
        set {
            guard
                // setPrimaryActionHandler:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0UHJpbWFyeUFjdGlvbkhhbmRsZXI6"),
                responds(to: aSelector)
            else {
                return
            }
            perform(aSelector, with: newValue)
        }
    }

    @available(iOS 16.0, *)
    public var contentView: UIView? {
        guard
            // contentView
            let aSelector = NSStringFromBase64EncodedString("Y29udGVudFZpZXc="),
            responds(to: NSSelectorFromString(aSelector))
        else {
            return nil
        }
        return value(forKey: aSelector) as? UIView
    }
}

class AlertActionHostingController<Content: View>: HostingController<Content> {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *)  {
            view.clipsToBounds = true
            view.cornerConfiguration = .capsule()
        }
        #endif
    }
}

struct AlertActionViewBody<Content: View>: VersionedView {
    var content: Content
    var safeAreaInsets: EdgeInsets
    weak var action: UIAlertAction?

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    var v4Body: some View {
        content
            .safeAreaInsets(safeAreaInsets)
            .frame(maxWidth: .infinity, alignment: .center)
            .tint(action?.style == .destructive ? .red : nil)
            .foregroundStyle(Color.red, isEnabled: action?.style == .destructive)
            .disabled(action?.isEnabled == false)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var v3Body: some View {
        content
            .safeAreaInsets(safeAreaInsets)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundStyle(Color.red, isEnabled: action?.style == .destructive)
            .disabled(action?.isEnabled == false)
    }

    var v1Body: some View {
        content
            .padding(safeAreaInsets)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(Color.red, isEnabled: action?.style == .destructive)
            .disabled(action?.isEnabled == false)
    }
}


extension UIAlertAction {

    private typealias Handler = @convention(block) (UIAlertAction) -> Void
    private typealias ActionWithContentViewControllerStyleHandler = @convention(c) (NSObject.Type, Selector, UIViewController, Style, Handler?) -> UIAlertAction
    public static func customView<Content: View>(
        content: Content,
        safeAreaInsets: EdgeInsets = {
            return EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
        }(),
        style: Style,
        handler: ((UIAlertAction) -> Void)? = nil
    ) -> UIAlertAction? {
        let hostingController = AlertActionHostingController(
            content: AlertActionViewBody(
                content: content,
                safeAreaInsets: safeAreaInsets
            )
        )
        let action = customView(
            contentViewController: hostingController,
            style: style,
            handler: handler
        )
        hostingController.content.action = action
        return action
    }

    public static func customView(
        contentViewController: UIViewController,
        style: Style,
        handler: ((UIAlertAction) -> Void)? = nil
    ) -> UIAlertAction? {
        guard
            // _actionWithContentViewController:style:handler:
            let aSelector = NSSelectorFromBase64EncodedString("X2FjdGlvbldpdGhDb250ZW50Vmlld0NvbnRyb2xsZXI6c3R5bGU6aGFuZGxlcjo="),
            responds(to: aSelector),
            let imp = method(for: aSelector)
        else {
            return nil
        }
        let method = unsafeBitCast(imp, to: ActionWithContentViewControllerStyleHandler.self)
        let action = method(
            UIAlertAction.self,
            aSelector,
            contentViewController,
            style,
            handler
        )
        return action
    }
}


// MARK: - Previews

@available(iOS 16.0, *)
struct MenuElementView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isSelected = false

        @MenuBuilder
        var menu: some MenuElement {
            MenuButton(isSelected: isSelected) {
                withAnimation {
                    isSelected.toggle()
                }
            } label: {
                Text("isSelected")
            }

            MenuElementView {

            } content: {
                Toggle(isOn: $isSelected) {
                    Text("isSelected")
                }
            }

            MenuElementView {
                Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }

        var body: some View {
            VStack {
                MenuSourceViewLink {
                    menu
                } label: {
                    Text("Menu")
                }

                MenuDialogLink(transition: .alert) {
                    menu
                } label: {
                    Text("Alert")
                }

                MenuDialogLink(transition: .actionSheet) {
                    menu
                } label: {
                    Text("Alert")
                }
            }
        }
    }
}

#endif
