//
// Copyright (c) Nathan Tannar
//

import UIKit

open class PortalView: UIView {

    let contentView: UIView

    public var hidesSourceView: Bool {
        get {
            let aSelector = NSSelectorFromString("hidesSourceView")
            guard contentView.responds(to: aSelector) else { return false }
            return contentView.perform(aSelector).takeUnretainedValue() as? Bool ?? false
        }
        set {
            let aSelector = NSSelectorFromString("setHidesSourceView:")
            guard contentView.responds(to: aSelector) else { return }
            contentView.perform(aSelector, with: newValue)
        }
    }

    public init?(sourceView: UIView) {
        let allocSelector = NSSelectorFromString("alloc")
        let initSelector = NSSelectorFromString("initWithSourceView:")
        guard
            let portalViewClassName = String(data: Data(base64Encoded: "X1VJUG9ydGFsVmlldw==")!, encoding: .utf8), // _UIPortalView
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
