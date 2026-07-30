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
        preconditionFailure("Failed to swizzle \(target):\(aSelector)")
    }

    let didAdd = class_addMethod(
        target,
        aSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    )
    class_replaceMethod(
        target,
        aSwizzledSelector,
        method_getImplementation(originalMethod),
        method_getTypeEncoding(originalMethod)
    )
    if !didAdd {
        class_replaceMethod(
            target,
            aSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
    }
}
