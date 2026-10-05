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
        coordinator.onDismantle()
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

        func onDismantle() {
            guard let presentingViewController else { return }
            presentingViewController.preferredStatusBarStyleOverride = nil
            presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
        }

        private func onUpdate() {
            guard let presentingViewController else { return }
            let newValue = isEnabled ? style : nil
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
        coordinator.onDismantle()
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

        func onDismantle() {
            guard let presentingViewController else { return }
            presentingViewController.prefersStatusBarHiddenOverride = nil
            presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
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
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
            for window in windows {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }

        var didUpdate = false
        if transitionAlongsideCoordinator, let transitionCoordinator {
            didUpdate = transitionCoordinator.animate { _ in
                update()
            }
        }
        if !didUpdate {
            if animated {
                UIView.animate(withDuration: 0.15, animations: update)
            } else {
                update()
            }
        }
    }

    private func getChildForStatusBarAppearance() -> UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.topViewController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController
        }
        if let pageViewController = self as? UIPageViewController {
            return pageViewController.viewControllers?.first
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
        if preferredStatusBarStyleOverride != nil {
            return nil
        }
        if let child = getChildForStatusBarAppearance() {
            return child
        }
        return self.swizzled_childForStatusBarStyle
    }

    @objc
    var swizzled_childForStatusBarHidden: UIViewController? {
        if prefersStatusBarHiddenOverride != nil {
            return nil
        }
        if let child = getChildForStatusBarAppearance() {
            return child
        }
        return self.swizzled_childForStatusBarHidden
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

    @objc
    var swizzled_preferredStatusBarStyle: UIStatusBarStyle {
        get {
            if let style = preferredStatusBarStyleOverride {
                return style
            }
            return self.swizzled_preferredStatusBarStyle
        }
        set {
            if !Self.preferredStatusBarStyleKey {
                Self.preferredStatusBarStyleKey = true

                swizzle(
                    target: UIHostingController<AnyView>.self,
                    source: UIViewController.self,
                    aSelector: #selector(getter: UIViewController.preferredStatusBarStyle),
                    aSwizzledSelector: #selector(getter: UIViewController.swizzled_preferredStatusBarStyle)
                )

                swizzle(
                    target: UIHostingController<AnyView>.self,
                    source: UIViewController.self,
                    aSelector: #selector(getter: UIViewController.childForStatusBarStyle),
                    aSwizzledSelector: #selector(getter: UIViewController.swizzled_childForStatusBarStyle)
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

    @objc
    var swizzled_prefersStatusBarHidden: Bool {
        get {
            if let isHidden = prefersStatusBarHiddenOverride {
                return isHidden
            }
            return self.swizzled_prefersStatusBarHidden
        }
        set {
            if !Self.prefersStatusBarHiddenKey {
                Self.prefersStatusBarHiddenKey = true

                swizzle(
                    target: UIHostingController<AnyView>.self,
                    source: UIViewController.self,
                    aSelector: #selector(getter: UIViewController.prefersStatusBarHidden),
                    aSwizzledSelector: #selector(getter: UIViewController.swizzled_prefersStatusBarHidden)
                )

                swizzle(
                    target: UIHostingController<AnyView>.self,
                    source: UIViewController.self,
                    aSelector: #selector(getter: UIViewController.childForStatusBarHidden),
                    aSwizzledSelector: #selector(getter: UIViewController.swizzled_childForStatusBarHidden)
                )
            }
            prefersStatusBarHiddenOverride = newValue
        }
    }
}

#endif
