//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import Engine

open class PopoverDimmingView: DimmingView {

    open var passthroughViews: [UIView]?

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let passthroughViews {
            for passthroughView in passthroughViews where !passthroughView.isHidden && passthroughView.isUserInteractionEnabled {
                let pointInPassthroughView = convert(point, to: passthroughView)
                if passthroughView.bounds.contains(pointInPassthroughView) {
                    let hitTest = passthroughView.hitTest(point, with: event)
                    if hitTest == passthroughView, passthroughView is AnyHostingView {
                        if passthroughView.layer.sublayers?.contains(where: { !$0.isHidden && $0.frame.contains(pointInPassthroughView) }) == true {
                            return nil
                        }
                        for subview in passthroughView.subviews where !subview.isHidden && subview.isUserInteractionEnabled {
                            let pointInSubview = passthroughView.convert(pointInPassthroughView, to: subview)
                            if subview.bounds.contains(pointInSubview) {
                                if subview.hitTest(pointInSubview, with: event) != nil {
                                    return nil
                                }
                            }
                        }
                    } else if hitTest != nil {
                        return nil
                    }
                }
            }
        }
        return super.hitTest(point, with: event)
    }
}

open class PopoverPresentationController: UIPopoverPresentationController {

    public let dimmingView: PopoverDimmingView = {
        let view = PopoverDimmingView()
        view.alpha = 0
        return view
    }()

    open override var passthroughViews: [UIView]? {
        get { super.passthroughViews }
        set {
            dimmingView.passthroughViews = newValue
            if var newValue, !newValue.isEmpty {
                newValue.insert(dimmingView, at: 0)
                super.passthroughViews = newValue
            } else {
                super.passthroughViews = nil
            }
        }
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelectBackground))
        dimmingView.addGestureRecognizer(tapGesture)

        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            presentedViewController.view.superview?.clipsToBounds = false
            presentedViewController.view.superview?.cornerConfiguration = .corners(
                topLeftRadius: nil,
                topRightRadius: nil,
                bottomLeftRadius: nil,
                bottomRightRadius: nil
            )
        }
        #endif

        containerView?.insertSubview(dimmingView, at: 0)
        dimmingView.frame = containerView?.bounds ?? .zero

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated
        {
            transitionCoordinator.animate { _ in
                self.dimmingView.alpha = 1
            }
        } else {
            dimmingView.alpha = 1
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if !completed {
            dimmingView.alpha = 0
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated
        {
            transitionCoordinator.animate { _ in
                self.dimmingView.alpha = 0
            }
        } else {
            dimmingView.alpha = 0
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if !completed {
            dimmingView.alpha = 1
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        let hasTranslucentBackground = backgroundColor?.isTranslucent == true
        presentedView?.subviews.first?.isHidden = hasTranslucentBackground
        presentedView?.subviews.last?.subviews.first?.isHidden = hasTranslucentBackground
    }

    @objc
    private func didSelectBackground() {
        let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
        if shouldDismiss {
            presentedViewController.dismiss(animated: true)
        }
    }
}

#endif
