//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

@frozen
@MainActor @preconcurrency
public struct ZoomTransitionOptions {
    public var dimmingColor: Color?
    public var dimmingVisualEffect: UIBlurEffect.Style?
    public var prefersScalePresentingView: Bool

    public init(
        dimmingColor: Color? = nil,
        dimmingVisualEffect: UIBlurEffect.Style? = nil,
        prefersScalePresentingView: Bool
    ) {
        self.dimmingColor = dimmingColor
        self.dimmingVisualEffect = dimmingVisualEffect
        self.prefersScalePresentingView = prefersScalePresentingView
    }

    @available(iOS 18.0, *)
    func toUIKit() -> UIViewController.Transition.ZoomOptions {
        let options = UIViewController.Transition.ZoomOptions()
        options.dimmingColor = dimmingColor?.toUIColor()
        options.dimmingVisualEffect = dimmingVisualEffect.map { UIBlurEffect(style: $0) }
        if #available(iOS 26.0, *) {
            options.recedesPresentingView = prefersScalePresentingView
        }
        return options
    }
}

@available(iOS 18.0, *)
extension UIViewController.Transition.ZoomOptions {

    @available(iOS 26.0, *)
    var recedesPresentingView: Bool {
        get {
            // _recedesPresentingView
            guard
                let aSelector = NSStringFromBase64EncodedString("X3JlY2VkZXNQcmVzZW50aW5nVmlldw=="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? Bool
            else {
                return true
            }
            return value
        }
        set {
            // _recedesPresentingView
            guard
                let aSelector = NSStringFromBase64EncodedString("X3JlY2VkZXNQcmVzZW50aW5nVmlldw=="),
                responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            return setValue(newValue, forKey: aSelector)
        }
    }
}

#endif
