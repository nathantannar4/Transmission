//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Turbocharger

open class HostingView<
    Content: View
>: _UIHostingView<Content> {

    public var content: Content {
        get {
            if #available(iOS 16.0, *) {
                return rootView
            } else {
                do {
                    return try swift_getFieldValue("_rootView", Content.self, self)
                } catch {
                    fatalError("\(error)")
                }
            }
        }
        set {
            if #available(iOS 16.0, *) {
                rootView = newValue
            } else {
                do {
                    var flags = try swift_getFieldValue("propertiesNeedingUpdate", UInt16.self, self)
                    try swift_setFieldValue("_rootView", newValue, self)
                    flags |= 1
                    try swift_setFieldValue("propertiesNeedingUpdate", flags, self)
                    setNeedsLayout()
                } catch {
                    fatalError("\(error)")
                }
            }
        }
    }

    public var disablesSafeArea: Bool = false

    public override var safeAreaInsets: UIEdgeInsets {
        if disablesSafeArea {
            return .zero
        }
        return super.safeAreaInsets
    }

    public init(content: Content) {
        super.init(rootView: content)
        backgroundColor = nil
    }

    public convenience init(@ViewBuilder content: () -> Content) {
        self.init(content: content())
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    public required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = super.hitTest(point, with: event), result != self else {
            return nil
        }
        return result
    }
}

#endif
