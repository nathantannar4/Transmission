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
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var isPresented: Binding<Bool>
    var content: Content
    var destination: Destination

    public init(
        transition: PresentationLinkTransition,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) where Content == EmptyView {
        self.init(
            transition: transition,
            isPresented: isPresented,
            destination: destination,
            content: {
                EmptyView()
            }
        )
    }

    public init(
        transition: PresentationLinkTransition,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.isPresented = isPresented
        self.content = content()
        self.destination = destination()
    }

    public var body: some View {
        PresentationLinkAdapterBody(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
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
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
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
        uiView.hostingView?.cornerRadius = cornerRadius
        uiView.backgroundColor = backgroundColor?.toUIColor()

        if let presentingViewController = presentingViewController, isPresented.wrappedValue {

            context.coordinator.isPresented = isPresented

            let traits = UITraitCollection(traitsFrom: [
                presentingViewController.traitCollection,
                UITraitCollection(userInterfaceStyle: .init(transition.value.options.preferredPresentationColorScheme ?? context.environment.colorScheme)),
                UITraitCollection(userInterfaceLevel: .elevated),
            ])

            var isAnimated = context.transaction.isAnimated
                || presentingViewController.transitionCoordinator?.isAnimated == true
            let animation = context.transaction.animation
                ?? (isAnimated ? .default : nil)
            context.coordinator.animation = animation
            var isTransitioningPresentationController = false
            let sourceView = uiView.hostingView ?? uiView

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
                                sourceView: sourceView,
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
                        sourceView: sourceView,
                        context: context,
                        isPresented: isPresented
                    )
                    context.coordinator.isBeingReused = false
                } else {
                    adapter = PresentationLinkDestinationViewControllerAdapter(
                        destination: destination,
                        sourceView: sourceView,
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
                        context.coordinator.presentationController = presentationController

                        if #available(iOS 15.0, *),
                           let sheetPresentationController = presentationController as? UISheetPresentationController
                        {
                            sheetPresentationController.delegate = context.coordinator
                            if case .sheet(let options) = adapter.transition,
                               options.prefersSourceViewAlignment
                            {
                                sheetPresentationController.sourceView = sourceView
                            }
                        } else if let popoverPresentationController = presentationController as? UIPopoverPresentationController {
                            popoverPresentationController.delegate = context.coordinator
                            popoverPresentationController.sourceView = sourceView
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
                    if let presentationController = adapter.viewController.presentationController {
                        presentationController.delegate = context.coordinator
                        presentationController.overrideTraitCollection = traits
                        context.coordinator.presentationController = presentationController
                    }

                case .fullscreen:
                    adapter.viewController.modalPresentationStyle = .overFullScreen
                    if let presentationController = adapter.viewController.presentationController {
                        presentationController.delegate = context.coordinator
                        presentationController.overrideTraitCollection = traits
                        context.coordinator.presentationController = presentationController
                    }

                case .popover:
                    context.coordinator.sourceView = sourceView
                    context.coordinator.overrideTraitCollection = traits
                    adapter.viewController.modalPresentationStyle = .custom

                case .sheet(let options):
                    context.coordinator.sourceView = sourceView
                    context.coordinator.overrideTraitCollection = traits
                    adapter.viewController.modalPresentationStyle = .custom

                    if options.prefersZoomTransition, #available(iOS 18.0, *) {
                        let zoomOptions = UIViewController.Transition.ZoomOptions()
                        adapter.viewController.preferredTransition = .zoom(options: zoomOptions) { [weak sourceView] context in
                            guard sourceView?.window != nil else { return nil }
                            return sourceView
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissPanGesture }) {
                            zoomGesture.addTarget(context.coordinator, action: #selector(Coordinator.zoomPanGestureDidChange(_:)))
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissEdgeGesture }) {
                            zoomGesture.addTarget(context.coordinator, action: #selector(Coordinator.zoomEdgePanGestureDidChange(_:)))
                        }
                    }

                case .zoom(let options):
                    if #available(iOS 18.0, *) {
                        let zoomOptions = UIViewController.Transition.ZoomOptions()
                        zoomOptions.dimmingColor = options.dimmingColor?.toUIColor()
                        zoomOptions.dimmingVisualEffect = options.dimmingVisualEffect.map { UIBlurEffect(style: $0) }
                        adapter.viewController.preferredTransition = .zoom(options: zoomOptions) { [weak sourceView] context in
                            guard sourceView?.window != nil else { return nil }
                            return sourceView
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissPanGesture }) {
                            zoomGesture.addTarget(context.coordinator, action: #selector(Coordinator.zoomPanGestureDidChange(_:)))
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissEdgeGesture }) {
                            zoomGesture.addTarget(context.coordinator, action: #selector(Coordinator.zoomEdgePanGestureDidChange(_:)))
                        }
                    }
                    context.coordinator.sourceView = sourceView
                    context.coordinator.overrideTraitCollection = traits
                    adapter.viewController.modalPresentationStyle = .custom

                case .representable(_, let transition):
                    assert(!swift_getIsClassType(transition), "PresentationLinkTransitionRepresentable must be value types (either a struct or an enum); it was a class")
                    context.coordinator.sourceView = sourceView
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
                    guard
                        isPresented.wrappedValue,
                        let viewController = context.coordinator.adapter?.viewController
                    else {
                        context.coordinator.didDismiss()
                        return
                    }
                    presentingViewController.present(
                        viewController,
                        animated: isAnimated
                    ) { [isAnimated, isTransitioningPresentationController] in
                        context.coordinator.animation = nil
                        context.coordinator.didPresentAnimated = isAnimated
                        if context.coordinator.adapter !== adapter {
                            viewController.dismiss(animated: isAnimated)
                        } else if !isPresented.wrappedValue {
                            var transaction = Transaction(animation: nil)
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                isPresented.wrappedValue = false
                            }
                        } else {
                            viewController
                                .setNeedsStatusBarAppearanceUpdate(animated: isAnimated)
                            if isTransitioningPresentationController {
                                viewController.presentationDelegate = context.coordinator
                            }
                        }
                    }
                }
                var didPresent = false
                if let presentedViewController = presentingViewController.presentedViewController {
                    if presentedViewController.presentationDelegate == context.coordinator {
                        presentedViewController.presentationDelegate = nil
                    }
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
                        didPresent = true
                        if let firstResponder = presentedViewController.firstResponder {
                            withCATransaction {
                                firstResponder.resignFirstResponder()
                                presentedViewController.dismiss(
                                    animated: isAnimated,
                                    completion: present
                                )
                            }
                        } else {
                            presentedViewController.dismiss(
                                animated: isAnimated,
                                completion: present
                            )
                        }
                    }
                }
                if !didPresent {
                    if let firstResponder = presentingViewController.firstResponder {
                        withCATransaction {
                            firstResponder.resignFirstResponder()
                            present()
                        }
                    } else {
                        present()
                    }
                }
            }
        } else if !isPresented.wrappedValue,
            context.coordinator.adapter != nil,
            !context.coordinator.isBeingReused
        {
            context.coordinator.onDismiss(1, transaction: context.transaction)
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
        var overrideTraitCollection: UITraitCollection? {
            didSet {
                if #available(iOS 17.0, *) {
                    guard oldValue?.changedTraits(from: overrideTraitCollection).isEmpty != true else { return }
                    presentationController?.overrideTraitCollection = overrideTraitCollection
                } else {
                    presentationController?.overrideTraitCollection = overrideTraitCollection
                }
            }
        }

        var isZoomTransitionDismissReady = false
        var feedbackGenerator: UIImpactFeedbackGenerator?

        weak var presentationController: UIPresentationController?

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
            guard let viewController = adapter?.viewController, count > 0, presentationController != nil else { return }
            animation = transaction.animation
            didPresentAnimated = false
            viewController._dismiss(count: count, animated: transaction.isAnimated) {
                self.onDismiss(transaction)
            }
        }

        private func onDismiss(_ transaction: Transaction) {
            if isPresented.wrappedValue == true {
                withTransaction(transaction) {
                    isPresented.wrappedValue = false
                }
            }
            didDismiss()
        }

        func didDismiss() {
            if adapter?.transition.options.isDestinationReusable == true {
                isBeingReused = true
            } else {
                adapter = nil
                isBeingReused = false
            }
        }

        // MARK: - UIViewControllerPresentationDelegate

        func viewControllerDidDismiss(
            _ viewController: UIViewController,
            presentingViewController: UIViewController?,
            animated: Bool
        ) {
            // Break the retain cycle
            adapter?.coordinator = nil

            if isPresented.wrappedValue {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withCATransaction {
                    withTransaction(transaction) {
                        self.isPresented.wrappedValue = false
                    }
                }
                didDismiss()
            }

            // Dismiss already handled by the presentation controller below
            if let presentingViewController {
                presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: animated)
                presentingViewController.fixSwiftUIHitTesting()
            }
        }

        // MARK: - UIAdaptivePresentationControllerDelegate

        func presentationControllerWillDismiss(
            _ presentationController: UIPresentationController
        ) {
            guard presentationController == self.presentationController else { return }
            var transaction = Transaction(animation: animation ?? .default)
            transaction.disablesAnimations = true
            if let transitionCoordinator = adapter?.viewController?.transitionCoordinator, transitionCoordinator.isInteractive {
                transitionCoordinator.notifyWhenInteractionChanges { ctx in
                    if !ctx.isCancelled {
                        self.onDismiss(transaction)
                    }
                }
            } else {
                onDismiss(transaction)
            }
        }

        func presentationControllerDidDismiss(
            _ presentationController: UIPresentationController
        ) {
            guard presentationController == self.presentationController else { return }
            if isPresented.wrappedValue {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withCATransaction {
                    withTransaction(transaction) {
                        self.isPresented.wrappedValue = false
                    }
                }
                didDismiss()
            }

            // Break the retain cycle
            adapter?.coordinator = nil

            self.presentationController = nil

            presentationController.presentingViewController.setNeedsStatusBarAppearanceUpdate(animated: true)
            presentationController.presentingViewController.fixSwiftUIHitTesting()
        }

        func presentationControllerShouldDismiss(
            _ presentationController: UIPresentationController
        ) -> Bool {
            guard presentationController == self.presentationController else { return true }
            guard let transition = adapter?.transition else { return true }
            switch transition {
            case .zoom(let options):
                guard options.options.isInteractive else { return false }
                // By default, zoom is too easy to dismiss a presented view rather than pop
                let zoomEdgeGesture = presentationController.presentedViewController
                    .view
                    .gestureRecognizers?
                    .compactMap({ $0.isZoomDismissEdgeGesture ? $0 as? UIPanGestureRecognizer : nil })
                    .first
                if let zoomEdgeGesture, zoomEdgeGesture.state == .possible {
                    let navigationController = presentationController.presentedViewController as? UINavigationController ?? presentationController.presentedViewController.firstDescendent(ofType: UINavigationController.self)
                    if let navigationController,
                        navigationController.viewControllers.count > 1,
                        let edgeGesture = navigationController.interactivePopGestureRecognizer as? UIScreenEdgePanGestureRecognizer,
                        edgeGesture.isEnabled
                    {
                        let translation = zoomEdgeGesture.location(in: presentationController.presentedViewController.view)
                        let edgeDistance: CGFloat = 16
                        if edgeGesture.edges.contains(.left) {
                            if translation.x <= edgeDistance {
                                return false
                            }
                        }
                        if edgeGesture.edges.contains(.right) {
                            let width = presentationController.presentedViewController.view.bounds.width
                            if translation.x >= (width - edgeDistance) {
                                return false
                            }
                        }
                    }
                }
                return true
            default:
                return transition.options.isInteractive
            }
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
            guard let adapter, presentationController == self.presentationController else { return .none }
            switch adapter.transition {
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
            guard let adapter, presentationController == self.presentationController else { return }
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
                guard let presentationController else { return nil }
                let animationController = transition.animationController(
                    forPresented: presented,
                    presenting: presenting,
                    presentationController: presentationController,
                    context: makeContext(options: options)
                )
                return animationController

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
                    presentationController.transition = transition
                    return transition
                }
                #endif
                return nil

            case .representable(let options, let transition):
                guard let presentationController else { return nil }
                let animationController = transition.animationController(
                    forDismissed: dismissed,
                    presentationController: presentationController,
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
            let presentationController = makePresentationController(
                forPresented: presented,
                presenting: presenting,
                source: source
            )
            self.presentationController = presentationController
            return presentationController
        }

        func makePresentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            switch adapter?.transition {
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
                    presentationController.preferredCornerRadiusOptions = options.preferredCornerRadius
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
                    if #available(iOS 26.0, *),
                       options.options.preferredPresentationBackgroundColor == nil,
                       options.detents.contains(where: { $0.identifier != .large || $0.identifier != .fullScreen }),
                       options.selected?.wrappedValue != .large,
                       options.selected?.wrappedValue != .fullScreen
                    {
                        presented.view.backgroundColor = .clear
                    }
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
                let context = makeContext(options: options)
                func project<T: PresentationLinkTransitionRepresentable>(
                    _ transition: T
                ) -> UIPresentationController {
                    let presentationController = transition.makeUIPresentationController(
                        presented: presented,
                        presenting: presenting,
                        source: source,
                        context: context
                    )
                    transition.updateUIPresentationController(
                        presentationController: presentationController,
                        context: context
                    )
                    return presentationController
                }
                let presentationController = _openExistential(transition, do: project)
                presentationController.overrideTraitCollection = overrideTraitCollection
                presentationController.delegate = self
                return presentationController

            case .zoom:
                let presentationController = DelegatedPresentationController(
                    presentedViewController: presented,
                    presenting: presenting
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
            if case .sheet(let options) = adapter?.transition {
                func applySelection() {
                    let newValue = sheetPresentationController.selectedDetentIdentifier.map {
                        PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier($0.rawValue)
                    }
                    if let selected = options.selected, selected.wrappedValue != newValue {
                        selected.wrappedValue = newValue
                    }
                    if #available(iOS 26.0, *) {
                        switch newValue {
                        case .large, .fullScreen:
                            sheetPresentationController.presentedViewController.view.backgroundColor = options.options.preferredPresentationBackgroundUIColor ?? .systemBackground
                        default:
                            sheetPresentationController.presentedViewController.view.backgroundColor = .clear
                        }
                    }
                }

                if sheetPresentationController.selectedDetentIdentifier?.rawValue == PresentationLinkTransition.SheetTransitionOptions.Detent.ideal.identifier.rawValue {
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        sheetPresentationController.invalidateDetents()
                        applySelection()
                    } else {
                        sheetPresentationController.detents = options.detents.map {
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

        // MARK: - Zoom Transition

        @objc
        func zoomPanGestureDidChange(_ panGesture: UIPanGestureRecognizer) {
            zoomGestureDidChange(panGesture: panGesture, isDismiss: true)
        }

        @objc
        func zoomEdgePanGestureDidChange(_ edgePanGesture: UIScreenEdgePanGestureRecognizer) {
            zoomGestureDidChange(panGesture: edgePanGesture, isDismiss: false)
        }

        private func zoomGestureDidChange(
            panGesture: UIPanGestureRecognizer,
            isDismiss: Bool
        ) {
            switch panGesture.state {
            case .ended, .cancelled:
                isZoomTransitionDismissReady = false
                feedbackGenerator = nil
            default:
                guard
                    case .zoom(let options) = adapter?.transition,
                    let hapticsStyle = options.hapticsStyle,
                    let view = panGesture.view
                else {
                    return
                }
                let velocity = isDismiss ? panGesture.velocity(in: view).y : panGesture.velocity(in: view).x
                let translation = isDismiss ? panGesture.translation(in: view).y : panGesture.translation(in: view).x
                let threshold = isDismiss ? UIGestureRecognizer.zoomGestureActivationThreshold.height : UIGestureRecognizer.zoomGestureActivationThreshold.width
                func impactOccurred(
                    intensity: CGFloat,
                    location: @autoclosure () -> CGPoint
                ) {
                    if #available(iOS 17.5, *) {
                        feedbackGenerator?.impactOccurred(intensity: intensity, at: location())
                    } else {
                        feedbackGenerator?.impactOccurred(intensity: intensity)
                    }
                }

                if feedbackGenerator == nil {
                    let feedbackGenerator: UIImpactFeedbackGenerator
                    if #available(iOS 17.5, *) {
                        feedbackGenerator = UIImpactFeedbackGenerator(style: hapticsStyle, view: view)
                    } else {
                        feedbackGenerator = UIImpactFeedbackGenerator(style: hapticsStyle)
                    }
                    feedbackGenerator.prepare()
                    self.feedbackGenerator = feedbackGenerator
                } else if !isZoomTransitionDismissReady, translation >= threshold, velocity >= 0 {
                    isZoomTransitionDismissReady = true
                    impactOccurred(intensity: 1, location: panGesture.location(in: view))
                } else if isZoomTransitionDismissReady, translation < threshold, velocity < 0
                {
                    impactOccurred(intensity: 0.5, location: panGesture.location(in: view))
                    isZoomTransitionDismissReady = false
                }
            }
        }
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        if let adapter = coordinator.adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                var transaction = Transaction(animation: coordinator.didPresentAnimated ? .default : nil)
                transaction.disablesAnimations = true
                withCATransaction {
                    coordinator.onDismiss(1, transaction: transaction)
                }
            } else {
                adapter.coordinator = coordinator
            }
        }
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
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
                        ),
                        colorScheme: transition.options.preferredPresentationColorScheme ?? context.environment.colorScheme
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
            viewController.modalPresentationCapturesStatusBarAppearance = transition.options.modalPresentationCapturesStatusBarAppearance
            if let backgroundColor = transition.options.preferredPresentationBackgroundUIColor {
                viewController.view.backgroundColor = backgroundColor
            }
        } else {
            let viewController = viewController as! DestinationController
            viewController.content = destination.modifier(
                PresentationBridgeAdapter(
                    presentationCoordinator: PresentationCoordinator(
                        isPresented: isPresented.wrappedValue,
                        sourceView: sourceView,
                        dismissBlock: { [weak self] in self?.dismiss($0, $1) }
                    ),
                    colorScheme: transition.options.preferredPresentationColorScheme ?? context.environment.colorScheme
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

    @MainActor
    private struct Visitor: @preconcurrency ViewVisitor {
        nonisolated(unsafe) var destination: Destination?
        nonisolated(unsafe) var isPresented: Binding<Bool>
        nonisolated(unsafe) var sourceView: UIView?
        nonisolated(unsafe) var context: PresentationLinkAdapterBody<Destination, SourceView>.Context?
        nonisolated(unsafe) var adapter: PresentationLinkDestinationViewControllerAdapter<Destination, SourceView>

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
