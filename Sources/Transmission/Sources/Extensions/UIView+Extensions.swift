//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIView {
    var viewController: UIViewController? {
        _viewController
    }

    public var _viewController: UIViewController? {
        var responder: UIResponder? = next
        while responder != nil, !(responder is UIViewController) {
            responder = responder?.next
        }
        return responder as? UIViewController
    }

    func preferredContentSize(for width: CGFloat) -> CGSize {
        var size = intrinsicContentSize
        if size.height <= 0 {
            size.width = width
            size.height = idealHeight(for: width)
        }
        return size
    }

    func idealHeight(for width: CGFloat) -> CGFloat {
        idealSize(for: width).height
    }

    func idealSize(for width: CGFloat) -> CGSize {
        var fittingSize = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        if fittingSize.height >= UIView.layoutFittingExpandedSize.height {
            let sizeThatFits = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            if sizeThatFits.height > 0 {
                fittingSize.height = sizeThatFits.height
            }
        }
        return fittingSize
    }

    func setFramePreservingTransform(_ frame: CGRect) {
        let anchor = layer.anchorPoint
        bounds = CGRect(origin: .zero, size: frame.size)
        center = CGPoint(
            x: frame.minX + (frame.width * anchor.x),
            y: frame.minY + (frame.height * anchor.y)
        )
    }

    func constrain(to other: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor),
            bottomAnchor.constraint(equalTo: other.bottomAnchor),
            leadingAnchor.constraint(equalTo: other.leadingAnchor),
            trailingAnchor.constraint(equalTo: other.trailingAnchor),
        ])
    }
}

extension UIView {

    public var isSwiftUIPlatformViewHost: Bool {
        _typeName(Self.self).hasPrefix("SwiftUI.PlatformViewHost")
    }

    private static var didSwizzleCAActionKey: UInt8 = 0

    public func disableInitialImplicitFrameAnimations() {
        let aClass: AnyClass = type(of: self)
        Self.disableInitialImplicitFrameAnimations(aClass: aClass)
    }

    public static func disableInitialImplicitFrameAnimations(aClass: AnyClass) {
        guard objc_getAssociatedObject(aClass, &Self.didSwizzleCAActionKey) as? Bool != true else { return }
        objc_setAssociatedObject(aClass, &Self.didSwizzleCAActionKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let originalSelector = #selector(action(for:forKey:))
        let swizzledSelector = #selector(swizzled_action(for:forKey:))

        guard
            let originalMethod = class_getInstanceMethod(aClass, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UIView.self, swizzledSelector)
        else { return }

        var didAdd = false
        if originalMethod == class_getInstanceMethod(UIView.self, originalSelector) {
            didAdd = class_addMethod(
                aClass,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod)
            )
        }

        if didAdd {
            class_replaceMethod(
                aClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc
    private func swizzled_action(for layer: CALayer, forKey event: String) -> CAAction? {
        if isInitialFrameAnimationAction(for: layer, forKey: event) {
            if isSwiftUIPlatformViewHost,
                responds(to: NSSelectorFromString("hostedView")),
                let hostedView = value(forKey: "hostedView") as? UIView
            {
                if let action = hostedView.action(for: hostedView.layer, forKey: event), action is NSNull {
                    return NSNull()
                }
            } else {
                return NSNull()
            }
        }
        let action = swizzled_action(for: layer, forKey: event)
        return action
    }

    public func isInitialFrameAnimationAction(for layer: CALayer, forKey event: String) -> Bool {
        guard layer.bounds.size == .zero else { return false }
        return event == "bounds" || event == "position" || event == "anchorPoint"
    }
}


#endif
