//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

#if targetEnvironment(macCatalyst)
@available(iOS 15.0, *)
public typealias SheetPresentationController = MacSheetPresentationController

@available(iOS 15.0, *)
open class MacSheetTransition: SlidePresentationControllerTransition {

    public init(
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        isPresenting: Bool,
        animation: Animation?
    ) {
        let cornerRadius = preferredCornerRadius ?? .rounded(cornerRadius: 12)
        super.init(
            edge: .bottom,
            prefersScaleEffect: false,
            preferredFromCornerRadius: cornerRadius,
            preferredToCornerRadius: cornerRadius,
            isPresenting: isPresenting,
            animation: animation
        )
    }
}

@available(iOS 15.0, *)
open class MacSheetPresentationController: SlidePresentationController {

    public var detent: PresentationLinkTransition.SheetTransitionOptions.Detent = .large {
        didSet {
            dimmingView.isHidden = largestUndimmedDetentIdentifier == detent.identifier
        }
    }

    var selected: Binding<PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?>?
    var largestUndimmedDetentIdentifier: PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?

    private var prevPresentationController: MacSheetPresentationController? {
        presentingViewController._activePresentationController as? MacSheetPresentationController
    }

    private var depth = 0 {
        didSet {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
            dimmingView.alpha = depth > 0 ? 0 : 1
        }
    }

    private func push() {
        prevPresentationController?.depth += 1
        prevPresentationController?.prevPresentationController?.depth += 1
    }

    private func pop() {
        prevPresentationController?.depth -= 1
        prevPresentationController?.prevPresentationController?.depth -= 1
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        let frame = super.frameOfPresentedViewInContainerView.inset(by: containerView?.safeAreaInsets ?? .zero)
        let isPinnedToEdges = frame.size.height > (1.5 * frame.size.width)
        let targetRect: CGRect = {
            if isPinnedToEdges {
                let height = (frame.size.height * 0.95).rounded(.up)
                return CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y + (frame.size.height - height),
                    width: frame.size.width,
                    height: height
                )
            } else {
                let width = (frame.size.width * 0.85).rounded(.up)
                let height = (frame.size.height * 0.85).rounded(.up)
                return CGRect(
                    x: frame.origin.x + (frame.size.width - width) / 2,
                    y: frame.origin.y + (frame.size.height - height) / 2,
                    width: width,
                    height: height
                )
            }
        }()
        switch detent.identifier {
        case .large:
            return targetRect

        case .medium:
            let height = (frame.size.height / 2).rounded(.up)
            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - height : targetRect.origin.y + (targetRect.size.height - height) / 2,
                width: targetRect.width,
                height: height
            )

        case .ideal:
            let targetHeight = presentedViewController.view.idealHeight(for: targetRect.width)

            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - targetHeight : targetRect.origin.y + (targetRect.size.height - targetHeight) / 2,
                width: targetRect.width,
                height: targetHeight
            )

        default:
            let height: CGFloat
            if let constant = detent.height {
                height = min(constant, targetRect.size.height)
            } else if let resolution = detent.resolution {
                height = resolution(
                    .init(
                        containerTraitCollection: traitCollection,
                        maximumDetentValue: targetRect.size.height,
                        idealDetentValue: { [weak presentedViewController] in
                            guard let presentedViewController else { return 0 }
                            let targetHeight = presentedViewController.view.idealHeight(for: targetRect.width)
                            return targetHeight
                        }
                    )
                ) ?? targetRect.size.height
            } else {
                return targetRect
            }
            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - height : targetRect.origin.y + (targetRect.size.height - height) / 2,
                width: targetRect.width,
                height: height
            )
        }
    }

    public init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            edge: .bottom,
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        preferredShadow = .minimal
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        selected?.wrappedValue = detent.identifier

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.push()
            }, completion: { [unowned self] ctx in
                if ctx.isCancelled {
                    self.pop()
                }
            })
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if !completed {
            selected?.wrappedValue = nil
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.pop()
            }, completion: { [unowned self] ctx in
                if ctx.isCancelled {
                    self.push()
                }
            })
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            selected?.wrappedValue = nil
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        if let presentedView = presentedView {
            let isPinnedToEdges = presentedView.frame.size.height > (1.5 * presentedView.frame.size.width)
            presentedView.layer.maskedCorners = isPinnedToEdges
                ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                : [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }

    open override func layoutPresentedView(frame: CGRect) {
        presentedView?.transform = .identity
        super.layoutPresentedView(frame: frame)
        if depth > 0 {
            let scale: CGFloat = pow(0.92, CGFloat(depth))
            presentedView?.transform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: 0, y: (frame.height * -0.08))
        } else {
            presentedView?.transform = .identity
        }
    }
}
#else
@available(iOS 15.0, *)
open class SheetPresentationController: UISheetPresentationController {

    public var preferredCornerRadiusOptions: CornerRadiusOptions.RoundedRectangle? {
        didSet {
            guard oldValue != preferredCornerRadiusOptions else { return }
            updateCornerRadius()
        }
    }

    public var preferredBackground: BackgroundOptions? {
        didSet {
            guard oldValue != preferredBackground else { return }
            updateBackground()
            updateShadow()
        }
    }

    public var preferredPresentationBackgroundColor: UIColor? {
        didSet {
            guard oldValue != preferredPresentationBackgroundColor else { return }
            updateBackground()
        }
    }

    public var preferredShadow: ShadowOptions? {
        didSet {
            guard oldValue != preferredShadow else { return }
            updateShadow()
        }
    }

    public let presentedContainerView = PresentedContainerView()

    open override var selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier? {
        didSet {
            guard oldValue != selectedDetentIdentifier else { return }
            lastSelectedDetentIdentifier = nil
            updateBackgroundInteraction()
        }
    }
    private var lastSelectedDetentIdentifier: UISheetPresentationController.Detent.Identifier?

//    open override var presentedView: UIView? {
//        let presentedView = super.presentedView
//        if let presentedView {
//            presentedContainerView.presentedView = presentedView
//        }
//        return presentedContainerView
//    }

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        updateBackground()
        updateCornerRadius()
        updateShadow()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.fixSwiftUIHitTesting()
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if !completed {
            presentedViewController.fixSwiftUIHitTesting()
        }
    }

    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if lastSelectedDetentIdentifier != selectedDetentIdentifier {
            updateBackgroundInteraction()
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        updateCornerRadius()
        lastSelectedDetentIdentifier = selectedDetentIdentifier
    }

    private func updateBackgroundInteraction() {
        presentedContainerView.prefersInteractiveBackground = selectedDetentIdentifier != .large
    }

    private func updateShadow() {
        if case .glass = preferredBackground?.effect?.storage {
            ShadowOptions.clear.apply(to: presentedContainerView.layer)
        } else {
            (preferredShadow ?? .feather).apply(to: presentedContainerView.layer)
        }
    }

    private func updateCornerRadius() {
        preferredCornerRadius = preferredCornerRadiusOptions?.cornerRadius
        var didUseCornerConfiguration = false
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels) // Xcode 26
            let topCornerRadius = preferredCornerRadiusOptions?.cornerRadius ?? 38
            let cornerConfiguration = UICornerConfiguration.corners(
                topLeftRadius: .containerConcentric(minimum: topCornerRadius),
                topRightRadius: .containerConcentric(minimum: topCornerRadius),
                bottomLeftRadius: .containerConcentric(),
                bottomRightRadius: .containerConcentric()
            )
            presentedContainerView.updateCornerConfiguration(cornerConfiguration)
            presentedContainerView.layer.cornerCurve = .continuous
            didUseCornerConfiguration = true
            #endif
        }
        if !didUseCornerConfiguration {
            var cornerRadius = preferredCornerRadiusOptions ?? .rounded(cornerRadius: 10, style: .continuous)
            cornerRadius.mask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            presentedContainerView.updateCornerRadius(cornerRadius)
        }
    }

    private func updateBackground() {
        if #available(iOS 26.0, *) {
            var hasBackgroundEffect = preferredBackground?.effect != nil
            let hasTranslucentBackground = preferredPresentationBackgroundColor?.isTranslucent == true && !hasBackgroundEffect
            if case .glass(let glassEffect) = preferredBackground?.effect?.storage, glassEffect == .regular {
                // Use default system effect
                hasBackgroundEffect = false
            }
            let hasBackgroundColor = preferredBackground?.color != nil
            let hasBackground = hasBackgroundEffect || hasBackgroundColor
            // _setLargeBackground:
            let aSelectorSetLargeBackground = NSSelectorFromBase64EncodedString("X3NldExhcmdlQmFja2dyb3VuZDo=")
            if responds(to: aSelectorSetLargeBackground) {
                perform(aSelectorSetLargeBackground, with: hasBackground ? UIColor.clear : nil)
            }
            // _setNonLargeBackground:
            let aSelectorSetNonLargeBackground = NSSelectorFromBase64EncodedString("X3NldE5vbkxhcmdlQmFja2dyb3VuZDo=")
            if responds(to: aSelectorSetNonLargeBackground) {
                perform(aSelectorSetNonLargeBackground, with: hasBackground || hasTranslucentBackground ? UIColor.clear : nil)
            }
            presentedContainerView.preferredBackground = preferredBackground
        } else {
            presentedContainerView.preferredBackground = preferredBackground
        }
    }
}

#endif

@available(iOS 15.0, *)
extension PresentationLinkTransition.SheetTransitionOptions {
    static func update(
        presentationController: SheetPresentationController,
        animated isAnimated: Bool,
        from oldValue: Self,
        to newValue: Self
    ) {
        let detents = newValue.detents
        #if targetEnvironment(macCatalyst)
        let hasChanges: Bool = {
            if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = newValue.selected,
                presentationController.detent.identifier != selected.wrappedValue
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            return false
        }()
        #else
        presentationController.preferredBackground = newValue.preferredBackground
        presentationController.preferredPresentationBackgroundColor = newValue.options.preferredPresentationBackgroundUIColor
        presentationController.preferredShadow = newValue.preferredPresentationShadow
        let selectedDetentIdentifier = newValue.selected?.wrappedValue?.toUIKit()
        let hasChanges: Bool = {
            if oldValue.preferredCornerRadius != newValue.preferredCornerRadius {
                return true
            } else if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = selectedDetentIdentifier,
                      presentationController.selectedDetentIdentifier != selected
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            if #available(iOS 17.0, *), oldValue.prefersPageSizing != newValue.prefersPageSizing {
                return true
            }
            return false
        }()
        #endif
        if hasChanges {
            func applyConfiguration() {
                #if targetEnvironment(macCatalyst)
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier
                presentationController.selected = newValue.selected
                let selected = newValue.selected?.wrappedValue
                presentationController.detent = detents.first(where: { $0.identifier == selected }) ?? detents.first ?? .large
                #else
                presentationController.detents = detents.map { $0.toUIKit(in: presentationController) }
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier?.toUIKit()
                if let selected = newValue.selected {
                    presentationController.selectedDetentIdentifier = selected.wrappedValue?.toUIKit()
                }
                presentationController.preferredCornerRadiusOptions = newValue.preferredCornerRadius
                if #available(iOS 17.0, *) {
                    presentationController.prefersPageSizing = newValue.prefersPageSizing
                }
                #endif
            }
            if isAnimated {
                withCATransaction {
                    #if targetEnvironment(macCatalyst)
                    UIView.animate(withDuration: 0.35) {
                        applyConfiguration()
                    }
                    #else
                    presentationController.animateChanges {
                        applyConfiguration()
                    }
                    #endif
                }
            } else {
                applyConfiguration()
            }
        }
    }
}

#endif
