//
// Copyright (c) Nathan Tannar
//

import ObjectiveC

func swizzle(target: AnyClass, source: AnyClass, aSelector: Selector, aSwizzledSelector: Selector) {
    guard
        let baseClassMethod = class_getInstanceMethod(source, aSelector),
        let originalMethod = class_getInstanceMethod(target, aSelector),
        let swizzledSelectorMethod = class_getInstanceMethod(target, aSwizzledSelector)
    else {
        preconditionFailure("Failed to swizzle \(target):\(aSelector)")
    }

    if baseClassMethod == originalMethod, target != source {
        // This means `source` did not override `aSelector`, so we need to add it
        let didAddMethod = class_addMethod(
            target,
            aSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
        guard didAddMethod else {
            preconditionFailure("Failed to swizzle \(target):\(aSelector)")
        }
    }

    guard let original = class_getInstanceMethod(target, aSelector) else {
        preconditionFailure("Failed to swizzle \(target):\(aSelector)")
    }
    method_exchangeImplementations(original, swizzledSelectorMethod)
}
