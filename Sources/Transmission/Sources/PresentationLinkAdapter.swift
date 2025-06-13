//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore

/// A view manages the presentation of a destination view in a new `UIViewController`. The presentation is
/// sourced from this view.
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
/// See Also:
///  - ``PresentationLink``
///  - ``PresentationLinkTransition``
///  - ``PresentationSourceViewLink``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with a `UIPresentationController` and/or
/// `UIViewControllerInteractiveTransitioning` with the ``PresentationLinkTransition/custom(_:)``
///  transition.
///
@frozen
@available(iOS 14.0, *)
public struct PresentationLinkAdapter<
    Content: View,
    Destination: View
>: View {

    var transition: PresentationLinkTransition
    var isPresented: Binding<Bool>
    var content: Content
    var destination: Destination

    public init(
        transition: PresentationLinkTransition,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) where Content == EmptyView {
        self.init(transition: transition, isPresented: isPresented, destination: destination, content: { EmptyView() })
    }

    public init(
        transition: PresentationLinkTransition,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self.isPresented = isPresented
        self.content = content()
        self.destination = destination()
    }

    public var body: some View {
        PresentationLinkAdapterBody(
            transition: transition,
            isPresented: isPresented,
            destination: destination,
            sourceView: content
        )
    }
}

@available(iOS 14.0, *)
private struct PresentationLinkAdapterBody<
    Destination: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: PresentationLinkTransition
    var isPresented: Binding<Bool>
    var destination: Destination
    var sourceView: SourceView

    @WeakState var presentingViewController: UIViewController?

    typealias UIViewType = TransitionSourceView<SourceView>
    typealias DestinationViewController = PresentationHostingController<ModifiedContent<Destination, PresentationBridgeAdapter>>

    func makeUIView(context: Context) -> UIViewType {
        let uiView = TransitionSourceView(
            onDidMoveToWindow: { viewController in
                withCATransaction {
                    presentingViewController = viewController
                }
            },
            content: sourceView
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.hostingView?.content = sourceView

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

            var isAnimated = context.transaction.isAnimated
                || presentingViewController.transitionCoordinator?.isAnimated == true
            let animation = context.transaction.animation
                ?? (isAnimated ? .default : nil)
            context.coordinator.animation = animation
            var isTransitioningPresentationController = false

            if let adapter = context.coordinator.adapter,
               !context.coordinator.isBeingReused
            {

                switch (adapter.transition, transition.value) {
                case (.sheet(let oldValue), .sheet(let newValue)):
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
                    if let presentationController = adapter.viewController.presentationController as? PopoverPresentationController {
                        presentationController.permittedArrowDirections = newValue.permittedArrowDirections(
                            layoutDirection: traits.layoutDirection
                        )
                        if let backgroundColor = newValue.options.preferredPresentationBackgroundUIColor {
                            presentationController.backgroundColor = backgroundColor
                        }
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

                case (.zoom, .zoom):
                    break

                case (.representable, .representable(let options, let transition)):
                    if let presentationController = adapter.viewController.presentationController {
                        func project<T: PresentationLinkTransitionRepresentable>(
                            _ transition: T
                        ) {
                            let context = PresentationLinkTransitionRepresentableContext(
                                sourceView: uiView,
                                options: options,
                                environment: context.environment,
                                transaction: Transaction(animation: animation)
                            )
                            if let presentationController = presentationController as? T.UIPresentationControllerType {
                                transition.updateUIPresentationController(
                                    presentationController: presentationController,
                                    context: context
                                )
                            } else {
                                transition.updateAdaptivePresentationController(
                                    adaptivePresentationController: presentationController,
                                    context: context
                                )
                            }
                        }
                        _openExistential(transition, do: project)
                    }

                case (.default, .default),
                    (.currentContext, .currentContext),
                    (.fullscreen, .fullscreen):
                    break

                default:
                    if context.coordinator.adapter?.transition.options.preferredPresentationBackgroundUIColor != nil {
                        context.coordinator.adapter?.viewController.view.backgroundColor = .systemBackground
                    }
                    context.coordinator.isBeingReused = true
                    isTransitioningPresentationController = true
                    isAnimated = false

                    if #available(iOS 18.0, *), case .zoom = adapter.transition {
                        adapter.viewController.preferredTransition = nil
                    }
                }
            }

            if let adapter = context.coordinator.adapter,
               !context.coordinator.isBeingReused
            {
                adapter.transition = transition.value
                adapter.viewController.presentationController?.overrideTraitCollection = traits

                adapter.update(
                    destination: destination,
                    sourceView: uiView,
                    context: context,
                    isPresented: isPresented
                )
            } else {
                let adapter: PresentationLinkDestinationViewControllerAdapter<Destination, SourceView>
                if let oldValue = context.coordinator.adapter {
                    adapter = oldValue
                    adapter.transition = transition.value
                    adapter.update(
                        destination: destination,
                        sourceView: uiView,
                        context: context,
                        isPresented: isPresented
                    )
                    context.coordinator.isBeingReused = false
                } else {
                    adapter = PresentationLinkDestinationViewControllerAdapter(
                        destination: destination,
                        sourceView: uiView,
                        transition: transition.value,
                        context: context,
                        isPresented: isPresented,
                        onDismiss: { [weak coordinator = context.coordinator] in
                            coordinator?.onDismiss($0, transaction: $1)
                        }
                    )
                    context.coordinator.adapter = adapter
                }

                if case .default = adapter.transition { } else {
                    adapter.viewController.transitioningDelegate = context.coordinator
                }

                switch adapter.transition {
                case .`default`:
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
                                if let backgroundColor = options.options.preferredPresentationBackgroundUIColor {
                                    popoverPresentationController.backgroundColor = backgroundColor
                                }
                            }
                        }
                    }

                case .currentContext:
                    // transitioningDelegate + .custom breaks .overCurrentContext
                    adapter.viewController.modalPresentationStyle = .overCurrentContext
                    adapter.viewController.presentationController?.overrideTraitCollection = traits

                case .fullscreen:
                    adapter.viewController.modalPresentationStyle = .overFullScreen
                    adapter.viewController.presentationController?.overrideTraitCollection = traits

                case .sheet, .popover:
                    context.coordinator.sourceView = uiView
                    context.coordinator.overrideTraitCollection = traits
                    adapter.viewController.modalPresentationStyle = .custom

                case .zoom(let options):
                    if #available(iOS 18.0, *) {
                        let zoomOptions = UIViewController.Transition.ZoomOptions()
                        zoomOptions.dimmingColor = options.dimmingColor?.toUIColor()
                        zoomOptions.dimmingVisualEffect = options.dimmingVisualEffect.map { UIBlurEffect(style: $0) }
                        adapter.viewController.preferredTransition = .zoom(options: zoomOptions) { [weak uiView] context in
                            return uiView
                        }
                    }
                    context.coordinator.sourceView = uiView
                    context.coordinator.overrideTraitCollection = traits
                    adapter.viewController.modalPresentationStyle = .custom

                case .representable(_, let transition):
                    assert(!swift_getIsClassType(transition), "PresentationLinkTransitionRepresentable must be value types (either a struct or an enum); it was a class")
                    context.coordinator.sourceView = uiView
                    context.coordinator.overrideTraitCollection = traits
                    adapter.viewController.modalPresentationStyle = .custom
                }

                if isTransitioningPresentationController {
                    adapter.viewController.presentationDelegate = nil
                } else {
                    // Swizzle to hook up for programatic dismissal
                    adapter.viewController.presentationDelegate = context.coordinator
                }

                var presentingViewController = presentingViewController
                if !transition.value.options.shouldAutomaticallyDismissPresentedView {
                    while let presenting = presentingViewController.presentedViewController {
                        presentingViewController = presenting
                    }
                }
                let present: () -> Void = {
                    guard let viewController = adapter.viewController else { return }
                    presentingViewController.present(
                        viewController,
                        animated: isAnimated
                    ) {
                        context.coordinator.animation = nil
                        context.coordinator.didPresentAnimated = isAnimated
                        if !isPresented.wrappedValue {
                            // Handle `isPresented` changing mid presentation
                            viewController.dismiss(animated: isAnimated)
                        } else {
                            viewController
                                .setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
                            if isTransitioningPresentationController {
                                viewController.presentationDelegate = context.coordinator
                            }
                        }
                    }
                }
                if let presentedViewController = presentingViewController.presentedViewController {
                    let shouldDismiss = {
                        if presentedViewController.isBeingDismissed {
                            return false
                        }
                        if isTransitioningPresentationController {
                            return true
                        }
                        return presentedViewController.presentationController.map {
                            $0.delegate?.presentationControllerShouldDismiss?($0) ?? true
                        } ?? true
                    }()
                    if shouldDismiss {
                        presentedViewController.dismiss(
                            animated: isAnimated,
                            completion: present
                        )
                    } else {
                        present()
                    }
                } else {
                    present()
                }
            }
        } else if let adapter = context.coordinator.adapter,
                  !isPresented.wrappedValue,
                  !context.coordinator.isBeingReused
        {
            let isAnimated = context.transaction.isAnimated
            let viewController = adapter.viewController!
            if viewController.presentedViewController != nil {
                (viewController.presentingViewController ?? viewController).dismiss(animated: isAnimated)
            } else if viewController.presentingViewController != nil {
                viewController.dismiss(animated: isAnimated)
            }
            if adapter.transition.options.isDestinationReusable {
                context.coordinator.isBeingReused = true
            } else {
                context.coordinator.adapter = nil
            }
        }
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize).replacingUnspecifiedDimensions(by: UIView.layoutFittingExpandedSize))
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
        var adapter: PresentationLinkDestinationViewControllerAdapter<Destination, SourceView>?
        var isBeingReused = false
        var animation: Animation?
        var didPresentAnimated = false
        weak var sourceView: UIView?
        var overrideTraitCollection: UITraitCollection?

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        private func makeContext(
            options: PresentationLinkTransition.Options
        ) -> PresentationLinkTransitionRepresentableContext {
            PresentationLinkTransitionRepresentableContext(
                sourceView: sourceView,
                options: options,
                environment: adapter?.environment ?? .init(),
                transaction: Transaction(animation: animation ?? (didPresentAnimated ? .default : nil))
            )
        }

        func onDismiss(_ count: Int, transaction: Transaction) {
            guard let viewController = adapter?.viewController, count > 0 else { return }
            let presentingViewController = {
                var remaining = count
                var presentingViewController = viewController
                if remaining == 1, presentingViewController.presentedViewController == nil {
                    remaining -= 1
                }
                while remaining > 0, let next = presentingViewController.presentingViewController {
                    presentingViewController = next
                    remaining -= 1
                }
                return presentingViewController
            }()
            animation = transaction.animation
            didPresentAnimated = false
            presentingViewController.dismiss(animated: transaction.isAnimated) {
                withTransaction(transaction) {
                    self.isPresented.wrappedValue = false
                }
            }
        }

        // MARK: - UIViewControllerPresentationDelegate

        func viewControllerDidDismiss(
            _ presentingViewController: UIViewController?,
            animated: Bool
        ) {
            // Break the retain cycle
            adapter?.coordinator = nil

            if isPresented.wrappedValue {
                var transaction = Transaction(animation: animated ? .default : nil)
                transaction.disablesAnimations = true
                withCATransaction {
                    withTransaction(transaction) {
                        self.isPresented.wrappedValue = false
                    }
                }
            }

            // Dismiss already handled by the presentation controller below
            if let presentingViewController {
                presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: animated)
                presentingViewController.fixSwiftUIHitTesting()
            }
        }

        // MARK: - UIAdaptivePresentationControllerDelegate

        func presentationControllerDidDismiss(
            _ presentationController: UIPresentationController
        ) {
            // Break the retain cycle
            adapter?.coordinator = nil

            presentationController.presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: true)
            presentationController.presentingViewController.fixSwiftUIHitTesting()
        }

        func presentationControllerShouldDismiss(
            _ presentationController: UIPresentationController
        ) -> Bool {
            guard let transition = adapter?.transition else { return true }
            return transition.options.isInteractive
        }

        func presentationControllerDidAttemptToDismiss(
            _ presentationController: UIPresentationController
        ) {
            presentationController.presentedViewController.fixSwiftUIHitTesting()
        }

        func adaptivePresentationStyle(
            for controller: UIPresentationController
        ) -> UIModalPresentationStyle {
            adaptivePresentationStyle(
                for: controller,
                traitCollection: controller.traitCollection
            )
        }

        func adaptivePresentationStyle(
            for controller: UIPresentationController,
            traitCollection: UITraitCollection
        ) -> UIModalPresentationStyle {
            switch adapter?.transition {
            case .popover(let options):
                return options.adaptiveTransition != nil && traitCollection.horizontalSizeClass == .compact ? .pageSheet : .none

            case .representable(_, let transition):
                return transition.adaptivePresentationStyle(
                    for: controller,
                    traitCollection: traitCollection
                )

            default:
                return .none
            }
        }

        func presentationController(
            _ presentationController: UIPresentationController,
            prepare adaptivePresentationController: UIPresentationController
        ) {
            guard let adapter else { return }
            switch adapter.transition {
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

            case .representable(let options, let transition):
                let context = PresentationLinkTransitionRepresentableContext(
                    sourceView: sourceView,
                    options: options,
                    environment: adapter.environment,
                    transaction: Transaction(animation: animation)
                )
                transition.updateAdaptivePresentationController(
                    adaptivePresentationController: adaptivePresentationController,
                    context: context
                )

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
            guard adapter?.viewController.presentationDelegate == self else { return nil }
            switch adapter?.transition {
            case .sheet(let options):
                #if targetEnvironment(macCatalyst)
                if #available(iOS 15.0, *) {
                    let transition = MacSheetTransition(
                        preferredCornerRadius: options.preferredCornerRadius,
                        isPresenting: true,
                        animation: animation
                    )
                    transition.wantsInteractiveStart = false
                    return transition
                }
                #endif
                return nil

            case .representable(let options, let transition):
                return transition.animationController(
                    forPresented: presented,
                    presenting: presenting,
                    context: makeContext(options: options)
                )

            default:
                return nil
            }
        }

        func animationController(
            forDismissed dismissed: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            guard adapter?.viewController.presentationDelegate == self else { return nil }
            switch adapter?.transition {
            case .sheet(let options):
                #if targetEnvironment(macCatalyst)
                if #available(iOS 15.0, *),
                   let presentationController = dismissed.presentationController as? MacSheetPresentationController
                {
                    let transition = MacSheetTransition(
                        preferredCornerRadius: options.preferredCornerRadius,
                        isPresenting: false,
                        animation: animation
                    )
                    transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
                    presentationController.transition(with: transition)
                    return transition
                }
                #endif
                return nil

            case .representable(let options, let transition):
                let animationController = transition.animationController(
                    forDismissed: dismissed,
                    context: makeContext(options: options)
                )
                if let transition = animationController as? UIPercentDrivenInteractiveTransition, transition.wantsInteractiveStart {
                    if let presentationController = dismissed.presentationController as? InteractivePresentationController {
                        transition.wantsInteractiveStart = options.isInteractive && presentationController.wantsInteractiveTransition
                    } else if !options.isInteractive {
                        transition.wantsInteractiveStart = false
                    }
                }
                return animationController

            default:
                return nil
            }
        }

        func interactionControllerForPresentation(
            using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
            guard adapter?.viewController.presentationDelegate == self else { return nil }
            switch adapter?.transition {
            case .representable(let options, let transition):
                return transition.interactionControllerForPresentation(
                    using: animator,
                    context: makeContext(options: options)
                )

            default:
                return nil
            }
        }

        func interactionControllerForDismissal(
            using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
            guard adapter?.viewController.presentationDelegate == self else { return nil }
            switch adapter?.transition {
            case .sheet:
                #if targetEnvironment(macCatalyst)
                if #available(iOS 15.0, *) {
                    return animator as? MacSheetTransition
                }
                #endif
                return nil

            case .representable(let options, let transition):
                return transition.interactionControllerForDismissal(
                    using: animator,
                    context: makeContext(options: options)
                )

            default:
                return nil
            }
        }

        func presentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            guard let adapter else { return nil }
            switch adapter.transition {
            case .sheet(let options):
                if #available(iOS 15.0, *) {
                    #if targetEnvironment(macCatalyst)
                    let presentationController = MacSheetPresentationController(
                        presentedViewController: presented,
                        presenting: presenting
                    )
                    let selected = options.selected?.wrappedValue
                    presentationController.detent = options.detents.first(where: { $0.identifier == selected }) ?? options.detents.first ?? .large
                    presentationController.selected = options.selected
                    presentationController.largestUndimmedDetentIdentifier = options.largestUndimmedDetentIdentifier
                    return presentationController
                    #else
                    let presentationController = SheetPresentationController(
                        presentedViewController: presented,
                        presenting: presenting
                    )
                    presentationController.detents = options.detents.map {
                        $0.toUIKit(in: presentationController)
                    }
                    presentationController.selectedDetentIdentifier = (options.selected?.wrappedValue ?? options.detents.first?.identifier)?.toUIKit()
                    presentationController.largestUndimmedDetentIdentifier = options.largestUndimmedDetentIdentifier?.toUIKit()
                    presentationController.prefersGrabberVisible = options.prefersGrabberVisible
                    presentationController.preferredCornerRadius = options.preferredCornerRadius
                    presentationController.prefersScrollingExpandsWhenScrolledToEdge = options.prefersScrollingExpandsWhenScrolledToEdge
                    presentationController.prefersEdgeAttachedInCompactHeight = options.prefersEdgeAttachedInCompactHeight
                    presentationController.widthFollowsPreferredContentSizeWhenEdgeAttached = options.widthFollowsPreferredContentSizeWhenEdgeAttached
                    if options.prefersSourceViewAlignment {
                        presentationController.sourceView = sourceView
                    }
                    if #available(iOS 17.0, *) {
                        presentationController.prefersPageSizing = options.prefersPageSizing
                    }
                    presentationController.preferredBackgroundColor = options.options.preferredPresentationBackgroundUIColor
                    presentationController.overrideTraitCollection = overrideTraitCollection
                    presentationController.delegate = self
                    return presentationController
                    #endif
                }

            case .popover(let options):
                let presentationController = PopoverPresentationController(
                    presentedViewController: presented,
                    presenting: presenting
                )
                presentationController.canOverlapSourceViewRect = options.canOverlapSourceViewRect
                presentationController.permittedArrowDirections = options.permittedArrowDirections(
                    layoutDirection: presentationController.traitCollection.layoutDirection
                )
                presentationController.sourceView = sourceView
                presentationController.overrideTraitCollection = overrideTraitCollection
                presentationController.delegate = self
                return presentationController

            case .representable(let options, let transition):
                let presentationController = transition.makeUIPresentationController(
                    presented: presented,
                    presenting: presenting,
                    context: makeContext(options: options)
                )
                presentationController.overrideTraitCollection = overrideTraitCollection
                presentationController.delegate = self
                return presentationController

            default:
                break
            }

            let presentationController = PresentationController(
                presentedViewController: presented,
                presenting: presenting
            )
            presentationController.overrideTraitCollection = overrideTraitCollection
            presentationController.delegate = self
            return presentationController
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
                        sheetPresentationController.detents = configuration.detents.map {
                            $0.toUIKit(in: sheetPresentationController)
                        }
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

        func prepareForPopoverPresentation(
            _ popoverPresentationController: UIPopoverPresentationController
        ) {
            popoverPresentationController.presentedViewController.view.layoutIfNeeded()
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        if let adapter = coordinator.adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                withCATransaction {
                    adapter.viewController.dismiss(animated: coordinator.didPresentAnimated)
                }
                coordinator.adapter = nil
            } else {
                adapter.coordinator = coordinator
            }
        }
    }
}

@available(iOS 14.0, *)
private class PresentationLinkDestinationViewControllerAdapter<
    Destination: View,
    SourceView: View
> {

    typealias DestinationController = PresentationHostingController<ModifiedContent<Destination, PresentationBridgeAdapter>>

    var viewController: UIViewController!
    var context: Any!

    var transition: PresentationLinkTransition.Value
    var environment: EnvironmentValues
    var isPresented: Binding<Bool>
    var conformance: ProtocolConformance<UIViewControllerRepresentableProtocolDescriptor>? = nil
    var onDismiss: (Int, Transaction) -> Void

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: PresentationLinkAdapterBody<Destination, SourceView>.Coordinator?

    init(
        destination: Destination,
        sourceView: UIView,
        transition: PresentationLinkTransition.Value,
        context: PresentationLinkAdapterBody<Destination, SourceView>.Context,
        isPresented: Binding<Bool>,
        onDismiss: @escaping (Int, Transaction) -> Void
    ) {
        self.transition = transition
        self.environment = context.environment
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Destination.self) {
            self.conformance = conformance
            update(
                destination: destination,
                sourceView: sourceView,
                context: context,
                isPresented: isPresented
            )
        } else {
            let viewController = DestinationController(
                content: destination.modifier(
                    PresentationBridgeAdapter(
                        presentationCoordinator: PresentationCoordinator(
                            isPresented: isPresented.wrappedValue,
                            sourceView: sourceView,
                            dismissBlock: { [weak self] in
                                self?.dismiss($0, $1)
                            }
                        )
                    )
                )
            )
            transition.update(
                viewController,
                context: PresentationLinkTransitionRepresentableContext(
                    sourceView: sourceView,
                    options: transition.options,
                    environment: context.environment,
                    transaction: context.transaction
                )
            )
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
        sourceView: UIView,
        context: PresentationLinkAdapterBody<Destination, SourceView>.Context,
        isPresented: Binding<Bool>
    ) {
        environment = context.environment
        self.isPresented = isPresented
        if let conformance = conformance {
            var visitor = Visitor(
                destination: destination,
                isPresented: isPresented,
                sourceView: sourceView,
                context: context,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
            switch transition {
            case .representable(let options, _):
                viewController.modalPresentationCapturesStatusBarAppearance = options.modalPresentationCapturesStatusBarAppearance
            default:
                break
            }
        } else {
            let viewController = viewController as! DestinationController
            viewController.content = destination.modifier(
                PresentationBridgeAdapter(
                    presentationCoordinator: PresentationCoordinator(
                        isPresented: isPresented.wrappedValue,
                        sourceView: sourceView,
                        dismissBlock: { [weak self] in self?.dismiss($0, $1) }
                    )
                )
            )
            transition.update(
                viewController,
                context: .init(
                    sourceView: sourceView,
                    options: transition.options,
                    environment: context.environment,
                    transaction: context.transaction
                )
            )
        }
    }

    func dismiss(_ count: Int, _ transaction: Transaction) {
        onDismiss(count, transaction)
    }

    private struct Context<Coordinator> {
        // Only `UIViewRepresentable` uses V4
        struct V4 {
            struct RepresentableContextValues {
                enum EnvironmentStorage {
                    case eager(EnvironmentValues)
                    case lazy(() -> EnvironmentValues)
                }
                var preferenceBridge: AnyObject?
                var transaction: Transaction
                var environmentStorage: EnvironmentStorage
            }

            var values: RepresentableContextValues
            var coordinator: Coordinator

            var environment: EnvironmentValues {
                get {
                    switch values.environmentStorage {
                    case .eager(let environment):
                        return environment
                    case .lazy(let block):
                        return block()
                    }
                }
                set {
                    values.environmentStorage = .eager(newValue)
                }
            }
        }

        struct V1 {
            var coordinator: Coordinator
            var transaction: Transaction
            var environment: EnvironmentValues
            var preferenceBridge: AnyObject?
        }
    }

    private struct Visitor: ViewVisitor {
        var destination: Destination?
        var isPresented: Binding<Bool>
        var sourceView: UIView?
        var context: PresentationLinkAdapterBody<Destination, SourceView>.Context?
        var adapter: PresentationLinkDestinationViewControllerAdapter<Destination, SourceView>

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
                let coordinator = destination.makeCoordinator()
                let preferenceBridge: AnyObject?
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<PresentationLinkAdapterBody<Destination, SourceView>.Coordinator>.V4.self
                    ).values.preferenceBridge
                } else {
                    preferenceBridge = unsafeBitCast(
                        context,
                        to: Context<PresentationLinkAdapterBody<Destination, SourceView>.Coordinator>.V1.self
                    ).preferenceBridge
                }
                let context = Context<Content.Coordinator>.V1(
                    coordinator: coordinator,
                    transaction: context.transaction,
                    environment: context.environment,
                    preferenceBridge: preferenceBridge
                )
                adapter.context = unsafeBitCast(context, to: Content.Context.self)
            }
            func project<T>(_ value: T) -> Content.Context {
                let presentationCoordinator = PresentationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    sourceView: sourceView,
                    dismissBlock: { [weak adapter] in
                        adapter?.dismiss($0, $1)
                    }
                )
                var ctx = unsafeBitCast(value, to: Context<Content.Coordinator>.V1.self)
                ctx.environment.presentationCoordinator = presentationCoordinator
                return unsafeBitCast(ctx, to: Content.Context.self)
            }
            let ctx = _openExistential(adapter.context!, do: project)
            if adapter.viewController == nil {
                adapter.viewController = destination.makeUIViewController(context: ctx)
            }
            let viewController = adapter.viewController as! Content.UIViewControllerType
            destination.updateUIViewController(viewController, context: ctx)
        }
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition.Value {

    func update<Content: View>(
        _ viewController: PresentationHostingController<Content>,
        context: @autoclosure () -> PresentationLinkTransitionRepresentableContext
    ) {

        viewController.modalPresentationCapturesStatusBarAppearance = options.modalPresentationCapturesStatusBarAppearance
        if let backgroundColor = options.preferredPresentationBackgroundUIColor {
            viewController.view.backgroundColor = backgroundColor
        }

        switch self {
        case .sheet(let options):
            if #available(iOS 15.0, *) {
                viewController.tracksContentSize = options.widthFollowsPreferredContentSizeWhenEdgeAttached || options.detents.contains(where: { $0.identifier == .ideal || $0.resolution != nil })
            } else {
                viewController.tracksContentSize = options.widthFollowsPreferredContentSizeWhenEdgeAttached
            }

        case .popover:
            viewController.tracksContentSize = true

        case .representable(_, let transition):
            transition.updateHostingController(presenting: viewController, context: context())

        default:
            break
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct PresentationLinkAdapter_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            VStack {
                PresentationLinkAdapter(transition: .default, isPresented: .constant(false)) {

                } content: {
                    Color.yellow
                        .aspectRatio(1, contentMode: .fit)
                }
                .border(Color.red)

                PresentationLinkAdapter(transition: .default, isPresented: .constant(false)) {

                } content: {
                    Color.yellow
                        .frame(width: 44, height: 44)
                }
                .border(Color.red)

                PresentationLinkAdapter(transition: .default, isPresented: .constant(false)) {

                } content: {
                    Text("Hello, World")
                }
                .border(Color.red)
            }
        }
    }
    static var previews: some View {
        Preview()

        ScrollView {
            Preview()
        }
    }
}

#endif
