//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
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
        if tracksContentSize, #available(iOS 15.0, *), let sheetPresentationController = presentationController as? UISheetPresentationController,
            let containerView = sheetPresentationController.containerView
        {
            func performTransition() {
                UIView.transition(
                    with: containerView,
                    duration: 0.35,
                    options: [.beginFromCurrentState, .curveEaseInOut]
                ) {
                    if #available(iOS 16.0, *) {
                        sheetPresentationController.invalidateDetents()
                    } else {
                        sheetPresentationController.delegate?.sheetPresentationControllerDidChangeSelectedDetentIdentifier?(sheetPresentationController)
                    }
                    (containerView.superview ?? containerView).layoutIfNeeded()
                }
            }

            if #available(iOS 16.0, *) {
                try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", true, view)
                performTransition()
            } else {
                withCATransaction {
                    performTransition()
                }
            }
        } else if tracksContentSize {
            if #available(iOS 16.0, *) {
                try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", true, view)
                if let popoverPresentationController = presentationController as? UIPopoverPresentationController,
                    let containerView = popoverPresentationController.containerView
                {
                    var newSize = view.systemLayoutSizeFitting(
                        UIView.layoutFittingCompressedSize
                    )
                    newSize.height -= (view.safeAreaInsets.top + view.safeAreaInsets.bottom)
                    newSize.width -= (view.safeAreaInsets.left + view.safeAreaInsets.right)
                    let oldSize = preferredContentSize
                    if oldSize != newSize {
                        let dz = (newSize.width * newSize.height) - (oldSize.width * oldSize.height)
                        UIView.transition(
                            with: containerView,
                            duration: 0.35 + (dz > 0 ? 0.15 : -0.05),
                            options: [.beginFromCurrentState, .curveEaseInOut]
                        ) {
                            self.preferredContentSize = newSize
                        }
                    }
                }
            } else {
                var size = view.systemLayoutSizeFitting(
                    UIView.layoutFittingCompressedSize
                )
                size.height -= (view.safeAreaInsets.top + view.safeAreaInsets.bottom)
                size.width -= (view.safeAreaInsets.left + view.safeAreaInsets.right)
                preferredContentSize = size
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
}

#endif
