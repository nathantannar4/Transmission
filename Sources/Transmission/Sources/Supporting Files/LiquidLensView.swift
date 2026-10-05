//
// Copyright (c) Nathan Tannar
//

#if os(iOS) && XCODE_26

import SwiftUI
import UIKit

@available(iOS 26.0, *)
open class LiquidLensView: UIView {

    let liquidLensView: UIView

    public var isLifted: Bool {
        guard
            // lifted
            let aSelector = NSStringFromBase64EncodedString("bGlmdGVk"),
            let value = liquidLensView.value(forKey: aSelector) as? Bool
        else {
            return false
        }
        return value
    }

    public init?(contentView: UIView) {
        guard
            // initWithRestingBackground:
            let initSelector = NSSelectorFromBase64EncodedString("aW5pdFdpdGhSZXN0aW5nQmFja2dyb3VuZDo="),
            // _UILiquidLensView
            let liquidLensViewClass = NSClassFromBase64EncodedString("X1VJTGlxdWlkTGVuc1ZpZXc=") as? UIView.Type
        else {
            return nil
        }
        let allocSelector = NSSelectorFromString("alloc")
        let instance = liquidLensViewClass.perform(allocSelector).takeUnretainedValue()
        guard
            instance.responds(to: initSelector),
            let liquidLensView = instance.perform(initSelector, with: contentView).takeUnretainedValue() as? UIView
        else {
            return nil
        }
        self.liquidLensView = liquidLensView
        super.init(frame: contentView.bounds)
        liquidLensView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(liquidLensView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setLifted(
        _ lifted: Bool,
        animated: Bool,
        alongsideAnimations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        let selector = NSSelectorFromString("setLifted:animated:alongsideAnimations:completion:")
        guard liquidLensView.responds(to: selector) else { return }

        typealias SetLiftedIMP = @convention(c) (
            AnyObject, Selector, ObjCBool, ObjCBool,
            (() -> Void)?, (() -> Void)?
        ) -> Void

        let method = class_getInstanceMethod(type(of: liquidLensView), selector)
        guard let impPointer = method.map(method_getImplementation) else { return }
        let imp = unsafeBitCast(impPointer, to: SetLiftedIMP.self)
        imp(liquidLensView, selector, ObjCBool(lifted), ObjCBool(animated), alongsideAnimations, completion)
    }
}

#endif
