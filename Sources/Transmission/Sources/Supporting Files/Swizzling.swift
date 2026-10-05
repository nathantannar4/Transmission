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

    let originalImplementation = method_getImplementation(originalMethod)
    let swizzledImplementation = method_getImplementation(swizzledMethod)

    class_replaceMethod(
        target,
        aSwizzledSelector,
        originalImplementation,
        method_getTypeEncoding(originalMethod)
    )
    class_replaceMethod(
        target,
        aSelector,
        swizzledImplementation,
        method_getTypeEncoding(swizzledMethod)
    )
}
