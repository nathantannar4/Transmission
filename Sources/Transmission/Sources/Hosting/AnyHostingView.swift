//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

public protocol AnyHostingView: UIView {
    func render()
}

extension _UIHostingView: AnyHostingView {
    public func render() {
        _renderForTest(interval: 1 / 60)
    }
}

public protocol AnyHostingController: UIViewController {
    func render()
}

extension UIHostingController: AnyHostingController {
    public func render() {
        (view as! AnyHostingView).render()
    }
}

extension UIView {
    var hostingView: AnyHostingView? {
        var view = superview
        while view != nil {
            if let host = view as? AnyHostingView {
                return host
            }
            view = view?.superview
        }
        return nil
    }
}

#endif
