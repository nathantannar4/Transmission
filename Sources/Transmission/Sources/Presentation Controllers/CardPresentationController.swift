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
        guard let presentedView else { return frame }
        let isCompact = traitCollection.verticalSizeClass == .compact
        let keyboardOverlap = keyboardOverlapInContainerView(
            of: frame,
            keyboardHeight: keyboardHeight
        )
        let width = isCompact ? frame.height : frame.width
        let fittingSize = CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let sizeThatFits = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        let height = isCompact ? frame.height - keyboardOverlap : min(frame.height, max(sizeThatFits.height - presentedView.safeAreaInsets.top - presentedView.safeAreaInsets.bottom, frame.width))
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
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.addSubview(dimmingView)
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectBackground))
        )

        updatePresentedView()
    }

    override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)
        dimmingView.alpha = isPresented ? 1 : 0
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        if shouldAutoLayoutPresentedView {
            updatePresentedView()
        }
    }

    override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        if wantsInteractiveDismissal {
            let percentage = translation.y / presentedViewController.view.frame.height
            let magnitude = sqrt(pow(velocity.y, 2) + pow(velocity.x, 2))
            return (percentage >= 0.5 && magnitude > 0) || (magnitude >= 1000 && velocity.y > 0)
        } else {
            return super.dismissalTransitionShouldBegin(
                translation: translation,
                delta: delta,
                velocity: velocity
            )
        }
    }

    override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        var edgeInsets = super.presentedViewAdditionalSafeAreaInsets()
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        edgeInsets.bottom = max(0, min(safeAreaInsets.bottom - edgeInset, edgeInsets.bottom))
        return edgeInsets
    }

    private func updatePresentedView() {
        presentedViewController.view.layer.masksToBounds = cornerRadius > 0
        presentedViewController.view.layer.cornerRadius = cornerRadius
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
