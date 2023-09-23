//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore
import Turbocharger

open class HostingController<
    Content: View
>: _HostingController<Content> {

    public var content: Content {
        get { rootView }
        set { rootView = newValue }
    }

    public var tracksContentSize: Bool = false {
        didSet {
            view.setNeedsLayout()
        }
    }

    public override init(content: Content) {
        super.init(content: content)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard view.superview != nil, !isBeingDismissed else {
            return
        }

        let isAnimated = isBeingPresented ? false : transitionCoordinator?.isAnimated ?? true

        if tracksContentSize, #available(iOS 15.0, *),
            presentingViewController != nil,
            let sheetPresentationController = presentationController as? UISheetPresentationController,
            sheetPresentationController.presentedViewController == self,
            let containerView = sheetPresentationController.containerView
        {
            guard
                let selectedIdentifier = sheetPresentationController.selectedDetentIdentifier,
                let detent = sheetPresentationController.detents.first(where: { $0.id == selectedIdentifier.rawValue && $0.isDynamic })
            else {
                return
            }

            let resolvedDetentHeight = detent.resolvedValue(
                containerTraitCollection: sheetPresentationController.traitCollection,
                maximumDetentValue: containerView.frame.height
            )
            guard let resolvedDetentHeight,
                resolvedDetentHeight != view.frame.height - (view.safeAreaInsets.top + view.safeAreaInsets.bottom)
            else {
                return
            }

            func performTransition(animated: Bool, completion: (() -> Void)? = nil) {
                if #available(iOS 16.0, *) {
                    sheetPresentationController.invalidateDetents()
                } else {
                    sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
                }
                if animated {
                    UIView.transition(
                        with: containerView,
                        duration: 0.35,
                        options: [.beginFromCurrentState, .curveEaseInOut]
                    ) {
                        containerView.layoutIfNeeded()
                    } completion: { _ in
                        completion?()
                    }
                } else {
                    containerView.layoutIfNeeded()
                    completion?()
                }
            }

            if #available(iOS 16.0, *) {
                try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", isAnimated, view)
                performTransition(animated: isAnimated) {
                    try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", false, self.view)
                }
            } else {
                withCATransaction {
                    performTransition(animated: isAnimated)
                }
            }

        } else if tracksContentSize {
            if #available(iOS 16.0, *) {
                if presentingViewController != nil,
                    let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    popoverPresentationController.presentedViewController == self,
                    let containerView = popoverPresentationController.containerView
                {
                    var newSize = view.systemLayoutSizeFitting(
                        UIView.layoutFittingExpandedSize
                    )
                    // Arrow Height
                    switch popoverPresentationController.arrowDirection {
                    case .up, .down:
                        newSize.height += 6
                    case .left, .right:
                        newSize.width += 6
                    default:
                        break
                    }
                    let oldSize = preferredContentSize
                    if oldSize == .zero || !isAnimated {
                        preferredContentSize = newSize
                    } else if oldSize != newSize {
                        let dz = (newSize.width * newSize.height) - (oldSize.width * oldSize.height)
                        try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", isAnimated, view)
                        UIView.transition(
                            with: containerView,
                            duration: 0.35 + (dz > 0 ? 0.15 : -0.05),
                            options: [.beginFromCurrentState, .curveEaseInOut]
                        ) {
                            self.preferredContentSize = newSize
                        } completion: { _ in
                            try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", false, self.view)
                        }
                    }
                }
            } else {
                preferredContentSize = view.systemLayoutSizeFitting(
                    UIView.layoutFittingExpandedSize
                )
            }
        }
    }
}

open class _HostingController<
    Content: View
>: UIHostingController<Content> {

    public var disablesSafeArea: Bool {
        get { _disableSafeArea }
        set { _disableSafeArea = newValue }
    }

    public init(content: Content) {
        super.init(rootView: content)
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    override init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
    }
}

#endif
