//
// Copyright (c) Nathan Tannar
//

import ObjectiveC

public func swizzle(
    target: AnyClass,
    source: AnyClass,
    aSelector: Selector,
    aSwizzledSelector: Selector
) {
    guard
        let originalMethod = class_getInstanceMethod(target, aSelector),
        let swizzledMethod = class_getInstanceMethod(source, aSwizzledSelector)
    else {
        assertionFailure("Failed to swizzle \(target):\(aSelector)")
        return
    }

    let didAddMethod = class_addMethod(
        target,
        aSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    )
    if didAddMethod {
        class_replaceMethod(
            target,
            aSwizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
