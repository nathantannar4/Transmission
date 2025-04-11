//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIViewController {

    private static var beginAppearanceTransitionKey: Bool = false

    struct BeginAppearanceTransition {
        var value: () -> Void
    }

    func swizzle_beginAppearanceTransition(_ transition: (() -> Void)?) {
        let original = #selector(UIViewController.beginAppearanceTransition(_:animated:))
        let swizzled = #selector(UIViewController.swizzled_beginAppearanceTransition(_:animated:))

        if !Self.beginAppearanceTransitionKey {
            Self.beginAppearanceTransitionKey = true

            if let originalMethod = class_getInstanceMethod(Self.self, original),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
            {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }

        if let transition {
            let box = ObjCBox(value: BeginAppearanceTransition(value: transition))
            objc_setAssociatedObject(self, &Self.beginAppearanceTransitionKey, box, .OBJC_ASSOCIATION_RETAIN)
        } else {
            objc_setAssociatedObject(self, &Self.beginAppearanceTransitionKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc
    func swizzled_beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
        if let box = objc_getAssociatedObject(self, &Self.beginAppearanceTransitionKey) as? ObjCBox<BeginAppearanceTransition> {
            box.value.value()
        }

        typealias BeginAppearanceTransitionMethod = @convention(c) (NSObject, Selector, Bool, Bool) -> Void
        let swizzled = #selector(UIViewController.swizzled_beginAppearanceTransition(_:animated:))
        unsafeBitCast(method(for: swizzled), to: BeginAppearanceTransitionMethod.self)(self, swizzled, isAppearing, animated)
    }

    private static var endAppearanceTransitionKey: Bool = false

    struct EndAppearanceTransition {
        var value: () -> Void
    }

    func swizzle_endAppearanceTransition(_ transition: (() -> Void)?) {
        let original = #selector(UIViewController.endAppearanceTransition)
        let swizzled = #selector(UIViewController.swizzled_endAppearanceTransition)

        if !Self.endAppearanceTransitionKey {
            Self.endAppearanceTransitionKey = true

            if let originalMethod = class_getInstanceMethod(Self.self, original),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
            {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }

        if let transition {
            let box = ObjCBox(value: EndAppearanceTransition(value: transition))
            objc_setAssociatedObject(self, &Self.endAppearanceTransitionKey, box, .OBJC_ASSOCIATION_RETAIN)
        } else {
            objc_setAssociatedObject(self, &Self.endAppearanceTransitionKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc
    func swizzled_endAppearanceTransition() {
        if let box = objc_getAssociatedObject(self, &Self.endAppearanceTransitionKey) as? ObjCBox<EndAppearanceTransition> {
            box.value.value()
        }

        typealias EndAppearanceTransitionMethod = @convention(c) (NSObject, Selector) -> Void
        let swizzled = #selector(UIViewController.swizzled_endAppearanceTransition)
        unsafeBitCast(method(for: swizzled), to: EndAppearanceTransitionMethod.self)(self, swizzled)
    }
}

#endif
