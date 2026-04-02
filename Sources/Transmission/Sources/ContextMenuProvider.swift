//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 16.0, *)
public enum ContextMenuOrder {

    /// The default order
    case automatic

    /// Allows the system to choose the appropriate ordering strategy for the current context.
    case priority

    /// Order menu elements according to priority. Keeping the first element in the UIMenu closest to user's interaction point.
    case fixed
}

@available(iOS 14.0, *)
public protocol ContextMenuProvider {

    @available(iOS 16.0, *)
    var order: ContextMenuOrder { get }

    @MainActor @preconcurrency func makeUIMenu(context: Context) -> UIMenu

    typealias Context = ContextMenuProviderContext
}

@frozen
@available(iOS 14.0, *)
public struct ContextMenuProviderContext {
    public var environment: EnvironmentValues
}

@available(iOS 16.0, *)
extension ContextMenuProvider {
    public var order: ContextMenuOrder { .automatic }
}

@available(iOS 16.0, *)
struct MenuElementView<Content: View>: View {
    var content: Content
    var safeAreaInsets: EdgeInsets

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
    }
}

@available(iOS 16.0, *)
extension UIMenuElement {

    public static func customView<Content: View>(
        content: Content,
        safeAreaInsets: EdgeInsets = {
            if #available(iOS 26.0, *) {
                return EdgeInsets(top: 8, leading: 28, bottom: 8, trailing: 28)
            }
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }(),
        attributes: UIMenuElement.Attributes = [],
        action: (@convention(block) () -> Void)? = nil
    ) -> (UIMenuElement & UIMenuLeaf)? {
        let hostingView = HostingView(
            content: MenuElementView(
                content: content,
                safeAreaInsets: safeAreaInsets
            )
        )
        return Self.customView(contentView: hostingView, attributes: attributes, action: action)
    }

    public static func customView(
        contentView: UIView,
        attributes: UIMenuElement.Attributes = [],
        action: (@convention(block) () -> Void)? = nil
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
        let provider: @convention(block) () -> UIView = { contentView }
        guard
            let element = aClassName.perform(aSelector, with: provider).takeUnretainedValue() as? UIMenuElement & UIMenuLeaf
        else {
            return nil
        }
        // setPrimaryActionHandler:
        if let action,
            let aSelector = NSSelectorFromBase64EncodedString("c2V0UHJpbWFyeUFjdGlvbkhhbmRsZXI6"),
            element.responds(to: aSelector)
        {
            element.perform(aSelector, with: action)
        }
        element.attributes = attributes
        return element
    }
}


#endif
