//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that presents the view from a source view rect
@available(iOS 14.0, *)
open class MatchedGeometryPresentationController: InteractivePresentationController {

    public var minimumScaleFactor: CGFloat

    open override var wantsInteractiveDismissal: Bool {
        return true
    }

    public init(
        edges: Edge.Set = .all,
        dimmingColor: Color? = nil,
        minimumScaleFactor: CGFloat = 0.5,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.minimumScaleFactor = minimumScaleFactor
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        self.edges = edges
        if let dimmingColor {
            self.dimmingView.backgroundColor = dimmingColor.toUIColor()
        }
        dimmingView.isHidden = false
    }

    open override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        guard !panGesture.isInteracting else { return false }
        var shouldBegin = false
        if !shouldBegin, edges.contains(.bottom), translation.y > 0 {
            shouldBegin = (translation.y >= UIGestureRecognizer.zoomGestureActivationThreshold.height && velocity.y >= 0) || velocity.y >= 1000
        }
        if !shouldBegin, edges.contains(.top), translation.y < 0 {
            shouldBegin = (abs(translation.y) >= UIGestureRecognizer.zoomGestureActivationThreshold.height && velocity.y <= 0) || velocity.y <= -1000
        }
        if !shouldBegin, edges.contains(.leading), translation.x < 0 {
            shouldBegin = (abs(translation.x) >= UIGestureRecognizer.zoomGestureActivationThreshold.width && velocity.x <= 0) || velocity.x <= -1000
        }
        if !shouldBegin, edges.contains(.trailing), translation.x > 0 {
            shouldBegin = (translation.x >= UIGestureRecognizer.zoomGestureActivationThreshold.height && velocity.x >= 0) || velocity.x >= 1000
        }
        return shouldBegin
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedView?.layer.cornerCurve = .continuous
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedView?.layer.cornerRadius = 0
        }
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)
        guard let presentedView else { return }
        if transform.isIdentity {
            CornerRadiusOptions.identity.apply(to: presentedView)
            dimmingView.alpha = 1
        } else {
            let transformProgress: CGFloat = {
                let frame = presentedView.bounds
                let dx = abs(transform.tx) / frame.width
                let dy = abs(transform.ty) / frame.height
                return min((1 - max(dx, dy)), min(transform.a, transform.d))
            }()
            let progress = max(0, min(transformProgress, 1))
            var cornerRadius = CornerRadiusOptions.RoundedRectangle.screen(min: 0)
            if let radius = cornerRadius.cornerRadii?.uniformCornerRadius {
                cornerRadius.cornerRadii = CornerRadiusOptions.CornerRadii(cornerRadius: radius * progress)
            }
            cornerRadius.apply(to: presentedView)
            dimmingView.alpha = progress
        }
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let frame = frameOfPresentedViewInContainerView
        let dx = frictionCurve(translation.x, distance: frame.width, coefficient: 0.5)
        let dy = frictionCurve(translation.y, distance: frame.height, coefficient: 1)
        let progress = max(abs(dx) / frame.width, abs(dy) / frame.height)
        let scale = max(minimumScaleFactor, 1 - progress * (1 - minimumScaleFactor))
        let cx = (1 - scale) * frame.width * 0.5
        let cy = (1 - scale) * frame.height * 0.5
        return CGAffineTransform(translationX: dx + cx, y: dy + cy)
            .scaledBy(x: scale, y: scale)
    }
}

#endif
