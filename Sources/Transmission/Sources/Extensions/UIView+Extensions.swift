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
        guard
            // _viewControllerForAncestor
            let aSelector = NSStringFromBase64EncodedString("X3ZpZXdDb250cm9sbGVyRm9yQW5jZXN0b3I="),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? UIViewController
        else {
            var responder: UIResponder? = next
            while responder != nil {
                if let vc = responder as? UIViewController {
                    return vc
                }
                responder = responder?.next
            }
            return nil
        }
        return value
    }

    var containingScrollView: UIScrollView? {
        guard
            // _containingScrollView
            let aSelector = NSStringFromBase64EncodedString("X2NvbnRhaW5pbmdTY3JvbGxWaWV3"),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? UIScrollView
        else {
            var view = superview
            while view != nil, !(view is UIScrollView) {
                view = view?.superview
            }
            return view as? UIScrollView
        }
        return value
    }

    public func _firstAncestor<T: UIView>(ofType type: T.Type, matching: (T) -> Bool) -> T? {
        firstAncestor(ofType: type, matching: matching)
    }

    public func _firstAncestor(matching: (UIView) -> Bool) -> UIView? {
        firstAncestor(ofType: UIView.self, matching: matching)
    }

    func firstAncestor<T: UIView>(ofType type: T.Type, matching: (T) -> Bool) -> T? {
        if let superview {
            if let match = superview as? T, matching(match) {
                return match
            }
            return superview.firstAncestor(ofType: type, matching: matching)
        }
        return nil
    }

    public func _firstDescendent<T: UIView>(ofType type: T.Type, matching: (T) -> Bool) -> T? {
        firstDescendent(ofType: type, matching: matching)
    }

    public func _firstDescendent(matching: (UIView) -> Bool) -> UIView? {
        firstDescendent(ofType: UIView.self, matching: matching)
    }

    func firstDescendent<T: UIView>(ofType type: T.Type, matching: (T) -> Bool) -> T? {
        for subview in subviews {
            if let match = subview as? T, matching(match) {
                return match
            } else if let match = subview.firstDescendent(ofType: type, matching: matching) {
                return match
            }
        }
        return nil
    }

    func preferredContentSize(for width: CGFloat) -> CGSize {
        var size = intrinsicContentSize
        if size.height <= 0 || size.width > width {
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

extension UIView.AnimationOptions {

    init(curve: Int) {
        self.init(rawValue: UInt(curve) << 16)
    }

    init(curve: UIView.AnimationCurve) {
        self.init(curve: curve.rawValue)
    }
}

extension UIView {

    public var isSwiftUIPlatformViewHost: Bool {
        _typeName(Self.self).contains("PlatformViewHost")
    }

    private static var didSwizzleCAActionKey: UInt8 = 0

    public func disableInitialImplicitFrameAnimations() {
        let aClass: AnyClass = type(of: self)
        Self.disableInitialImplicitFrameAnimations(aClass: aClass)
    }

    public static func disableInitialImplicitFrameAnimations(aClass: AnyClass) {
        guard objc_getAssociatedObject(aClass, &Self.didSwizzleCAActionKey) as? Bool != true else { return }
        objc_setAssociatedObject(aClass, &Self.didSwizzleCAActionKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        swizzle(
            target: aClass,
            source: UIView.self,
            aSelector: #selector(action(for:forKey:)),
            aSwizzledSelector: #selector(swizzled_action(for:forKey:))
        )
    }

    @objc
    private func swizzled_action(for layer: CALayer, forKey event: String) -> CAAction? {
        if isSwiftUIPlatformViewHost,
            responds(to: NSSelectorFromString("hostedView")),
            let hostedView = value(forKey: "hostedView") as? UIView
        {
            if let action = hostedView.action(for: hostedView.layer, forKey: event), action is NSNull {
                return NSNull()
            }
        } else if isInitialFrameAnimationAction(for: layer, forKey: event) {
            return NSNull()
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
