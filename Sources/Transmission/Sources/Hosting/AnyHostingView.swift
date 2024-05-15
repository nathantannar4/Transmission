//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

public protocol AnyHostingView: UIView {
    func render()
}

extension _UIHostingView: AnyHostingView {
    public func render() {
        _renderForTest(interval: 1 / 60)
    }
}

public protocol AnyHostingController: UIViewController {
    var disableSafeArea: Bool { get set }
    func render()
}

extension UIHostingController: AnyHostingController {
    public var disableSafeArea: Bool {
        get { _disableSafeArea }
        set { _disableSafeArea = newValue }
    }
    
    public func render() {
        (view as! AnyHostingView).render()
    }
}

#endif
