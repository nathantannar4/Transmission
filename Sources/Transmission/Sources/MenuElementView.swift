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
    public var safeAreaInsets: EdgeInsets
    public var attributes: MenuButton.Attributes
    public var action: (@MainActor () -> Void)?

    @inlinable
    public init(
        safeAreaInsets: EdgeInsets = {
            if #available(iOS 26.0, *) {
                return EdgeInsets(top: 10, leading: 28, bottom: 10, trailing: 28)
            }
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }(),
        attributes: MenuButton.Attributes = [],
        @ViewBuilder content: () -> Content,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.content = content()
        self.safeAreaInsets = safeAreaInsets
        self.attributes = attributes
        self.action = action
    }

    public typealias UIMenuElementType = UIMenuElement & UIMenuLeaf

    public func makeUIMenuElement(context: Context) -> UIMenuElementType {
        let element = UIMenuElement.customView(
            content: content,
            safeAreaInsets: safeAreaInsets
        )
        if let element {
            element.attributes = attributes.toUIKit()
            element.primaryAction = action
            return element
        }
        return UIAction(attributes: .hidden) { _ in }
    }

    public func updateUIMenuElement(_ element: inout UIMenuElementType, context: Context) {
        let hostingView = element.contentView as? MenuElementHostingView<Content>
        hostingView?.content.content = content
        element.attributes = attributes.toUIKit()
        element.primaryAction = action
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
            .tint(element?.attributes.contains(.destructive) == true ? .red : .black)
            .disabled(element?.attributes.contains(.disabled) ?? false)
    }
}

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
        contentView: @escaping @autoclosure () -> UIView
    ) -> (UIMenuElement & UIMenuLeaf)? {
        guard
            // UICustomViewMenuElement
            let aClassName = NSClassFromBase64EncodedString("VUlDdXN0b21WaWV3TWVudUVsZW1lbnQ="),
            // elementWithViewProvider:
            let aSelector = NSSelectorFromBase64EncodedString("ZWxlbWVudFdpdGhWaWV3UHJvdmlkZXI6"),
            aClassName.responds(to: aSelector)
        else {
            return nil
        }
        let provider: @convention(block) () -> UIView = { contentView() }
        guard
            let element = aClassName.perform(aSelector, with: provider).takeUnretainedValue() as? UIMenuElement & UIMenuLeaf
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

#endif
