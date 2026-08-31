//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
extension View {
    /// Sets the preferred status bar style of the hosting views `UIViewController`
    ///
    /// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
    ///
    public func preferredStatusBarStyle(_ style: UIStatusBarStyle, isEnabled: Bool = true) -> some View {
        modifier(PreferredStatusBarStyleModifier(style: style, isEnabled: isEnabled))
    }

    /// Sets the preferred status bar visibility of the hosting views `UIViewController`
    ///
    /// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
    ///
    public func prefersStatusBarHidden(_ isHidden: Bool = true, isEnabled: Bool = true) -> some View {
        modifier(PrefersStatusBarHiddenModifier(isHidden: isHidden, isEnabled: isEnabled))
    }
}

/// Sets the preferred status bar style of the hosting views `UIViewController`
///
/// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
///
@available(iOS 14.0, *)
@frozen
public struct PreferredStatusBarStyleModifier: ViewModifier {

    var style: UIStatusBarStyle
    var isEnabled: Bool

    public init(
        style: UIStatusBarStyle,
        isEnabled: Bool = true
    ) {
        self.style = style
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .background(
                PreferredStatusBarStyleAdapter(
                    style: style,
                    isEnabled: isEnabled
                )
            )
    }
}

@available(iOS 14.0, *)
private struct PreferredStatusBarStyleAdapter: UIViewRepresentable {

    var style: UIStatusBarStyle
    var isEnabled: Bool

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        context.coordinator.onUpdate(
            style: style,
            isEnabled: isEnabled,
            context: context
        )
    }

    static func dismantleUIView(_ uiView: ViewControllerReader, coordinator: Coordinator) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .filter { $0.isKeyWindow }
        for window in windows {
            if coordinator.isAnimated {
                UIView.animate(withDuration: 0.15) {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }
            } else {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator: ViewControllerReaderDelegate {

        var style: UIStatusBarStyle = .default
        var isEnabled: Bool = false
        var isAnimated: Bool = false

        weak var presentingViewController: UIViewController?

        func viewControllerReaderDidMoveToWindow(_ view: UIView) {
            guard presentingViewController == nil else { return }
            presentingViewController = view.viewController
            onUpdate()
        }

        func onUpdate(
            style: UIStatusBarStyle,
            isEnabled: Bool,
            context: PreferredStatusBarStyleAdapter.Context
        ) {
            self.style = style
            self.isEnabled = isEnabled
            self.isAnimated = context.transaction.isAnimated
            onUpdate()
        }

        private func onUpdate() {
            guard let presentingViewController else { return }
            let newValue = isEnabled && style != .default ? style : nil
            if presentingViewController.preferredStatusBarStyleOverride != newValue {
                if isEnabled {
                    presentingViewController.swizzled_preferredStatusBarStyle = style
                } else {
                    presentingViewController.preferredStatusBarStyleOverride = newValue
                }
                presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
            }
        }
    }
}

/// Sets the preferred status bar visibility of the hosting views `UIViewController`
///
/// > Required: Your apps `Info.plist` key for `UIViewControllerBasedStatusBarAppearance` should be set to `YES`
///
@available(iOS 14.0, *)
public struct PrefersStatusBarHiddenModifier: ViewModifier {

    var isHidden: Bool
    var isEnabled: Bool

    public init(
        isHidden: Bool,
        isEnabled: Bool = true
    ) {
        self.isHidden = isHidden
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .background(
                PrefersStatusBarHiddenAdapter(
                    isHidden: isHidden,
                    isEnabled: isEnabled
                )
            )
    }
}

@available(iOS 14.0, *)
private struct PrefersStatusBarHiddenAdapter: UIViewRepresentable {

    var isHidden: Bool
    var isEnabled: Bool

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        context.coordinator.onUpdate(
            isHidden: isHidden,
            isEnabled: isEnabled,
            context: context
        )
    }

    static func dismantleUIView(_ uiView: ViewControllerReader, coordinator: Coordinator) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .filter { $0.isKeyWindow }
        for window in windows {
            if coordinator.isAnimated {
                UIView.animate(withDuration: 0.15) {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }
            } else {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator: ViewControllerReaderDelegate {

        var isHidden = false
        var isEnabled: Bool = false
        var isAnimated: Bool = false

        weak var presentingViewController: UIViewController?

        func viewControllerReaderDidMoveToWindow(_ view: UIView) {
            guard presentingViewController == nil else { return }
            presentingViewController = view.viewController
            onUpdate()
        }

        func onUpdate(
            isHidden: Bool,
            isEnabled: Bool,
            context: PrefersStatusBarHiddenAdapter.Context
        ) {
            self.isHidden = isHidden
            self.isEnabled = isEnabled
            self.isAnimated = context.transaction.isAnimated
            onUpdate()
        }

        private func onUpdate() {
            guard let presentingViewController else { return }
            let newValue = isEnabled ? isHidden : nil
            if presentingViewController.prefersStatusBarHiddenOverride != newValue {
                if isEnabled {
                    presentingViewController.swizzled_prefersStatusBarHidden = isHidden
                } else {
                    presentingViewController.prefersStatusBarHiddenOverride = newValue
                }
                presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
            }
        }
    }
}

extension UIViewController {

    func setNeedsStatusBarAppearanceUpdate(animated: Bool, transitionAlongsideCoordinator: Bool = true) {
        let update: () -> Void = {
            self.setNeedsStatusBarAppearanceUpdate()
            let windows: [UIWindow]
            if let presentingWindow = self.view.window {
                windows = presentingWindow.windowScene?.windows
                    .filter { $0 !== presentingWindow && $0.windowLevel == presentingWindow.windowLevel } ?? []
            } else {
                windows = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
            }
            for window in windows {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }

        if transitionAlongsideCoordinator, let transitionCoordinator {
            transitionCoordinator.animate { _ in
                update()
            }
        } else if animated {
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
        if self is AnyHostingController {
            for child in children {
                if let child = child.getChildForStatusBarAppearance() {
                    return child
                }
            }
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

    var preferredStatusBarStyleOverride: UIStatusBarStyle? {
        get {
            if let box = objc_getAssociatedObject(self, &Self.preferredStatusBarStyleKey) as? ObjCBox<UIStatusBarStyle> {
                return box.value
            }
            return nil
        }
        set {
            if let newValue {
                if let box = objc_getAssociatedObject(self, &Self.preferredStatusBarStyleKey) as? ObjCBox<UIStatusBarStyle> {
                    box.value = newValue
                } else {
                    let box = ObjCBox(value: newValue)
                    objc_setAssociatedObject(self, &Self.preferredStatusBarStyleKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            } else {
                objc_setAssociatedObject(self, &Self.preferredStatusBarStyleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    private func getPreferredStatusBarStyle() -> UIStatusBarStyle? {
        if let style = preferredStatusBarStyleOverride {
            return style
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
            preferredStatusBarStyleOverride = newValue
        }
    }

    // MARK: prefersStatusBarHidden

    private static var prefersStatusBarHiddenKey: Bool = false

    var prefersStatusBarHiddenOverride: Bool? {
        get {
            if let box = objc_getAssociatedObject(self, &Self.prefersStatusBarHiddenKey) as? ObjCBox<Bool> {
                return box.value
            }
            return nil
        }
        set {
            if let newValue {
                if let box = objc_getAssociatedObject(self, &Self.prefersStatusBarHiddenKey) as? ObjCBox<Bool> {
                    box.value = newValue
                } else {
                    let box = ObjCBox(value: newValue)
                    objc_setAssociatedObject(self, &Self.prefersStatusBarHiddenKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            } else {
                objc_setAssociatedObject(self, &Self.prefersStatusBarHiddenKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    private func getPrefersStatusBarHidden() -> Bool? {
        if let isHidden = prefersStatusBarHiddenOverride {
            return isHidden
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
            prefersStatusBarHiddenOverride = newValue
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
