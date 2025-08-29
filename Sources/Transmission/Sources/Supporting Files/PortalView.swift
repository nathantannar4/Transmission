//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

open class PortalView: UIView {

    public var sourceView: UIView? {
        // sourceView
        let aSelector = NSSelectorFromBase64EncodedString("c291cmNlVmlldw==")
        guard contentView.responds(to: aSelector) else { return nil }
        return contentView.perform(aSelector).takeUnretainedValue() as? UIView
    }

    let contentView: UIView

    public var hidesSourceView: Bool {
        get {
            // hidesSourceView
            guard
                let aSelector = NSStringFromBase64EncodedString("aGlkZXNTb3VyY2VWaWV3"),
                contentView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return contentView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            // setHidesSourceView:
            let aSelector = NSSelectorFromBase64EncodedString("c2V0SGlkZXNTb3VyY2VWaWV3Og==")
            guard contentView.responds(to: aSelector) else { return }
            contentView.perform(aSelector, with: newValue)
        }
    }

    public init?(sourceView: UIView) {
        let allocSelector = NSSelectorFromString("alloc")
        // initWithSourceView:
        let initSelector = NSSelectorFromBase64EncodedString("aW5pdFdpdGhTb3VyY2VWaWV3Og==")
        // _UIPortalView
        let portalViewClassName = NSStringFromBase64EncodedString("X1VJUG9ydGFsVmlldw==")
        guard
            let portalViewClassName = portalViewClassName,
            let portalViewClass = NSClassFromString(portalViewClassName) as? UIView.Type
        else {
            return nil
        }
        let instance = portalViewClass.perform(allocSelector).takeUnretainedValue()
        guard
            instance.responds(to: initSelector),
            let portalView = instance.perform(initSelector, with: sourceView).takeUnretainedValue() as? UIView
        else {
            return nil
        }
        contentView = portalView
        super.init(frame: sourceView.frame)
        addSubview(contentView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
}

#endif
