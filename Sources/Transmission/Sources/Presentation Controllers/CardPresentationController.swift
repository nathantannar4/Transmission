//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 14.0, *)
class CardPresentationController: InteractivePresentationController {

    var preferredEdgeInset: CGFloat? {
        didSet {
            guard oldValue != preferredEdgeInset else { return }
            updatePresentedView()
            containerView?.setNeedsLayout()
        }
    }

    var preferredCornerRadius: CGFloat? {
        didSet {
            guard oldValue != preferredCornerRadius else { return }
            updatePresentedView()
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView
        let isCompact = traitCollection.verticalSizeClass == .compact
        let keyboardOverlap = keyboardOverlapInContainerView(of: frame)
        let height = isCompact ? frame.height - keyboardOverlap : min(frame.height, 400)
        let width = isCompact ? frame.height : min(frame.width, height)
        frame = CGRect(
            x: frame.origin.x + (frame.width - width) / 2,
            y: frame.origin.y + (frame.height - height),
            width: width,
            height: height
        )
        if !isTransitioningSize {
            frame.origin.y -= keyboardOverlap
        }
        frame = frame.inset(
            by: UIEdgeInsets(
                top: edgeInset,
                left: edgeInset,
                bottom: edgeInset,
                right: edgeInset
            )
        )
        return frame
    }

    private var edgeInset: CGFloat {
        preferredEdgeInset ?? 4
    }

    private var cornerRadius: CGFloat {
        preferredCornerRadius ?? max(12, UIScreen.main.displayCornerRadius - edgeInset)
    }

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        view.alpha = 0
        return view
    }()

    init(
        preferredEdgeInset: CGFloat?,
        preferredCornerRadius: CGFloat?,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredEdgeInset = preferredEdgeInset
        self.preferredCornerRadius = preferredCornerRadius
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )

        shouldAutomaticallyAdjustFrameForKeyboard = false
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.addSubview(dimmingView)
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectBackground))
        )

        presentedViewController.view.layer.masksToBounds = true
        updatePresentedView()
    }

    override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)
        dimmingView.alpha = isPresented ? 1 : 0
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        updatePresentedView()
    }

    override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)
        updatePresentedViewSafeArea(transform: transform)
    }

    private func updatePresentedView() {
        presentedViewController.view.layer.cornerRadius = cornerRadius
        updatePresentedViewSafeArea(transform: presentedViewController.view.transform)
    }

    private func updatePresentedViewSafeArea(transform: CGAffineTransform) {
        let inset = cornerRadius / 2
        let bottomSafeArea = max(inset, (containerView?.safeAreaInsets.bottom ?? 0))
        let scale = presentedViewController.view.window?.screen.scale ?? 1
        let dy = transform.ty.rounded(scale: scale)
        let bottomInset = max(min(-min(0, dy), bottomSafeArea - edgeInset), min(inset, keyboardHeight))
        presentedViewController.additionalSafeAreaInsets = UIEdgeInsets(
            top: inset,
            left: inset,
            bottom: bottomInset,
            right: inset
        )
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
