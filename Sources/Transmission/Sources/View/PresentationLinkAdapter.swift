//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore
import Turbocharger

/// A modifier that presents a destination view in a new `UIViewController`.
///
/// To present the destination view with an animation, `isPresented` should
/// be updated with a transaction that has an animation. For example:
///
/// ```
/// withAnimation {
///     isPresented = true
/// }
/// ```
///
/// The destination view is presented with the provided `transition`.
/// By default, the ``PresentationLinkTransition/default`` transition is used.
///
/// See Also:
///  - ``PresentationLinkTransition``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with a `UIPresentationController` and/or
/// `UIViewControllerInteractiveTransitioning` with the ``PresentationLinkTransition/custom(_:)``
///  transition.
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct PresentationLinkAdapter<
    Destination: View
>: ViewModifier {

    var transition: PresentationLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination

    public init(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        destination: Destination
    ) {
        self.transition = transition
        self.isPresented = isPresented
        self.destination = destination
    }

    public func body(content: Content) -> some View {
        content.background(
            PresentationLinkAdapterBody(
                transition: transition,
                isPresented: isPresented,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    /// A modifier that presents a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkAdapter``
    ///
    public func presentation<Destination: View>(
        transition: PresentationLinkTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        modifier(
            PresentationLinkAdapter(
                transition: transition,
                isPresented: isPresented,
                destination: destination()
            )
        )
    }

    /// A modifier that presents a destination view in a new `UIViewController`.
    ///
    /// See Also:
    ///  - ``PresentationLinkAdapter``
    ///  
    public func presentation<T, Destination: View>(
        _ value: Binding<T?>,
        transition: PresentationLinkTransition = .default,
        @ViewBuilder destination: (Binding<T>) -> Destination
    ) -> some View {
        presentation(transition: transition, isPresented: value.isNotNil()) {
            OptionalAdapter(value, content: destination)
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PresentationLinkAdapterBody<
    Destination: View
>: UIViewRepresentable {

    var transition: PresentationLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination

    @WeakState var presentingViewController: UIViewController?

    typealias DestinationViewController = HostingController<ModifiedContent<Destination, PresentationBridgeAdapter>>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(
            presentingViewController: $presentingViewController
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        if let presentingViewController = presentingViewController, isPresented.wrappedValue {

            context.coordinator.isPresented = isPresented

            let traits = UITraitCollection(traitsFrom: [
                presentingViewController.traitCollection,
                UITraitCollection(userInterfaceStyle: .init(context.environment.colorScheme)),
                UITraitCollection(layoutDirection: .init(context.environment.layoutDirection)),
                UITraitCollection(verticalSizeClass: .init(context.environment.verticalSizeClass)),
                UITraitCollection(horizontalSizeClass: .init(context.environment.horizontalSizeClass)),
                UITraitCollection(accessibilityContrast: .init(context.environment.colorSchemeContrast)),
                UITraitCollection(legibilityWeight: .init(context.environment.legibilityWeight)),
                UITraitCollection(displayScale: context.environment.displayScale),
                UITraitCollection(activeAppearance: .unspecified),
                UITraitCollection(userInterfaceLevel: .elevated)
            ])

            let isAnimated = context.transaction.isAnimated || (presentingViewController.transitionCoordinator?.isAnimated ?? false)
            if let adapter = context.coordinator.adapter, !context.coordinator.isBeingReused {

                
                switch (adapter.transition, transition.value) {
                case (.sheet(let oldValue), .sheet(let newValue)):
                    adapter.transition = .sheet(newValue)

                    guard #available(iOS 15.0, *), let presentationController = adapter.viewController.presentationController as? SheetPresentationController
                    else {
                        break
                    }
                    PresentationLinkTransition.SheetTransitionOptions.update(
                        presentationController: presentationController,
                        animated: isAnimated,
                        from: oldValue,
                        to: newValue
                    )

                case (.popover(let oldValue), .popover(let newValue)):
                    adapter.transition = .popover(newValue)

                    if let presentationController = adapter.viewController.presentationController as? UIPopoverPresentationController {
                        presentationController.permittedArrowDirections = newValue.permittedArrowDirections(
                            layoutDirection: traits.layoutDirection
                        )
                        presentationController.backgroundColor = newValue.options.preferredPresentationBackgroundUIColor
                    } else if #available(iOS 15.0, *) {
                        if let newValue = newValue.adaptiveTransition,
                            let presentationController = adapter.viewController.presentationController as? SheetPresentationController
                        {
                            PresentationLinkTransition.SheetTransitionOptions.update(
                                presentationController: presentationController,
                                animated: isAnimated,
                                from: oldValue.adaptiveTransition ?? .init(),
                                to: newValue
                            )
                        }
                    }

                case (.slide(let oldValue), .slide(let newValue)):
                    adapter.transition = .slide(newValue)

                    if oldValue.edge != newValue.edge,
                        let presentationController = adapter.viewController.presentationController as? SlidePresentationController
                    {
                        presentationController.edge = newValue.edge
                    }

                default:
                    adapter.transition = transition.value
                }

                adapter.viewController.presentationController?.overrideTraitCollection = traits

                adapter.update(
                    destination: destination,
                    isPresented: isPresented,
                    sourceView: uiView,
                    context: context
                )
            } else {
                let adapter: PresentationLinkDestinationViewControllerAdapter<Destination>
                let isPresented: Binding<Bool> = Binding(
                    get: { self.isPresented.wrappedValue },
                    set: { newValue, transaction in
                        self.isPresented.transaction(transaction).wrappedValue = newValue
                        if let hostingView = presentingViewController.view as? AnyHostingView {
                            hostingView.render()
                        }
                    }
                )
                if let oldValue = context.coordinator.adapter {
                    adapter = oldValue
                    adapter.transition = transition.value
                    adapter.update(
                        destination: destination,
                        isPresented: isPresented,
                        sourceView: uiView,
                        context: context
                    )
                    context.coordinator.isBeingReused = false
                } else {
                    adapter = PresentationLinkDestinationViewControllerAdapter(
                        destination: destination,
                        isPresented: isPresented,
                        sourceView: uiView,
                        transition: transition.value,
                        context: context
                    )
                    context.coordinator.adapter = adapter
                }

                if adapter.viewController.transitioningDelegate == nil {
                    adapter.viewController.transitioningDelegate = context.coordinator
                } else if case .default = adapter.transition {
                    switch adapter.transition {
                    case .`default`:
                        break
                    default:
                        adapter.viewController.transitioningDelegate = context.coordinator
                    }
                }

                switch adapter.transition {
                case .currentContext:
                    // transitioningDelegate + .custom breaks .overCurrentContext
                    adapter.viewController.modalPresentationStyle = .overCurrentContext
                    adapter.viewController.presentationController?.overrideTraitCollection = traits

                case .fullscreen, .sheet, .popover, .`default`:
                    switch adapter.transition {
                    case .sheet, .popover, .fullscreen:
                        adapter.viewController.modalPresentationStyle = .custom

                    default:
                        break
                    }

                    if let presentationController = adapter.viewController.presentationController {
                        presentationController.delegate = context.coordinator
                        presentationController.overrideTraitCollection = traits

                        if #available(iOS 15.0, *),
                           let sheetPresentationController = presentationController as? UISheetPresentationController
                        {
                            sheetPresentationController.delegate = context.coordinator
                            if case .sheet(let options) = adapter.transition,
                                options.prefersSourceViewAlignment
                            {
                                sheetPresentationController.sourceView = uiView
                            }
                        } else if let popoverPresentationController = presentationController as? UIPopoverPresentationController {
                            popoverPresentationController.delegate = context.coordinator
                            popoverPresentationController.sourceView = uiView
                            if case .popover(let options) = adapter.transition {
                                let permittedArrowDirections = options.permittedArrowDirections(
                                    layoutDirection: traits.layoutDirection
                                )
                                popoverPresentationController.permittedArrowDirections = permittedArrowDirections
                                popoverPresentationController.backgroundColor = options.options.preferredPresentationBackgroundUIColor
                            }
                        }
                    }

                case .slide:
                    adapter.viewController.modalPresentationStyle = .custom

                case .custom(_, let delegate):
                    assert(!isClassType(delegate), "PresentationLinkCustomTransition must be value types (either a struct or an enum); it was a class")
                    context.coordinator.sourceView = uiView
                    adapter.viewController.modalPresentationStyle = .custom
                    adapter.viewController.presentationController?.overrideTraitCollection = traits
                }

                // Swizzle to hook up for programatic dismissal
                adapter.viewController.presentationDelegate = context.coordinator
                if let presentedViewController = presentingViewController.presentedViewController {
                    let shouldDismiss = presentedViewController.presentationController.map {
                        $0.delegate?.presentationControllerShouldDismiss?($0) ?? true
                    } ?? true
                    if shouldDismiss {
                        presentedViewController.dismiss(animated: isAnimated) {
                            presentingViewController.present(adapter.viewController, animated: isAnimated)
                        }
                    } else {
                        withCATransaction {
                            isPresented.wrappedValue = false
                        }
                    }
                } else {
                    presentingViewController.present(adapter.viewController, animated: isAnimated)
                }
            }
        } else if let adapter = context.coordinator.adapter,
            !isPresented.wrappedValue,
            !context.coordinator.isBeingReused
        {
            let isAnimated = context.transaction.isAnimated || PresentationCoordinator.transaction.isAnimated
            let viewController = adapter.viewController!
            if let presented = adapter.viewController.presentedViewController {
                presented.dismiss(animated: isAnimated) {
                    viewController.dismiss(animated: isAnimated) {
                        PresentationCoordinator.transaction = nil
                    }
                }
            } else {
                viewController.dismiss(animated: isAnimated) {
                    PresentationCoordinator.transaction = nil
                }
            }
            if adapter.transition.options.isDestinationReusable {
                context.coordinator.isBeingReused = true
            } else {
                context.coordinator.adapter = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }

    final class Coordinator: NSObject,
        UIViewControllerTransitioningDelegate,
        UIAdaptivePresentationControllerDelegate,
        UISheetPresentationControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        UIViewControllerPresentationDelegate
    {
        var isPresented: Binding<Bool>
        var adapter: PresentationLinkDestinationViewControllerAdapter<Destination>?
        var isBeingReused = false
        unowned var sourceView: UIView!

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        // MARK: - UIViewControllerPresentationDelegate

        func viewControllerDidDismiss() {
            withCATransaction {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.isPresented.wrappedValue = false
                }
            }
        }

        // MARK: - UIAdaptivePresentationControllerDelegate

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            if let toView = presentationController.presentingViewController.view as? AnyHostingView {
                // This fixes SwiftUI's gesture handling that can get messed up when applying
                // transforms and/or frame changes during an interactive presentation. This resets
                // SwiftUI's geometry in a clean way, fixing hit testing.
                let frame = toView.frame
                toView.frame = .zero
                toView.frame = frame
            }
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            switch adapter?.transition {
            case .sheet(let options):
                return options.isInteractive

            case .popover(let options):
                return options.isInteractive

            case .slide(let options):
                return options.isInteractive

            default:
                return true
            }
        }

        func presentationControllerDidAttemptToDismiss(
            _ presentationController: UIPresentationController
        ) {
            if let fromView = presentationController.presentedViewController.view as? AnyHostingView {
                // This fixes SwiftUI's gesture handling that can get messed up when applying
                // transforms and/or frame changes during an interactive presentation. This resets
                // SwiftUI's geometry in a clean way, fixing hit testing.
                let frame = fromView.frame
                fromView.frame = .zero
                fromView.frame = frame
            }
        }

        func adaptivePresentationStyle(
            for controller: UIPresentationController
        ) -> UIModalPresentationStyle {
            adaptivePresentationStyle(for: controller, traitCollection: controller.traitCollection)
        }

        func adaptivePresentationStyle(
            for controller: UIPresentationController,
            traitCollection: UITraitCollection
        ) -> UIModalPresentationStyle {
            switch adapter?.transition {
            case .popover(let options):
                return options.adaptiveTransition != nil && traitCollection.horizontalSizeClass == .compact ? .pageSheet : .none

            case .custom(_, let transition):
                return transition.adaptivePresentationStyle(for: controller, traitCollection: traitCollection)

            default:
                return .none
            }
        }

        func presentationController(
            _ presentationController: UIPresentationController,
            prepare adaptivePresentationController: UIPresentationController
        ) {
            switch adapter?.transition {
            case .popover(let options):
                if #available(iOS 15.0, *) {
                    if let options = options.adaptiveTransition,
                        let presentationController = adaptivePresentationController as? SheetPresentationController
                    {
                        PresentationLinkTransition.SheetTransitionOptions.update(
                            presentationController: presentationController,
                            animated: false,
                            from: .init(),
                            to: options
                        )
                    }
                }

            case .custom(_, let transition):
                transition.presentationController(presentationController, prepare: adaptivePresentationController)

            default:
                break
            }
        }

        // MARK: - UIViewControllerTransitioningDelegate

        func animationController(
            forPresented presented: UIViewController,
            presenting: UIViewController,
            source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            switch adapter?.transition {
            case .sheet(let options):
                #if targetEnvironment(macCatalyst)
                let transition = SlideTransition(
                    isPresenting: true,
                    options: .init(
                        edge: .bottom,
                        prefersScaleEffect: false,
                        preferredCornerRadius: options.preferredCornerRadius,
                        isInteractive: options.isInteractive,
                        options: options.options
                    )
                )
                transition.wantsInteractiveStart = false
                return transition
                #else
                return nil
                #endif

            case .slide(let options):
                let transition = SlideTransition(
                    isPresenting: true,
                    options: options
                )
                transition.wantsInteractiveStart = false
                return transition

            case .custom(_, let transition):
                return transition.animationController(
                    forPresented: presented,
                    presenting: presenting
                )

            default:
                return nil
            }
        }

        func animationController(
            forDismissed dismissed: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            switch adapter?.transition {
            case .sheet(let options):
                #if targetEnvironment(macCatalyst)
                guard let presentationController = dismissed.presentationController as? MacSheetPresentationController else {
                    return nil
                }
                let transition = SlideTransition(
                    isPresenting: false,
                    options: .init(
                        edge: .bottom,
                        prefersScaleEffect: false,
                        preferredCornerRadius: options.preferredCornerRadius,
                        isInteractive: options.isInteractive,
                        options: options.options
                    )
                )
                presentationController.begin(transition: transition, isInteractive: options.isInteractive)
                return transition
                #else
                return nil
                #endif

            case .slide(let options):
                guard let presentationController = dismissed.presentationController as? SlidePresentationController else {
                    return nil
                }
                let transition = SlideTransition(
                    isPresenting: false,
                    options: options
                )
                presentationController.begin(transition: transition, isInteractive: options.isInteractive)
                return transition

            case .custom(_, let transition):
                return transition.animationController(forDismissed: dismissed)

            default:
                return nil
            }
        }

        func interactionControllerForPresentation(
            using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
            switch adapter?.transition {
            case .custom(_, let transition):
                return transition.interactionControllerForPresentation(using: animator)

            default:
                return nil
            }
        }

        func interactionControllerForDismissal(
            using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
            switch adapter?.transition {
            case .sheet:
                #if targetEnvironment(macCatalyst)
                return animator as? SlideTransition
                #else
                return nil
                #endif

            case .slide:
                return animator as? SlideTransition

            case .custom(_, let transition):
                return transition.interactionControllerForDismissal(using: animator)

            default:
                return nil
            }
        }

        func presentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            switch adapter?.transition {
            case .sheet(let configuration):
                #if targetEnvironment(macCatalyst)
                let presentationController = MacSheetPresentationController(
                    presentedViewController: presented,
                    presenting: presenting
                )
                presentationController.detents = configuration.detents
                presentationController.selected = configuration.selected
                presentationController.largestUndimmedDetentIdentifier = configuration.largestUndimmedDetentIdentifier
                return presentationController
                #else
                if #available(iOS 15.0, *) {
                    let presentationController = PhoneSheetPresentationController(
                        presentedViewController: presented,
                        presenting: presenting
                    )
                    presentationController.detents = configuration.detents.map { $0.resolve(in: presentationController).toUIKit() }
                    presentationController.selectedDetentIdentifier = (configuration.selected?.wrappedValue ?? configuration.detents.first?.identifier)?.toUIKit()
                    presentationController.largestUndimmedDetentIdentifier = configuration.largestUndimmedDetentIdentifier?.toUIKit()
                    presentationController.prefersGrabberVisible = configuration.prefersGrabberVisible
                    presentationController.preferredCornerRadius = configuration.preferredCornerRadius
                    presentationController.prefersScrollingExpandsWhenScrolledToEdge = configuration.prefersScrollingExpandsWhenScrolledToEdge
                    presentationController.prefersEdgeAttachedInCompactHeight = configuration.prefersEdgeAttachedInCompactHeight
                    presentationController.widthFollowsPreferredContentSizeWhenEdgeAttached = configuration.widthFollowsPreferredContentSizeWhenEdgeAttached
                    presentationController.delegate = self
                    return presentationController
                } else {
                    // Fallback on earlier versions
                    let presentationController = PresentationController(
                        presentedViewController: presented,
                        presenting: presenting
                    )
                    presentationController.delegate = self
                    return presentationController
                }
                #endif

            case .popover(let options):
                let presentationController = PopoverPresentationController(
                    presentedViewController: presented,
                    presenting: presenting
                )
                presentationController.canOverlapSourceViewRect = options.canOverlapSourceViewRect
                presentationController.permittedArrowDirections = options.permittedArrowDirections(
                    layoutDirection: presentationController.traitCollection.layoutDirection
                )
                presentationController.delegate = self
                return presentationController

            case .slide(let options):
                let presentationController = SlidePresentationController(
                    presentedViewController: presented,
                    presenting: presenting
                )
                presentationController.edge = options.edge
                presentationController.delegate = self
                return presentationController

            case .fullscreen:
                let presentationController = FullscreenPresentationController(
                    presentedViewController: presented,
                    presenting: presenting
                )
                presentationController.delegate = self
                return presentationController

            case .custom(_, let adapter):
                let presentationController = adapter.presentationController(
                    sourceView: sourceView,
                    presented: presented,
                    presenting: presenting
                )
                presentationController.delegate = self
                return presentationController

            default:
                return nil
            }
        }

        func presentationController(
            _ presentationController: UIPresentationController,
            willPresentWithAdaptiveStyle style: UIModalPresentationStyle,
            transitionCoordinator: UIViewControllerTransitionCoordinator?
        ) {
            #if !targetEnvironment(macCatalyst)
            if #available(iOS 15.0, *) {
                if let sheetPresentationController = presentationController as? SheetPresentationController {
                    transitionCoordinator?.animate(alongsideTransition: { _ in
                        self.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheetPresentationController)
                    })
                }
            }
            #endif
        }

        // MARK: - UISheetPresentationControllerDelegate

        @available(iOS 15.0, *)
        @available(macOS, unavailable)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
            _ sheetPresentationController: UISheetPresentationController
        ) {
            if case .sheet(let configuration) = adapter?.transition {
                func applySelection() {
                    configuration.selected?.wrappedValue = sheetPresentationController.selectedDetentIdentifier.map {
                        .init($0.rawValue)
                    }
                }

                if sheetPresentationController.selectedDetentIdentifier?.rawValue == PresentationLinkTransition.SheetTransitionOptions.Detent.ideal.identifier.rawValue {
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        sheetPresentationController.invalidateDetents()
                        applySelection()
                    } else {
                        sheetPresentationController.detents = configuration.detents.map { $0.resolve(in: sheetPresentationController).toUIKit() }
                        withCATransaction {
                            applySelection()
                        }
                    }
                } else {
                    applySelection()
                }
            }
        }

        // MARK: - UIPopoverPresentationControllerDelegate

        func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
            popoverPresentationController.presentedViewController.view.layoutIfNeeded()
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        coordinator.adapter?.viewController.dismiss(animated: false)
        coordinator.adapter = nil
    }
}

private class PresentationController: UIPresentationController {
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.addSubview(presentedViewController.view)
        presentedViewController.view.frame = frameOfPresentedViewInContainerView
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.presentedViewController.view.frame = self.frameOfPresentedViewInContainerView
        }
    }
}

#if targetEnvironment(macCatalyst)
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private typealias SheetPresentationController = MacSheetPresentationController

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class MacSheetPresentationController: SlidePresentationController {

    private var depth = 0
    private var overlayView: UIView?
    private var dimmingView = UIView()

    private(set) var detent: PresentationLinkTransition.SheetTransitionOptions.Detent?
    private var largeHeightAnchor: NSLayoutConstraint?
    private var constantHeightAnchor: NSLayoutConstraint?

    var detents: [PresentationLinkTransition.SheetTransitionOptions.Detent] = []
    var selected: Binding<PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?>?
    var largestUndimmedDetentIdentifier: PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?

    func updateDetent() {
        if let identifier = selected?.wrappedValue {
            detent = detents.first(where: { $0.identifier == identifier }) ?? detents.first
        } else {
            detent = detents.first
        }
        dimmingView.isHidden = largestUndimmedDetentIdentifier == detent?.identifier
        updateHeightAnchorForDetent()
    }

    private func updateHeightAnchorForDetent() {
        if #available(iOS 15.0, *), let detent = detent {

            switch detent.identifier {
            case .large, .medium:
                largeHeightAnchor?.isActive = true
                constantHeightAnchor?.isActive = false

            case .ideal:
                largeHeightAnchor?.isActive = false
                constantHeightAnchor?.isActive = false

            default:
                var constant: CGFloat?
                if let height = detent.height {
                    constant = height
                } else if let resolution = detent.resolution {
                    let maximumDetentValue = containerView.map {
                        ($0.frame.height - $0.safeAreaInsets.top - $0.safeAreaInsets.bottom) * 0.85
                    } ?? 0
                    constant = resolution(
                        .init(
                            containerTraitCollection: traitCollection,
                            maximumDetentValue: maximumDetentValue
                        )
                    )
                }
                if let constant = constant {
                    largeHeightAnchor?.isActive = false
                    constantHeightAnchor?.constant = constant
                    constantHeightAnchor?.isActive = true
                } else {
                    largeHeightAnchor?.isActive = true
                    constantHeightAnchor?.isActive = false
                }
            }

        } else {
            largeHeightAnchor?.isActive = true
            constantHeightAnchor?.isActive = false
        }

        containerView?.layoutIfNeeded()
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        selected?.wrappedValue = detent?.identifier

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.dimmingView.alpha = 1
                self.overlayView?.alpha = 1
                self.transformPresentedViewIfNeeded(isPresented: true)
            }, completion: { ctx in
                self.dimmingView.alpha = ctx.isCancelled ? 0 : 1
                self.overlayView?.alpha = ctx.isCancelled ? 0 : 1
                if self.depth > 0, ctx.isCancelled {
                    self.presentingViewController.view.transform = .identity
                }
            })
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if !completed {
            selected?.wrappedValue = nil
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.dimmingView.alpha = 0
                self.overlayView?.alpha = 0
                self.transformPresentedViewIfNeeded(isPresented: false)
            }, completion: { ctx in
                self.dimmingView.alpha = ctx.isCancelled ? 1 : 0
                self.overlayView?.alpha = ctx.isCancelled ? 1 : 0
                if !ctx.isCancelled {
                    self.overlayView?.removeFromSuperview()
                    self.overlayView = nil
                }
            })
        }
    }

    override func addPresentedView(to containerView: UIView) {
        if let presentingPresentingViewController = presentingViewController.presentingViewController,
            presentingViewController.presentationController is MacSheetPresentationController
        {
            depth = 1
            if presentingPresentingViewController.presentingViewController != nil,
               presentingPresentingViewController.presentationController is MacSheetPresentationController
            {
                depth = 2
            }

            dimmingView.backgroundColor = nil

            let overlayView = UIView()
            overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            overlayView.alpha = 0
            overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPresentedViewController)))
            self.overlayView = overlayView

        } else {
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }

        dimmingView.alpha = 0
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPresentedViewController)))

        containerView.addSubview(presentedViewController.view)
        containerView.insertSubview(dimmingView, belowSubview: presentedViewController.view)

        if let overlayView = overlayView {
            presentingViewController.view.addSubview(overlayView)
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: presentingViewController.view.topAnchor),
                overlayView.bottomAnchor.constraint(equalTo: presentingViewController.view.bottomAnchor),
                overlayView.leftAnchor.constraint(equalTo: presentingViewController.view.leftAnchor),
                overlayView.rightAnchor.constraint(equalTo: presentingViewController.view.rightAnchor),
            ])
        }

        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dimmingView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            dimmingView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
        ])

        presentedViewController.view.layer.masksToBounds = true
        presentedViewController.view.layer.cornerCurve = .continuous

        presentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        largeHeightAnchor = presentedViewController.view.heightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.heightAnchor, multiplier: 0.85)
        let heightAnchor = presentedViewController.view.heightAnchor.constraint(equalToConstant: 100)
        heightAnchor.priority = .defaultLow
        constantHeightAnchor = heightAnchor
        NSLayoutConstraint.activate([
            presentedViewController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.85),
            presentedViewController.view.heightAnchor.constraint(lessThanOrEqualTo: containerView.safeAreaLayoutGuide.heightAnchor, multiplier: 0.85),
            presentedViewController.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            presentedViewController.view.centerYAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerYAnchor),
        ])
        updateDetent()
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if !presentedViewController.isBeingPresented,
            !presentedViewController.isBeingDismissed,
            presentedViewController.presentedViewController == nil
        {
            transformPresentedViewIfNeeded(isPresented: true)
        }
    }

    private func transformPresentedViewIfNeeded(isPresented: Bool) {
        if depth > 0 {
            func makeTransform(scale: CGFloat, frame: CGRect) -> CGAffineTransform {
                CGAffineTransform(scaleX: scale, y: scale)
                    .translatedBy(x: 0, y: (frame.height * -(1 - scale) / 2) - 20)
            }

            var scale: CGFloat = 0.92
            if isPresented {
                let frame = presentingViewController.view.frame.applying(presentingViewController.view.transform.inverted())
                presentingViewController.view.transform = makeTransform(
                    scale: scale,
                    frame: frame
                )
            } else {
                presentingViewController.view.transform = .identity
            }

            if depth > 1, let presentingPresentingViewController = presentingViewController.presentingViewController {
                if isPresented {
                    scale *= scale
                }
                let frame = presentingPresentingViewController.view.frame.applying(presentingPresentingViewController.view.transform.inverted())
                presentingPresentingViewController.view.transform = makeTransform(
                    scale: scale,
                    frame: frame
                )
            }
        }
    }

    @objc
    private func dismissPresentedViewController() {
        presentedViewController.dismiss(animated: true)
    }
}
#else
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private typealias SheetPresentationController = UISheetPresentationController

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class PhoneSheetPresentationController: UISheetPresentationController {

}
#endif

private class PopoverPresentationController: UIPopoverPresentationController {

}

private class FullscreenPresentationController: PresentationController {
    override var presentationStyle: UIModalPresentationStyle { .fullScreen }
}

@available(iOS 15.0, *)
extension PresentationLinkTransition.SheetTransitionOptions {
    fileprivate static func update(
        presentationController: SheetPresentationController,
        animated isAnimated: Bool,
        from oldValue: Self,
        to newValue: Self
    ) {
        lazy var detents = newValue.detents.map { $0.resolve(in: presentationController) }
        #if targetEnvironment(macCatalyst)
        let cornerRadius = newValue.preferredCornerRadius ?? SlideTransition.displayCornerRadius
        let hasChanges: Bool = {
            if presentationController.presentedViewController.view.layer.cornerRadius != cornerRadius {
                return true
            } else if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = newValue.selected,
                presentationController.detent?.identifier != selected.wrappedValue
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            return false
        }()
        #else
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
            return false
        }()
        #endif
        if hasChanges {
            func applyConfiguration() {
                #if targetEnvironment(macCatalyst)
                presentationController.presentedViewController.view.layer.cornerRadius = cornerRadius
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier
                presentationController.selected = newValue.selected
                presentationController.detents = detents
                presentationController.updateDetent()
                #else
                presentationController.detents = detents.map { $0.toUIKit() }
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier?.toUIKit()
                if let selected = newValue.selected {
                    presentationController.selectedDetentIdentifier = selected.wrappedValue?.toUIKit()
                }
                presentationController.preferredCornerRadius = newValue.preferredCornerRadius
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

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class SlideTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    let isPresenting: Bool
    let options: PresentationLinkTransition.SlideTransitionOptions

    var animator: UIViewPropertyAnimator?

    static let displayCornerRadius: CGFloat = {
        #if targetEnvironment(macCatalyst)
        return 12
        #else
        let key = String("suidaRrenroCyalpsid_".reversed())
        let value = UIScreen.main.value(forKey: key) as? CGFloat ?? 0
        return max(value, 12)
        #endif
    }()

    init(
        isPresenting: Bool,
        options: PresentationLinkTransition.SlideTransitionOptions
    ) {
        self.isPresenting = isPresenting
        self.options = options
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        transitionContext?.isAnimated == true ? 0.35 : 0
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        let animator = makeAnimatorIfNeeded(using: transitionContext)
        animator.startAnimation()

        if !transitionContext.isAnimated {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    func animationEnded(_ transitionCompleted: Bool) {
        wantsInteractiveStart = false
        animator = nil
    }

    func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        let animator = makeAnimatorIfNeeded(using: transitionContext)
        return animator
    }

    func makeAnimatorIfNeeded(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {
        if let animator = animator {
            return animator
        }

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
        let isTranslucentBackground = options.options.preferredPresentationBackgroundUIColor.map { color in
            var alpha: CGFloat = 0
            if color.getWhite(nil, alpha: &alpha) {
                return alpha < 1
            }
            return false
        } ?? false
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
            presented.view.transform = presentationTransform(
                presented: presented,
                frame: frame
            )
        } else {
            presented.view.layer.cornerRadius = cornerRadius
            if isScaleEnabled {
                presenting.view.transform = dzTransform
                presenting.view.layer.cornerRadius = cornerRadius
            }
        }

        presented.additionalSafeAreaInsets.top = -1

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
        self.animator = animator
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

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class SlidePresentationController: UIPresentationController, UIGestureRecognizerDelegate {

    private weak var transition: SlideTransition?
    var edge: Edge = .bottom

    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))

    private var isPanGestureActive = false
    private var translationOffset: CGPoint = .zero

    override var presentationStyle: UIModalPresentationStyle { .fullScreen }

    func begin(transition: SlideTransition, isInteractive: Bool) {
        self.transition = transition
        transition.wantsInteractiveStart = isInteractive && isPanGestureActive
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let containerView = containerView else {
            return
        }
        addPresentedView(to: containerView)
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            panGesture.delegate = self
            panGesture.allowedScrollTypesMask = .all
            containerView?.addGestureRecognizer(panGesture)
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        delegate?.presentationControllerWillDismiss?(self)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            delegate?.presentationControllerDidDismiss?(self)
        } else {
            delegate?.presentationControllerDidAttemptToDismiss?(self)
        }
    }

    func addPresentedView(to containerView: UIView) {
        containerView.addSubview(presentedViewController.view)
        presentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            presentedViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            presentedViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            presentedViewController.view.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            presentedViewController.view.rightAnchor.constraint(equalTo: containerView.rightAnchor),
        ])
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        delegate?.presentationControllerShouldDismiss?(self) ?? false
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let scrollView = gestureRecognizer.view as? UIScrollView
        guard let containerView = scrollView ?? containerView else {
            return
        }

        let gestureTranslation = gestureRecognizer.translation(in: containerView)
        let offset = CGSize(
            width: gestureTranslation.x - translationOffset.x,
            height: gestureTranslation.y - translationOffset.y
        )
        let translation: CGFloat
        let percentage: CGFloat
        switch edge {
        case .top:
            if let scrollView {
                translation = max(0, scrollView.contentSize.height + scrollView.adjustedContentInset.top - scrollView.bounds.height) + offset.height
            } else {
                translation = offset.height
            }
            percentage = translation / containerView.bounds.height
        case .bottom:
            translation = offset.height
            percentage = translation / containerView.bounds.height
        case .leading:
            if let scrollView {
                translation = max(0, scrollView.contentSize.width + scrollView.adjustedContentInset.left - scrollView.bounds.width) + offset.width
            } else {
                translation = offset.width
            }
            percentage = translation / containerView.bounds.width
        case .trailing:
            translation = offset.width
            percentage = translation / containerView.bounds.width
        }

        guard isPanGestureActive else {
            let shouldBeginDismissal: Bool
            switch edge {
            case .top, .leading:
                shouldBeginDismissal = translation < 1
            case .bottom, .trailing:
                shouldBeginDismissal = translation > 1
            }
            if shouldBeginDismissal,
                !presentedViewController.isBeingDismissed,
                scrollView.map({ isAtTop(scrollView: $0) }) ?? true
            {
                #if targetEnvironment(macCatalyst)
                let canStart = true
                #else
                var views = gestureRecognizer.view.map { [$0] } ?? []
                var firstResponder: UIView?
                var index = 0
                repeat {
                    let view = views[index]
                    if view.isFirstResponder {
                        firstResponder = view
                    } else {
                        views.append(contentsOf: view.subviews)
                        index += 1
                    }
                } while index < views.count && firstResponder == nil
                let canStart = firstResponder?.resignFirstResponder() ?? true
                #endif
                if canStart, gestureRecognizerShouldBegin(gestureRecognizer) {
                    isPanGestureActive = true
                    presentedViewController.dismiss(animated: true)
                }
            }
            return
        }

        guard percentage > 0 && (edge == .bottom || edge == .trailing) ||
            percentage < 0 && (edge == .top || edge == .leading)
        else {
            transition?.cancel()
            isPanGestureActive = false
            return
        }

        switch gestureRecognizer.state {
        case .began, .changed:
            if let scrollView = scrollView {
                switch edge {
                case .top:
                    scrollView.contentOffset.y = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height + scrollView.adjustedContentInset.top - scrollView.frame.height)

                case .bottom:
                    scrollView.contentOffset.y = -scrollView.adjustedContentInset.top

                case .leading:
                    scrollView.contentOffset.x = max(-scrollView.adjustedContentInset.left, scrollView.contentSize.width + scrollView.adjustedContentInset.left - scrollView.frame.width)

                case .trailing:
                    scrollView.contentOffset.x = -scrollView.adjustedContentInset.right
                }
            }

            transition?.update(abs(percentage))

        case .ended, .cancelled:
            // Dismiss if:
            // - Drag over 50% and not moving up
            // - Large enough down vector
            let velocity: CGFloat
            switch edge {
            case .top:
                velocity = -gestureRecognizer.velocity(in: containerView).y
            case .bottom:
                velocity = gestureRecognizer.velocity(in: containerView).y
            case .leading:
                velocity = -gestureRecognizer.velocity(in: containerView).x
            case .trailing:
                velocity = gestureRecognizer.velocity(in: containerView).x
            }
            let shouldDismiss = (abs(percentage) > 0.5 && velocity > 0) || velocity >= 1000
            if shouldDismiss {
                transition?.finish()
            } else {
                if abs(velocity) < 1000 {
                    transition?.completionSpeed = 0.5
                }
                transition?.cancel()
            }
            isPanGestureActive = false
            translationOffset = .zero

        default:
            break
        }
    }

    func isAtTop(scrollView: UIScrollView) -> Bool {
        let frame = scrollView.frame
        let size = scrollView.contentSize
        let canScrollVertically = size.height > frame.size.height
        let canScrollHorizontally = size.width > frame.size.width

        switch edge {
        case .top, .bottom:
            if canScrollHorizontally && !canScrollVertically {
                return false
            }

            let dy = scrollView.contentOffset.y + scrollView.contentInset.top
            if edge == .bottom {
                return dy <= 0
            } else {
                return dy >= size.height - frame.height
            }

        case .leading, .trailing:
            if canScrollVertically && !canScrollHorizontally {
                return false
            }

            let dx = scrollView.contentOffset.x + scrollView.contentInset.left
            if edge == .trailing {
                return dx <= 0
            } else {
                return dx >= size.width - frame.width
            }
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(onPanGesture(_:)))
            switch edge {
            case .bottom, .trailing:
                translationOffset = CGPoint(
                    x: scrollView.contentOffset.x + scrollView.adjustedContentInset.left,
                    y: scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                )
            case .top, .leading:
                translationOffset = CGPoint(
                    x: scrollView.contentOffset.x + scrollView.adjustedContentInset.left + scrollView.adjustedContentInset.right,
                    y: scrollView.contentOffset.y - scrollView.adjustedContentInset.bottom + scrollView.adjustedContentInset.top
                )
            }
            return false
        }
        return false
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class PresentationLinkDestinationViewControllerAdapter<
    Destination: View
> {

    typealias DestinationController = HostingController<ModifiedContent<Destination, PresentationBridgeAdapter>>

    var viewController: UIViewController!
    var context: Any!

    var transition: PresentationLinkTransition.Value
    var conformance: ProtocolConformance<UIViewControllerRepresentableProtocolDescriptor>? = nil

    init(
        destination: Destination,
        isPresented: Binding<Bool>,
        sourceView: UIView,
        transition: PresentationLinkTransition.Value,
        context: PresentationLinkAdapterBody<Destination>.Context
    ) {
        self.transition = transition
        if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Destination.self) {
            self.conformance = conformance
            update(
                destination: destination,
                isPresented: isPresented,
                sourceView: sourceView,
                context: context
            )
        } else {
            let viewController = DestinationController(
                content: destination.modifier(
                    PresentationBridgeAdapter(
                        isPresented: isPresented
                    )
                )
            )
            transition.update(viewController)
            self.viewController = viewController
        }
    }

    deinit {
        switch transition {
        case .sheet(let configuration):
            withCATransaction {
                configuration.selected?.wrappedValue = nil
            }
        default:
            break
        }
        if let conformance = conformance {
            var visitor = Visitor(
                destination: nil,
                isPresented: .constant(false),
                sourceView: nil,
                context: nil,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
        }
    }

    func update(
        destination: Destination,
        isPresented: Binding<Bool>,
        sourceView: UIView,
        context: PresentationLinkAdapterBody<Destination>.Context
    ) {
        if let conformance = conformance {
            var visitor = Visitor(
                destination: destination,
                isPresented: isPresented,
                sourceView: sourceView,
                context: context,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
            if case .custom(let options, _) = transition {
                viewController.modalPresentationCapturesStatusBarAppearance = options.modalPresentationCapturesStatusBarAppearance
            }
        } else {
            let viewController = viewController as! DestinationController
            viewController.content = destination.modifier(
                PresentationBridgeAdapter(
                    isPresented: isPresented
                )
            )
            transition.update(viewController)
        }
    }

    private struct Context<Coordinator> {
        var coordinator: Coordinator
        var transaction: Transaction
        var environment: EnvironmentValues
        var preferenceBridge: AnyObject?
    }

    private struct Visitor: ViewVisitor {
        var destination: Destination?
        var isPresented: Binding<Bool>
        var sourceView: UIView?
        var context: PresentationLinkAdapterBody<Destination>.Context?
        var adapter: PresentationLinkDestinationViewControllerAdapter<Destination>

        mutating func visit<Content>(type: Content.Type) where Content: UIViewControllerRepresentable {
            guard
                let destination = destination.map({ unsafeBitCast($0, to: Content.self) }),
                let context = context
            else {
                if let context = adapter.context, let viewController = adapter.viewController as? Content.UIViewControllerType {
                    func project<T>(_ value: T) {
                        let coordinator = unsafeBitCast(value, to: Content.Context.self).coordinator
                        Content.dismantleUIViewController(viewController, coordinator: coordinator)
                    }
                    _openExistential(context, do: project)
                }
                return
            }
            if adapter.context == nil {
                let preferenceBridge = unsafeBitCast(
                    context,
                    to: Context<PresentationLinkAdapterBody<Destination>.Coordinator>.self
                ).preferenceBridge
                let context = Context(
                    coordinator: destination.makeCoordinator(),
                    transaction: context.transaction,
                    environment: context.environment,
                    preferenceBridge: preferenceBridge
                )
                adapter.context = unsafeBitCast(context, to: Content.Context.self)
            }
            func project<T>(_ value: T) -> Content.Context {
                var ctx = unsafeBitCast(value, to: Context<Content.Coordinator>.self)
                let isPresented = self.isPresented
                ctx.environment.presentationCoordinator = PresentationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    sourceView: sourceView,
                    dismissBlock: {
                        isPresented.wrappedValue = false
                    }
                )
                return unsafeBitCast(ctx, to: Content.Context.self)
            }
            let ctx = _openExistential(adapter.context!, do: project)
            if adapter.viewController == nil {
                adapter.viewController = destination.makeUIViewController(context: ctx)
            } else {
                let viewController = adapter.viewController as! Content.UIViewControllerType
                destination.updateUIViewController(viewController, context: ctx)
            }
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PresentationLinkTransition.Value {

    func update<Content: View>(_ viewController: HostingController<Content>) {

        viewController.view.backgroundColor = options.preferredPresentationBackgroundUIColor ?? .systemBackground

        switch self {
        case .custom(let options, _):
            viewController.modalPresentationCapturesStatusBarAppearance = options.modalPresentationCapturesStatusBarAppearance

        case .sheet(let options):
            if #available(iOS 15.0, *) {
                viewController.tracksContentSize = options.widthFollowsPreferredContentSizeWhenEdgeAttached || options.detents.contains(where: { $0.identifier == .ideal })
            } else {
                viewController.tracksContentSize = options.widthFollowsPreferredContentSizeWhenEdgeAttached
            }
            viewController.modalPresentationCapturesStatusBarAppearance = options.options.modalPresentationCapturesStatusBarAppearance

        case .currentContext(let options):
            viewController.modalPresentationCapturesStatusBarAppearance = options.modalPresentationCapturesStatusBarAppearance

        case .fullscreen(let options):
            viewController.modalPresentationCapturesStatusBarAppearance = options.modalPresentationCapturesStatusBarAppearance

        case .popover:
            viewController.tracksContentSize = true

        case .slide(let options):
            viewController.modalPresentationCapturesStatusBarAppearance = options.options.modalPresentationCapturesStatusBarAppearance

        default:
            break
        }
    }
}

#endif
