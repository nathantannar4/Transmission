//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

@frozen
public struct ZoomTransitionOptions: Sendable {

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

    @MainActor @preconcurrency
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

#endif
