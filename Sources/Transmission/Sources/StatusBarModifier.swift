//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    /// Sets the preferred status bar style of the hosting views `UIViewController`
    ///
    /// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
    ///
    public func preferredStatusBarStyle(_ style: UIStatusBarStyle) -> some View {
        modifier(PreferredStatusBarStyleModifier(style: style))
    }

    /// Sets the preferred status bar visibility of the hosting views `UIViewController`
    ///
    /// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
    ///
    public func prefersStatusBarHidden(_ isHidden: Bool = true) -> some View {
        modifier(PrefersStatusBarHiddenModifier(isHidden: isHidden))
    }
}

/// Sets the preferred status bar style of the hosting views `UIViewController`
///
/// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct PreferredStatusBarStyleModifier: ViewModifier {
    var style: UIStatusBarStyle

    public init(style: UIStatusBarStyle) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .background(
                PreferredStatusBarStyleAdapter(style: style)
            )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PreferredStatusBarStyleAdapter: UIViewRepresentable {
    var style: UIStatusBarStyle

    @WeakState var presentingViewController: UIViewController?

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(presentingViewController: $presentingViewController)
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        if let presentingViewController = presentingViewController {
            let isAnimated = context.transaction.isAnimated
            presentingViewController.swizzled_preferredStatusBarStyle = style
            presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
        }
    }

    static func dismantleUIView(_ uiView: ViewControllerReader, coordinator: Void) {
        for window in UIApplication.shared.windows where window.isKeyWindow {
            UIView.animate(withDuration: 0.15) {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

/// Sets the preferred status bar visibility of the hosting views `UIViewController`
///
/// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PrefersStatusBarHiddenModifier: ViewModifier {
    var isHidden: Bool

    public init(isHidden: Bool) {
        self.isHidden = isHidden
    }

    public func body(content: Content) -> some View {
        content
            .background(
                PrefersStatusBarHiddenAdapter(isHidden: isHidden)
            )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PrefersStatusBarHiddenAdapter: UIViewRepresentable {
    var isHidden: Bool

    @WeakState var presentingViewController: UIViewController?

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(presentingViewController: $presentingViewController)
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        if let presentingViewController = presentingViewController {
            let isAnimated = context.transaction.isAnimated
            presentingViewController.swizzled_prefersStatusBarHidden = isHidden
            presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
        }
    }

    static func dismantleUIView(_ uiView: ViewControllerReader, coordinator: Void) {
        for window in UIApplication.shared.windows where window.isKeyWindow {
            UIView.animate(withDuration: 0.15) {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension UIViewController {

    func setNeedsStatusBarAppearanceUpdate(animated: Bool) {
        let update: () -> Void = {
            self.setNeedsStatusBarAppearanceUpdate()
            let presentingWindow = self.view.window
            for window in UIApplication.shared.windows where window.windowLevel == presentingWindow?.windowLevel && window != presentingWindow {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }

        if animated {
            UIView.animate(withDuration: 0.15, animations: update)
        } else {
            update()
        }
    }

    private var swizzled_childForStatusBar: UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.topViewController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController
        }
        if let pageViewController = self as? UIPageViewController {
            return pageViewController.viewControllers?.first
        }
        return nil
    }

    private func getChildForStatusBarAppearance() -> UIViewController? {
        if let child = swizzled_childForStatusBar {
            return child
        }
        if let host = self as? AnyHostingController {
            return host.children.first
        }
        return nil
    }

    @objc
    var swizzled_childForStatusBarStyle: UIViewController? {
        if getPreferredStatusBarStyle() != .default {
            return nil
        }
        
        if let child = swizzled_childForStatusBar {
            return child
        }

        typealias GetChildForStatusBarStyleMethod = @convention(c) (NSObject, Selector) -> UIViewController?
        let swizzled = #selector(getter: UIViewController.swizzled_childForStatusBarStyle)
        return unsafeBitCast(method(for: swizzled), to: GetChildForStatusBarStyleMethod.self)(self, swizzled)
    }

    @objc
    var swizzled_childForStatusBarHidden: UIViewController? {
        if getPrefersStatusBarHidden() != false {
            return nil
        }

        if let child = swizzled_childForStatusBar {
            return child
        }

        typealias GetChildForStatusBarHiddenMethod = @convention(c) (NSObject, Selector) -> UIViewController?
        let swizzled = #selector(getter: UIViewController.swizzled_childForStatusBarHidden)
        return unsafeBitCast(method(for: swizzled), to: GetChildForStatusBarHiddenMethod.self)(self, swizzled)
    }

    // MARK: preferredStatusBarStyle

    private static var preferredStatusBarStyleKey: Bool = false

    private func getPreferredStatusBarStyle() -> UIStatusBarStyle? {
        if let box = objc_getAssociatedObject(self, &Self.preferredStatusBarStyleKey) as? ObjCBox<UIStatusBarStyle> {
            return box.value
        } else if let child = getChildForStatusBarAppearance() {
            return child.getPreferredStatusBarStyle()
        }
        return nil
    }

    @objc
    var swizzled_preferredStatusBarStyle: UIStatusBarStyle {
        get {
            if let style = getPreferredStatusBarStyle() {
                return style
            }

            typealias GetPreferredStatusBarStyleMethod = @convention(c) (NSObject, Selector) -> UIStatusBarStyle
            let swizzled = #selector(getter: UIViewController.swizzled_preferredStatusBarStyle)
            return unsafeBitCast(method(for: swizzled), to: GetPreferredStatusBarStyleMethod.self)(self, swizzled)
        }
        set {
            if !Self.preferredStatusBarStyleKey {
                Self.preferredStatusBarStyleKey = true

                objc_class_swizzle(
                    original: #selector(getter: UIViewController.preferredStatusBarStyle),
                    replacement: #selector(getter: UIViewController.swizzled_preferredStatusBarStyle)
                )

                objc_class_swizzle(
                    original: #selector(getter: UIViewController.childForStatusBarStyle),
                    replacement: #selector(getter: UIViewController.swizzled_childForStatusBarStyle)
                )
            }

            if let box = objc_getAssociatedObject(self, &Self.preferredStatusBarStyleKey) as? ObjCBox<UIStatusBarStyle> {
                box.value = newValue
            } else {
                let box = ObjCBox(value: newValue)
                objc_setAssociatedObject(self, &Self.preferredStatusBarStyleKey, box, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    // MARK: prefersStatusBarHidden

    private static var prefersStatusBarHiddenKey: Bool = false

    private func getPrefersStatusBarHidden() -> Bool? {
        if let box = objc_getAssociatedObject(self, &Self.prefersStatusBarHiddenKey) as? ObjCBox<Bool> {
            return box.value
        } else if let child = getChildForStatusBarAppearance() {
            return child.getPrefersStatusBarHidden()
        }
        return nil
    }

    @objc
    var swizzled_prefersStatusBarHidden: Bool {
        get {
            if let isHidden = getPrefersStatusBarHidden() {
                return isHidden
            }

            typealias GetPrefersStatusBarHiddenMethod = @convention(c) (NSObject, Selector) -> Bool
            let swizzled = #selector(getter: UIViewController.swizzled_prefersStatusBarHidden)
            return unsafeBitCast(method(for: swizzled), to: GetPrefersStatusBarHiddenMethod.self)(self, swizzled)
        }
        set {
            if !Self.prefersStatusBarHiddenKey {
                Self.prefersStatusBarHiddenKey = true

                objc_class_swizzle(
                    original: #selector(getter: UIViewController.prefersStatusBarHidden),
                    replacement: #selector(getter: UIViewController.swizzled_prefersStatusBarHidden)
                )

                objc_class_swizzle(
                    original: #selector(getter: UIViewController.childForStatusBarHidden),
                    replacement: #selector(getter: UIViewController.swizzled_childForStatusBarHidden)
                )
            }

            if let box = objc_getAssociatedObject(self, &Self.prefersStatusBarHiddenKey) as? ObjCBox<Bool> {
                box.value = newValue
            } else {
                let box = ObjCBox(value: newValue)
                objc_setAssociatedObject(self, &Self.prefersStatusBarHiddenKey, box, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
}

private func objc_class_swizzle(original: Selector, replacement swizzled: Selector) {
    if let originalMethod = class_getInstanceMethod(UIHostingController<AnyView>.self, original),
        let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
    {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

#endif
