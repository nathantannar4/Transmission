//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

public protocol AnyHostingView: UIView {
    func render()
    func renderAsync()
}

extension _UIHostingView: AnyHostingView {
    public func render() {
        _renderForTest(interval: 1 / 60)
    }

    public func renderAsync() {
        if #available(iOS 15.0, *) {
            _renderAsyncForTest(interval: 1 / 60)
        } else {
            _renderForTest(interval: 1 / 60)
        }
    }
}

public protocol AnyHostingController: UIViewController {
    var disableSafeArea: Bool { get set }
    func render()
    func renderAsync()
}

extension UIHostingController: AnyHostingController {
    public var disableSafeArea: Bool {
        get { _disableSafeArea }
        set {
            if #available(macOS 13.3, iOS 16.4, tvOS 16.4, *) {
                safeAreaRegions = newValue ? [] : .all
            }
            _disableSafeArea = newValue
        }
    }
    
    public func render() {
        (view as! AnyHostingView).render()
    }

    public func renderAsync() {
        (view as! AnyHostingView).renderAsync()
    }
}

#endif
