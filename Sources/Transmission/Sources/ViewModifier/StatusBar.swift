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
    /// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `NO`
    ///
    public func preferredStatusBarStyle(_ style: UIStatusBarStyle) -> some View {
        modifier(PreferredStatusBarSyleModifier(style: style))
    }

    /// Sets the preferred status bar visibility of the hosting views `UIViewController`
    ///
    /// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `NO`
    ///
    public func prefersStatusBarHidden(_ isHidden: Bool = true) -> some View {
        modifier(PrefersStatusBarHiddenModifier(isHidden: isHidden))
    }
}

/// Sets the preferred status bar style of the hosting views `UIViewController`
///
/// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `NO`
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PreferredStatusBarSyleModifier: ViewModifier {
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

    @WeakStateObject var presentingViewController: UIViewController?

    func makeUIView(context: Context) -> HostingViewReader {
        let uiView = HostingViewReader(presentingViewController: $presentingViewController)
        return uiView
    }

    func updateUIView(_ uiView: HostingViewReader, context: Context) {
        if let presentingViewController = presentingViewController {
            let isAnimated = context.transaction.isAnimated
            presentingViewController.swizzled_preferredStatusBarStyle = style

            func setNeedsStatusBarAppearanceUpdate() {
                presentingViewController.setNeedsStatusBarAppearanceUpdate()
                for window in UIApplication.shared.windows where window.windowLevel == presentingViewController.view.window?.windowLevel {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }
            }

            if isAnimated {
                UIView.animate(withDuration: 0.15) {
                    setNeedsStatusBarAppearanceUpdate()
                }
            } else {
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    static func dismantleUIView(_ uiView: HostingViewReader, coordinator: Void) {
        for window in UIApplication.shared.windows where window.isKeyWindow {
            UIView.animate(withDuration: 0.15) {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

/// Sets the preferred status bar visibility of the hosting views `UIViewController`
///
/// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `NO`
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

    @WeakStateObject var presentingViewController: UIViewController?

    func makeUIView(context: Context) -> HostingViewReader {
        let uiView = HostingViewReader(presentingViewController: $presentingViewController)
        return uiView
    }

    func updateUIView(_ uiView: HostingViewReader, context: Context) {
        if let presentingViewController = presentingViewController {
            let isAnimated = context.transaction.isAnimated
            presentingViewController.swizzled_prefersStatusBarHidden = isHidden

            func setNeedsStatusBarAppearanceUpdate() {
                presentingViewController.setNeedsStatusBarAppearanceUpdate()
                for window in UIApplication.shared.windows where window.windowLevel == presentingViewController.view.window?.windowLevel {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }
            }

            if isAnimated {
                UIView.animate(withDuration: 0.15) {
                    setNeedsStatusBarAppearanceUpdate()
                }
            } else {
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    static func dismantleUIView(_ uiView: HostingViewReader, coordinator: Void) {
        for window in UIApplication.shared.windows where window.isKeyWindow {
            UIView.animate(withDuration: 0.15) {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension UIViewController {

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

    private func getChildForStatusBarAppearance() -> UIViewController? {
        if let child = childForStatusBarStyle {
            return child
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController
        }
        if let pageViewController = self as? UIPageViewController {
            return pageViewController.viewControllers?.first
        }
        if let host = self as? AnyHostingController, host.parent == nil {
            return host.children.first
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

                let original = #selector(getter: UIViewController.preferredStatusBarStyle)
                let swizzled = #selector(getter: UIViewController.swizzled_preferredStatusBarStyle)
                if let originalMethod = class_getInstanceMethod(UIHostingController<AnyView>.self, original),
                   let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
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
        }
        if let child = getChildForStatusBarAppearance() {
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

                let original = #selector(getter: UIViewController.prefersStatusBarHidden)
                let swizzled = #selector(getter: UIViewController.swizzled_prefersStatusBarHidden)
                if let originalMethod = class_getInstanceMethod(UIHostingController<AnyView>.self, original),
                   let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
                {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
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

#endif
