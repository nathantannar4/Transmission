//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
class SlidePresentationController: InteractivePresentationController {

    var edge: Edge

    override var edges: Edge.Set {
        get { Edge.Set(edge) }
        set { }
    }

    override var presentationStyle: UIModalPresentationStyle { .overFullScreen }

    init(
        edge: Edge = .bottom,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }

    open override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint
    ) -> Bool {
        if edges.contains(.bottom), translation.y > 0 {
            return true
        }
        if edges.contains(.top), translation.y < 0 {
            return true
        }
        if edges.contains(.leading), translation.x < 0 {
            return true
        }
        if edges.contains(.trailing), translation.x > 0 {
            return true
        }
        return false
    }

    open override func dismissalTransitionShouldCancel(
        translation: CGPoint,
        delta: CGPoint
    ) -> Bool {
        if edges.contains(.bottom), translation.y >= 0 {
            return false
        }
        if edges.contains(.top), translation.y <= 0 {
            return false
        }
        if edges.contains(.leading), translation.x <= 0 {
            return false
        }
        if edges.contains(.trailing), translation.x >= 0 {
            return false
        }
        return true
    }

    override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        return .identity
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        presentingViewController.view.isHidden = presentedViewController.presentedViewController != nil
    }
}

@available(iOS 14.0, *)
class SlideTransition: PresentationControllerTransition {

    let options: PresentationLinkTransition.SlideTransitionOptions

    static let displayCornerRadius: CGFloat = {
        #if targetEnvironment(macCatalyst)
        return 12
        #else
        return max(UIScreen.main.displayCornerRadius, 12)
        #endif
    }()

    init(
        isPresenting: Bool,
        options: PresentationLinkTransition.SlideTransitionOptions
    ) {
        self.options = options
        super.init(isPresenting: isPresenting)
    }

    override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let isPresenting = isPresenting
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: completionCurve
        )

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        #if targetEnvironment(macCatalyst)
        let isScaleEnabled = false
        #else
        let isTranslucentBackground = options.options.preferredPresentationBackgroundUIColor?.isTranslucent ?? false
        let isScaleEnabled = options.prefersScaleEffect && !isTranslucentBackground && presenting.view.convert(presenting.view.frame.origin, to: nil).y == 0
        #endif
        let safeAreaInsets = transitionContext.containerView.safeAreaInsets
        let cornerRadius = options.preferredCornerRadius ?? Self.displayCornerRadius

        var dzTransform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        switch options.edge {
        case .top:
            dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.bottom / 2)
        case .bottom:
            dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.top / 2)
        case .leading:
            switch presented.traitCollection.layoutDirection {
            case .rightToLeft:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.left / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.right / 2)
            }
        case .trailing:
            switch presented.traitCollection.layoutDirection {
            case .leftToRight:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.right / 2)
            default:
                dzTransform = dzTransform.translatedBy(x: 0, y: safeAreaInsets.left / 2)
            }
        }

        presented.view.layer.masksToBounds = true
        presented.view.layer.cornerCurve = .continuous

        presenting.view.layer.masksToBounds = true
        presenting.view.layer.cornerCurve = .continuous

        let frame = transitionContext.finalFrame(for: presented)
        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = frame
            presented.view.transform = presentationTransform(
                presented: presented,
                frame: frame
            )
        } else {
            presented.view.layer.cornerRadius = cornerRadius
            #if !targetEnvironment(macCatalyst)
            if isScaleEnabled {
                presenting.view.transform = dzTransform
                presenting.view.layer.cornerRadius = cornerRadius
            }
            #endif
        }

        let presentedTransform = isPresenting ? .identity : presentationTransform(
            presented: presented,
            frame: frame
        )
        let presentingTransform = isPresenting && isScaleEnabled ? dzTransform : .identity
        animator.addAnimations {
            presented.view.transform = presentedTransform
            presented.view.layer.cornerRadius = isPresenting ? cornerRadius : 0
            presenting.view.transform = presentingTransform
            if isScaleEnabled {
                presenting.view.layer.cornerRadius = isPresenting ? cornerRadius : 0
            }
        }
        animator.addCompletion { animatingPosition in

            if presented.view.frame.origin.y == 0 {
                presented.view.layer.cornerRadius = 0
            }

            if isScaleEnabled {
                presenting.view.layer.cornerRadius = 0
                presenting.view.transform = .identity
            }

            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        return animator
    }

    private func presentationTransform(
        presented: UIViewController,
        frame: CGRect
    ) -> CGAffineTransform {
        switch options.edge {
        case .top:
            return CGAffineTransform(translationX: 0, y: -frame.maxY)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: frame.maxY)
        case .leading:
            switch presented.traitCollection.layoutDirection {
            case .rightToLeft:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        case .trailing:
            switch presented.traitCollection.layoutDirection {
            case .leftToRight:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        }
    }
}

#endif
