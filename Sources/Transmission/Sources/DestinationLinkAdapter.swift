//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import EngineCore

/// A view that manages the push of a destination view in a new `UIViewController`.  The presentation is
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
///  - ``DestinationLink``
///  - ``DestinationLinkTransition``
///  - ``DestinationSourceViewLink``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with the ``DestinationLinkTransition/custom(_:)``
///  transition.
///
@frozen
@available(iOS 14.0, *)
public struct DestinationLinkAdapter<
    Content: View,
    Destination: View
>: View {

    var transition: DestinationLinkTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var isPresented: Binding<Bool>
    var content: Content
    var destination: Destination

    public init(
        transition: DestinationLinkTransition,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.isPresented = isPresented
        self.content = content()
        self.destination = destination()
    }

    public var body: some View {
        DestinationLinkAdapterBody(
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
extension DestinationLinkAdapter {

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            isPresented: isPresented
        ) {
            ViewControllerRepresentableAdapter(destination)
        } content: {
            content()
        }
    }

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        destination: @escaping (ViewControllerRepresentableAdapter<ViewController>.Context) -> ViewController,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            isPresented: isPresented
        ) {
            ViewControllerRepresentableAdapter(destination)
        } content: {
            content()
        }
    }
}

@available(iOS 14.0, *)
private struct DestinationLinkAdapterBody<
    Destination: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: DestinationLinkTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var isPresented: Binding<Bool>
    var destination: Destination
    var sourceView: SourceView

    @WeakState var presentingViewController: UIViewController?

    typealias UIViewType = TransitionSourceView<SourceView>
    typealias DestinationViewController = DestinationHostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    func makeUIView(
        context: Context
    ) -> UIViewType {
        let uiView = UIViewType(
            presentingViewController: $presentingViewController,
            content: sourceView,
            useHostingController: {
                switch transition.value {
                case .zoom(let options):
                    if #unavailable(iOS 26.0) {
                        return !options.prefersScalePresentingView
                    }
                    return false
                default:
                    return false
                }
            }()
        )
        return uiView
    }

    func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        uiView.update(
            content: sourceView,
            transaction: context.transaction,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor?.toUIColor(in: context.environment)
        )
        context.coordinator.onUpdate(
            presentingViewController: presentingViewController,
            isPresented: isPresented,
            transition: transition,
            destination: destination,
            context: context,
            sourceView: uiView.sourceView ?? uiView
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIViewType,
        context: Context
    ) -> CGSize? {
        return uiView.sizeThatFits(ProposedSize(proposal))
    }

    func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize)) ?? size
    }

    static func dismantleUIView(
        _ uiView: UIViewType,
        coordinator: Coordinator
    ) {
        coordinator.onDismantle()
    }

    typealias Coordinator = DestinationLinkCoordinator<Destination, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }
}

@MainActor @preconcurrency
@available(iOS 14.0, *)
final class DestinationLinkCoordinator<
    Destination: View,
    Representable: UIViewRepresentable
>: NSObject, DestinationLinkCoordinatorDelegate, DestinationLinkDelegate
{
    var viewController: UIViewController? { adapter?.viewController }

    private var isPresented: Binding<Bool>
    private var adapter: DestinationLinkDestinationViewControllerAdapter<Destination, Representable>?
    private var animation: Animation?
    private var didPresentAnimated = false
    private var isPushing: Bool?
    private weak var sourceView: UIView?

    private var isZoomTransitionDismissReady = false
    private var feedbackGenerator: UIImpactFeedbackGenerator?

    private var wasNavigationBarHidden: Bool?

    init(isPresented: Binding<Bool>) {
        self.isPresented = isPresented
    }

    func onUpdate(
        presentingViewController: UIViewController?,
        isPresented: Binding<Bool>,
        transition: DestinationLinkTransition,
        destination: Destination,
        context: Representable.Context,
        sourceView: UIView,
        push: ((UIViewController) -> Void)? = nil
    ) {
        self.isPresented = isPresented

        if let presentingViewController, isPresented.wrappedValue {

            let isAnimated = context.transaction.isAnimated
                || (presentingViewController.transitionCoordinator?.isAnimated ?? false)
            let animation = context.transaction.animation
                ?? (isAnimated ? .default : nil)
            self.animation = animation

            let traits = UITraitCollection(
                traitsFrom: [
                    UITraitCollection(userInterfaceStyle: .init(transition.options.preferredPresentationColorScheme))
                ]
            )

            if let adapter {
                adapter.navigationController?.setOverrideTraitCollection(
                    traits,
                    forChild: adapter.viewController
                )
                adapter.transition = transition
                adapter.update(
                    destination: destination,
                    context: context,
                    isPresented: isPresented
                )
            } else if let navigationController = presentingViewController._navigationController {
                let adapter = DestinationLinkDestinationViewControllerAdapter(
                    destination: destination,
                    sourceView: sourceView,
                    transition: transition,
                    context: context,
                    navigationController: navigationController,
                    isPresented: isPresented,
                    onPop: { [weak self] in
                        self?.onPop($0, transaction: $1)
                    }
                )
                self.adapter = adapter
                switch adapter.transition.value {
                case .`default`:
                    break

                case .zoom(let options):
                    if #available(iOS 18.0, *) {
                        let zoomOptions = options.toUIKit()
                        zoomOptions.interactiveDismissShouldBegin = { [weak adapter] context in
                            context.willBegin && (adapter?.transition.options.isInteractive ?? true)
                        }
                        adapter.viewController.preferredTransition = .zoom(options: zoomOptions) { [weak self] _ in
                            guard let sourceView = self?.sourceView, sourceView.window != nil else { return nil }
                            return sourceView
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissPanGesture }) {
                            zoomGesture.addTarget(self, action: #selector(zoomPanGestureDidChange(_:)))
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissEdgeGesture }) {
                            zoomGesture.addTarget(self, action: #selector(zoomEdgePanGestureDidChange(_:)))
                        }
                        if let zoomGesture = adapter.viewController.view.gestureRecognizers?.first(where: { $0.isZoomDismissPinchGesture }) {
                            zoomGesture.addTarget(self, action: #selector(zoomPinchGestureDidChange(_:)))
                        }
                    }
                    self.sourceView = sourceView

                case .representable(let representable):
                    assert(!swift_getIsClassType(representable), "DestinationLinkCustomTransition must be value types (either a struct or an enum); it was a class")
                    self.sourceView = sourceView
                }

                navigationController.setOverrideTraitCollection(
                    traits,
                    forChild: adapter.viewController
                )

                navigationController.delegates.add(delegate: self, for: adapter.viewController)
                self.isPushing = true
                let present: () -> Void = {
                    self.didPresentAnimated = isAnimated
                    if let push {
                        push(adapter.viewController)
                    } else {
                        navigationController.pushViewController(
                            adapter.viewController,
                            animated: isAnimated
                        )
                    }
                }
                var didPresent = false
                if let transitionCoordinator = navigationController.transitionCoordinator,
                    transitionCoordinator.presentationStyle == .none
                {
                    if let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
                        let transition = navigationController.delegates.transition(for: fromVC) as? ViewControllerTransition
                    {
                        transition.complete()
                        present()
                        didPresent = true
                    } else if let toVC = transitionCoordinator.viewController(forKey: .to),
                        let transition = navigationController.delegates.transition(for: toVC) as? ViewControllerTransition
                    {
                        transition.complete()
                        present()
                        didPresent = true
                    }
                }
                if !didPresent {
                    if let firstResponder = navigationController.topViewController?.firstResponder {
                        withCATransaction {
                            firstResponder.resignFirstResponder()
                            CATransaction.flush()
                            present()
                        }
                    } else {
                        present()
                    }
                }
            } else {
                withCATransaction {
                    isPresented.wrappedValue = false
                }
            }
        } else if !isPresented.wrappedValue, adapter != nil {
            onPop(1, transaction: context.transaction)
        }
    }

    func onDismantle() {
        sourceView = nil
        if let adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                if isPushing != false {
                    let transaction = Transaction(animation: didPresentAnimated ? .default : nil)
                    withCATransaction {
                        self.onPop(1, transaction: transaction)
                    }
                }
            } else {
                adapter.coordinator = self
            }
        }
    }

    private func makeContext(
        options: DestinationLinkTransition.Options
    ) -> DestinationLinkTransitionRepresentableContext {
        DestinationLinkTransitionRepresentableContext(
            sourceView: sourceView,
            options: options,
            environment: adapter?.environment ?? .init(),
            transaction: Transaction(animation: animation ?? (didPresentAnimated ? .default : nil))
        )
    }

    func onPop(_ count: Int, transaction: Transaction) {
        guard
            let viewController = adapter?.viewController,
            viewController.navigationController != nil
        else {
            return
        }
        if count > 0 {
            animation = transaction.animation
            didPresentAnimated = false
            isPushing = false
        }

        var didPop = false
        if let transitionCoordinator = viewController.transitionCoordinator,
            transitionCoordinator.presentationStyle == .none
        {
            if let toVC = transitionCoordinator.viewController(forKey: .to),
                let transition = adapter?.navigationController?.delegates.transition(for: viewController)
            {
                if toVC == viewController {
                    didPop = true
                    transition.pause()
                    transition.endInteractiveTransition()
                    transition.cancel()
                    transitionCoordinator.animate { [weak self] _ in
                        self?.onPop(transaction)
                        self?.didPop()
                    }
                } else {
                    if let transition = transition as? ViewControllerTransition {
                        transition.complete()
                    } else {
                        transition.pause()
                        transition.endInteractiveTransition()
                        transition.finish()
                    }
                }
            } else if let fromVC = transitionCoordinator.viewController(forKey: .from),
                let transition = adapter?.navigationController?.delegates.transition(for: fromVC)
            {
                if let transition = transition as? ViewControllerTransition {
                    transition.complete()
                } else {
                    transition.pause()
                    transition.endInteractiveTransition()
                    transition.finish()
                }
            }
        }

        if !didPop {
            if let transitionCoordinator = viewController.transitionCoordinator,
                adapter?.navigationController?.zoomInteractionController == nil
            {
                transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                    viewController._popViewController(
                        count: count,
                        animated: transaction.isAnimated
                    ) { [weak self] success in
                        guard success, count > 0, self?.adapter?.viewController == viewController else { return }
                        self?.onPop(transaction)
                        self?.didPop()
                    }
                }
            } else {
                viewController._popViewController(
                    count: count,
                    animated: transaction.isAnimated
                ) { [weak self] success in
                    guard success, count > 0, self?.adapter?.viewController == viewController else { return }
                    self?.onPop(transaction)
                    self?.didPop()
                }
            }
        }
    }

    func onPop(_ transaction: Transaction) {
        if isPresented.wrappedValue == true {
            withTransaction(transaction) {
                self.isPresented.wrappedValue = false
            }
        }
    }

    func didPop() {
        if let viewController = adapter?.viewController,
            let navigationController = adapter?.navigationController
        {
            navigationController.delegates.remove(
                delegate: self,
                for: viewController
            )
        }
        adapter = nil
    }

    func navigationControllerCanBeginInteractivePop() -> Bool {
        guard let transition = adapter?.transition else { return true }
        guard transition.options.isInteractive else { return false }
        return true
    }

    func navigationControllerShouldBeginInteractivePop(
        _ navigationController: UINavigationController,
        gesture: UIGestureRecognizer
    ) -> Bool {
        guard navigationControllerCanBeginInteractivePop() else { return false }
        guard let transition = adapter?.transition else { return true }
        switch transition.value {
        case .zoom:
            // Allowing the built in gestures to start breaks the interruptibility of the zoom transition interaction
            return false
        default:
            let isEdge = gesture is UIScreenEdgePanGestureRecognizer
            if !isEdge, !transition.options.prefersPanGesturePop {
                return false
            }
            let isBuiltInGesture = {
                if gesture == navigationController.interactivePopGestureRecognizer {
                    return true
                }
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *), gesture == navigationController.interactiveContentPopGestureRecognizer {
                    return true
                }
                #endif
                return false
            }()
            if case .default = transition.value {
                return isBuiltInGesture
            } else {
                return !isBuiltInGesture
            }
        }
    }

    func navigationControllerHapticsForInteractivePop(
        _ navigationController: UINavigationController
    ) -> Int {
        guard let hapticsStyle = adapter?.transition.options.hapticsStyle else { return -1 }
        return hapticsStyle.rawValue
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willPop viewControllers: [UIViewController],
        animated: Bool
    ) {
        guard
            let viewController = adapter?.viewController,
            viewControllers.contains(viewController)
        else {
            return
        }
        if viewControllers.count > 1 {
            if #available(iOS 18.0, *), viewController != viewControllers.first, case .zoom = adapter?.transition.value {
                viewController.preferredTransition = nil
            }
            adapter?.transition = .default(options: adapter?.transition.options ?? .init())
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didPop viewController: UIViewController,
        isCancel: Bool,
        animated: Bool
    ) {
        guard
            let adapter,
            adapter.transition.options.shouldTransitionIsPresentedAlongsideTransition,
            viewController == adapter.viewController
        else {
            return
        }
        isPushing = false

        let transaction = Transaction(animation: animated ? animation ?? .default : nil)
        if let transitionCoordinator = navigationController.transitionCoordinator,
            transitionCoordinator.presentationStyle == .none
        {
            if isCancel {
                onPop(transaction)
                didPop()
            } else if #unavailable(iOS 18.0, ) {
                //  transitionCoordinator.animate not fired
                onPop(transaction)
            } else {
                let isInteractive = transitionCoordinator.isInteractive
                if isInteractive {
                    transitionCoordinator.notifyWhenInteractionChanges { [weak self] ctx in
                        if !ctx.isCancelled {
                            self?.onPop(transaction)
                            self?.didPop()
                        }
                    }
                }
                let isInterruptible = transitionCoordinator.isInterruptible
                transitionCoordinator.animate { [weak self] ctx in
                    if !ctx.isInteractive {
                        self?.onPop(transaction)
                        if !isInterruptible {
                            self?.didPop()
                        }
                    }
                } completion: { [weak self] ctx in
                    if ctx.isCancelled {
                        self?.isPresented.wrappedValue = true
                    } else if !isInteractive, isInterruptible {
                        self?.didPop()
                    }
                }
            }
        } else {
            onPop(transaction)
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard let viewController = adapter?.viewController else { return }
        let hasViewController = navigationController.viewControllers.contains(viewController)
        if isPushing == true, hasViewController {
            isPushing = nil
            animation = nil
        } else if !hasViewController, isPushing != true {
            // Break the retain cycle
            adapter?.coordinator = nil

            onPop(Transaction())
            didPop()
            isPushing = nil
        }

        #if !targetEnvironment(macCatalyst)
        if #available(iOS 16.0, *),
           let sheetPresentationController = viewController._activePresentationController as? SheetPresentationController,
           sheetPresentationController.detents.contains(where: { $0.isDynamic })
        {
            if animated {
                sheetPresentationController.animateChanges {
                    sheetPresentationController.invalidateDetents()
                }
            } else {
                sheetPresentationController.invalidateDetents()
            }
        }
        #endif
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        let isShowingPreviousViewController = navigationController.viewControllers.last == viewController
        if isPushing == true || isShowingPreviousViewController {
            let isNavigationBarHidden = isPushing == true ? adapter?.transition.options.isNavigationBarHidden : wasNavigationBarHidden
            if let isNavigationBarHidden, navigationController.isNavigationBarHidden != isNavigationBarHidden {
                wasNavigationBarHidden = navigationController.isNavigationBarHidden
                navigationController.setNavigationBarHidden(
                    isNavigationBarHidden,
                    animated: animated
                )
            }
        }
        if isPushing == true, adapter?.viewController == viewController, !isPresented.wrappedValue {
            let animation = animation ?? (animated ? .default : nil)
            withAnimation(animation) {
                isPresented.wrappedValue = true
            }
        }
        if isPushing != true {
            if navigationController.interactivePopGestureRecognizer?.isInteracting == true {
                sourceView?.alpha = 1
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), navigationController.interactiveContentPopGestureRecognizer?.isInteracting == true {
                sourceView?.alpha = 1
            }
            #endif
            navigationController.setNeedsStatusBarAppearanceUpdate(
                animated: animated,
                transitionAlongsideCoordinator: false
            )
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        guard let transition = adapter?.transition else { return nil }
        switch transition.value {
        case .representable(let representable):
            if isPushing == true {
                return representable.navigationController(
                    navigationController,
                    interactionControllerForPush: animationController,
                    context: makeContext(options: transition.options)
                )

            } else {
                return representable.navigationController(
                    navigationController,
                    interactionControllerForPop: animationController,
                    context: makeContext(options: transition.options)
                )
            }

        default:
            return nil
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let transition = adapter?.transition else { return nil }
        switch transition.value {
        case .representable(let representable):
            switch operation {
            case .push:
                guard adapter?.viewController == toVC else { return nil }
                return representable.navigationController(
                    navigationController,
                    pushing: toVC,
                    from: fromVC,
                    context: makeContext(options: transition.options)
                )

            case .pop:
                guard adapter?.viewController == fromVC else { return nil }
                let animationController = representable.navigationController(
                    navigationController,
                    popping: fromVC,
                    to: toVC,
                    context: makeContext(options: transition.options)
                )
                if !transition.options.isInteractive, let interactiveTransition = animationController as? UIPercentDrivenInteractiveTransition {
                    interactiveTransition.wantsInteractiveStart = false
                }
                return animationController

            default:
                return nil
            }

        default:
            return nil
        }
    }

    // MARK: - Zoom Transition

    @objc
    func zoomPanGestureDidChange(_ panGesture: UIPanGestureRecognizer) {
        zoomGestureDidChange(panGesture: panGesture, isVertical: true)
    }

    @objc
    func zoomEdgePanGestureDidChange(_ edgePanGesture: UIScreenEdgePanGestureRecognizer) {
        zoomGestureDidChange(panGesture: edgePanGesture, isVertical: false)
    }
    @objc
    func zoomPinchGestureDidChange(_ gesture: UIGestureRecognizer) {
        guard
            gesture.responds(to: NSSelectorFromString("scale")),
            let scale = gesture.value(forKey: "scale") as? CGFloat
        else {
            return
        }
        gestureDidChange(
            gesture: gesture,
            hasReachedTriggerThreshold: scale <= 0.4,
            hasReachedCancelThreshold: scale > 0.4
        )
    }

    private func zoomGestureDidChange(
        panGesture: UIPanGestureRecognizer,
        isVertical: Bool
    ) {
        guard let view = panGesture.view else { return }
        let velocity = isVertical ? panGesture.velocity(in: view).y : panGesture.velocity(in: view).x
        let translation = isVertical ? panGesture.translation(in: view).y : panGesture.translation(in: view).x
        let threshold = isVertical ? UIGestureRecognizer.zoomGestureActivationThreshold.height : UIGestureRecognizer.zoomGestureActivationThreshold.width
        gestureDidChange(
            gesture: panGesture,
            hasReachedTriggerThreshold: translation >= threshold &&  velocity >= 0,
            hasReachedCancelThreshold: translation < threshold && velocity < 0
        )
    }

    private func gestureDidChange(
        gesture: UIGestureRecognizer,
        hasReachedTriggerThreshold: Bool,
        hasReachedCancelThreshold: Bool
    ) {
        switch gesture.state {
        case .ended, .cancelled:
            isZoomTransitionDismissReady = false
            feedbackGenerator = nil
        default:
            guard
                let hapticsStyle = adapter?.transition.options.hapticsStyle,
                let view = gesture.view
            else {
                return
            }
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
            } else if !isZoomTransitionDismissReady, hasReachedTriggerThreshold {
                isZoomTransitionDismissReady = true
                impactOccurred(intensity: 1, location: gesture.location(in: view))
            } else if isZoomTransitionDismissReady, hasReachedCancelThreshold {
                impactOccurred(intensity: 0.5, location: gesture.location(in: view))
                isZoomTransitionDismissReady = false
            }
        }
    }
}

/// A public protocol you can cast the `UINavigationController` delegate to
@MainActor
public protocol DestinationLinkDelegate {

    func navigationControllerCanBeginInteractivePop() -> Bool
}

@objc
protocol DestinationLinkCoordinatorDelegate: UINavigationControllerDelegate  {

    func navigationControllerShouldBeginInteractivePop(
        _ navigationController: UINavigationController,
        gesture: UIGestureRecognizer
    ) -> Bool

    func navigationControllerHapticsForInteractivePop(
        _ navigationController: UINavigationController
    ) -> Int

    func navigationController(
        _ navigationController: UINavigationController,
        willPop viewControllers: [UIViewController],
        animated: Bool
    )

    func navigationController(
        _ navigationController: UINavigationController,
        didPop viewController: UIViewController,
        isCancel: Bool,
        animated: Bool
    )
}

@available(iOS 14.0, *)
final class DestinationLinkDelegateProxy: NSObject,
    UINavigationControllerDelegate,
    UIGestureRecognizerDelegate,
    UINavigationControllerPresentationDelegate,
    DestinationLinkDelegate
{

    private weak var navigationController: UINavigationController?
    private nonisolated(unsafe) weak var delegate: UINavigationControllerDelegate?
    private var delegates = [ObjectIdentifier: ObjCWeakBox<DestinationLinkCoordinatorDelegate>]()

    private var transitioningId: ObjectIdentifier?
    private weak var transition: UIPercentDrivenInteractiveTransition?
    private weak var cancelledTransition: UIPercentDrivenInteractiveTransition?
    private weak var finishedTransition: UIPercentDrivenInteractiveTransition?

    private weak var popGestureDelegate: UIGestureRecognizerDelegate?
    private weak var panGestureDelegate: UIGestureRecognizerDelegate?
    private var interactivePopEdgeGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    private var interactivePopPanGestureRecognizer: UIPanGestureRecognizer!
    private var simultaneousPanGestures: [UIPanGestureRecognizer] = []

    private var isInterruptedInteractiveTransition = false

    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var isPopReady = false
    private let threshold: CGFloat = 0.55

    init(for navigationController: UINavigationController) {
        super.init()
        self.delegate = navigationController.delegate
        popGestureDelegate = navigationController.interactivePopGestureRecognizer?.delegate
        navigationController.interactivePopGestureRecognizer?.delegate = self
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            panGestureDelegate = navigationController.interactiveContentPopGestureRecognizer?.delegate
            navigationController.interactiveContentPopGestureRecognizer?.delegate = self
        }
        #endif
        self.navigationController = navigationController
        navigationController.delegate = self
        interactivePopEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(panGestureDidChange(_:))
        )
        interactivePopEdgeGestureRecognizer.delegate = self
        if let builtinGesture = navigationController.interactivePopGestureRecognizer as? UIScreenEdgePanGestureRecognizer {
            interactivePopEdgeGestureRecognizer.edges = builtinGesture.edges
            interactivePopEdgeGestureRecognizer.delaysTouchesBegan = builtinGesture.delaysTouchesBegan
            interactivePopEdgeGestureRecognizer.delaysTouchesEnded = builtinGesture.delaysTouchesEnded
            builtinGesture.addTarget(self, action: #selector(interactivePopGestureDidChange(_:)))
        } else {
            interactivePopEdgeGestureRecognizer.edges = navigationController.view.effectiveUserInterfaceLayoutDirection == .leftToRight ? [.left] : [.right]
            interactivePopEdgeGestureRecognizer.delaysTouchesBegan = true
        }
        navigationController.view.addGestureRecognizer(interactivePopEdgeGestureRecognizer)

        interactivePopPanGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureDidChange(_:))
        )
        interactivePopPanGestureRecognizer.delegate = self
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *), let builtinGesture = navigationController.interactiveContentPopGestureRecognizer {
            interactivePopPanGestureRecognizer.delaysTouchesBegan = builtinGesture.delaysTouchesBegan
            interactivePopPanGestureRecognizer.delaysTouchesEnded = builtinGesture.delaysTouchesEnded
            builtinGesture.addTarget(self, action: #selector(interactivePopGestureDidChange(_:)))
        }
        #endif
        navigationController.view.addGestureRecognizer(interactivePopPanGestureRecognizer)

        navigationController.pushDelegate = self
    }

    func add(
        delegate: DestinationLinkCoordinatorDelegate,
        for viewController: UIViewController
    ) {
        delegates[ObjectIdentifier(viewController)] = ObjCWeakBox(value: delegate)
    }

    func remove(
        delegate: DestinationLinkCoordinatorDelegate,
        for viewController: UIViewController
    ) {
        let id = ObjectIdentifier(viewController)
        if transitioningId == id {
            if isInterruptedInteractiveTransition {
                cancelledTransition = transition
            } else {
                finishedTransition = transition
            }
            transition = nil
        }
        delegates[id] = nil
    }

    func transition(for viewController: UIViewController) -> UIPercentDrivenInteractiveTransition? {
        guard transitioningId == ObjectIdentifier(viewController) else { return nil }
        return transition ?? finishedTransition ?? cancelledTransition
    }

    @objc
    private func interactivePopGestureDidChange(
        _ gestureRecognizer: UIPanGestureRecognizer
    ) {
        guard let view = gestureRecognizer.view else { return }
        let translation = gestureRecognizer.translation(in: view)
        let percentage = min(max(0, translation.x / view.bounds.width), 1)
        triggerHapticsIfNeeded(panGesture: gestureRecognizer, isActivationThresholdSatisfied: percentage >= threshold)
    }

    @objc
    private func panGestureDidChange(
        _ gestureRecognizer: UIPanGestureRecognizer
    ) {
        guard
            let view = gestureRecognizer.view,
            let navigationController
        else {
            panGestureDidEnd(gestureRecognizer, didCancel: true)
            return
        }

        let velocity = gestureRecognizer.velocity(in: view)
        if gestureRecognizer.state == .began {
            if isInterruptedInteractiveTransition {
                if let topViewController = navigationController.topViewController,
                   let frame = topViewController.view.layer.presentation()?.frame
                {
                    gestureRecognizer.setTranslation(frame.origin, in: nil)
                }
            } else {
                if !simultaneousPanGestures.isEmpty {
                    var canBegin = abs(velocity.x) > abs(velocity.y)
                    if canBegin {
                        if navigationController.view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
                            if velocity.x > 0 {
                                canBegin = false
                            }
                        } else {
                            if velocity.x < 0 {
                                canBegin = false
                            }
                        }
                    }
                    if !canBegin {
                        panGestureDidEnd(gestureRecognizer, didCancel: true)
                        return
                    } else {
                        for gesture in simultaneousPanGestures {
                            gesture.isEnabled = false
                            gesture.isEnabled = true
                        }
                    }
                }
                if let transitionCoordinator = navigationController.transitionCoordinator,
                    transitionCoordinator.presentationStyle == .none
                {
                    if !transitionCoordinator.isCancelled {
                        if let transition = (finishedTransition ?? cancelledTransition) as? ViewControllerTransition {
                            transition.complete(transition === finishedTransition)
                            navigationController.popViewController(animated: true)
                        } else if let transition = finishedTransition ?? cancelledTransition {
                            transition.pause()
                            transition.endInteractiveTransition()
                            if transition === finishedTransition {
                                transition.finish()
                            } else {
                                transition.cancel()
                            }
                            transitionCoordinator.animate(alongsideTransition: nil) { ctx in
                                if gestureRecognizer.isInteracting {
                                    navigationController.popViewController(animated: true)
                                }
                            }
                        } else if navigationController.zoomInteractionController != nil {
                            navigationController.popViewController(animated: true)
                        }
                    }
                } else {
                    navigationController.popViewController(animated: true)
                }
            }
        }

        let translation = gestureRecognizer.translation(in: view)
        var percentage: CGFloat
        if isInterruptedInteractiveTransition {
            percentage = 1 - min(max(0, translation.x / view.bounds.width), 1)
        } else {
            percentage = min(max(0, translation.x / view.bounds.width), 1)
        }

        switch gestureRecognizer.state {
        case .began, .changed:
            guard let transition else { return }
            if isInterruptedInteractiveTransition, abs(velocity.y) > abs(velocity.x) {
                return
            }
            transition.pause()
            transition.update(percentage)
            let isActivationThresholdSatisfied = isInterruptedInteractiveTransition
                ? percentage <= threshold
                : percentage >= threshold
            triggerHapticsIfNeeded(panGesture: gestureRecognizer, isActivationThresholdSatisfied: isActivationThresholdSatisfied)

        case .cancelled, .ended, .failed:
            guard let transition else {
                panGestureDidEnd(gestureRecognizer, didCancel: true)
                return
            }
            // Dismiss if:
            // - Drag over 50% and not moving up
            // - Large enough down vector
            var targetVelocity = velocity.x
            if isInterruptedInteractiveTransition {
                targetVelocity = -targetVelocity
            }
            if navigationController.view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
                targetVelocity = -targetVelocity
            }
            var shouldFinish = false
            if isInterruptedInteractiveTransition, abs(velocity.y) > abs(velocity.x) {
                shouldFinish = true
            } else if gestureRecognizer.state == .ended {
                let targetVelocityThreshold: CGFloat = isInterruptedInteractiveTransition ? 100 : 0
                if interactivePopEdgeGestureRecognizer.edges.contains(.left), !shouldFinish {
                    shouldFinish = (percentage >= threshold && targetVelocity >= -targetVelocityThreshold) || (percentage > 0 && targetVelocity >= 800)
                }
                if interactivePopEdgeGestureRecognizer.edges.contains(.right), !shouldFinish {
                    shouldFinish = (percentage >= threshold && targetVelocity <= targetVelocityThreshold) || (percentage > 0 && targetVelocity <= -800)
                }
            }
            let delta = max(threshold, (isInterruptedInteractiveTransition ? 1 - percentage : percentage) * view.frame.width)
            if !shouldFinish {
                targetVelocity = -targetVelocity
            }
            var dx = delta >= 1 ? targetVelocity / delta : 0
            if dx < 0 {
                dx = max(dx, -30)
            } else {
                dx = min(dx, 30)
            }
            let initialVelocity = CGVector(
                dx: dx,
                dy: velocity.y / view.frame.height
            )
            // `completionSpeed` handling seems to differ across iOS version
            if #available(iOS 18.0, *) {
                var completionSpeed = shouldFinish ? 1 - percentage : percentage
                if isInterruptedInteractiveTransition, shouldFinish {
                    completionSpeed = 1 - completionSpeed
                }
                if abs(velocity.x) >= 4000 {
                    completionSpeed = 1
                }
                transition.completionSpeed = completionSpeed
            }
            transition.timingCurve = UISpringTimingParameters(
                dampingRatio: 0.84,
                initialVelocity: initialVelocity
            )
            if shouldFinish {
                transition.finish()
                finishedTransition = transition
                self.transition = nil
            } else {
                if let transitionCoordinator = navigationController.transitionCoordinator {
                    // Fixes bugs with a cancelled interactive push transition
                    transitionCoordinator.animate(alongsideTransition: nil) { ctx in
                        if !navigationController.isNavigationBarHidden, !navigationController.navigationBar.isHidden {
                            navigationController.setNavigationBarHidden(true, animated: false)
                            navigationController.setNavigationBarHidden(false, animated: false)
                        }
                        if #unavailable(iOS 18.0) {
                            navigationController.topViewController?.fixSwiftUIHitTesting()
                        }
                    }
                }
                transition.cancel()

                if isInterruptedInteractiveTransition,
                   let fromVC = navigationController.topViewController,
                   let delegate = delegates[ObjectIdentifier(fromVC)]?.value
                {
                    delegate.navigationController(
                        navigationController,
                        didPop: fromVC,
                        isCancel: true,
                        animated: true
                    )
                }
            }
            panGestureDidEnd(gestureRecognizer, didCancel: gestureRecognizer.state != .ended)

        default:
            panGestureDidEnd(gestureRecognizer, didCancel: true)
        }
    }

    private func panGestureDidEnd(
        _ gestureRecognizer: UIPanGestureRecognizer,
        didCancel: Bool
    ) {
        if didCancel {
            transition?.cancel()
            transition = nil
            finishedTransition = nil
            transitioningId = nil
            gestureRecognizer.isEnabled = false
            gestureRecognizer.isEnabled = true
        }
        isInterruptedInteractiveTransition = false
        isPopReady = false
        feedbackGenerator = nil
        simultaneousPanGestures = []
        navigationController?.interactiveTransitionWillEnd()
    }

    private func triggerHapticsIfNeeded(
        panGesture: UIPanGestureRecognizer,
        isActivationThresholdSatisfied: Bool
    ) {
        switch panGesture.state {
        case .ended, .cancelled:
            isPopReady = false
            feedbackGenerator = nil
        default:
            guard
                let navigationController,
                let fromVC = navigationController.transitionCoordinator?.viewController(forKey: isInterruptedInteractiveTransition ? .to : .from),
                let delegate = delegates[ObjectIdentifier(fromVC)]?.value,
                let view = panGesture.view
            else {
                return
            }
            let hapticsStyleValue = delegate.navigationControllerHapticsForInteractivePop(navigationController)
            guard
                hapticsStyleValue >= 0,
                let hapticsStyle = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: hapticsStyleValue)
            else {
                return
            }
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
            } else if !isPopReady, isActivationThresholdSatisfied {
                isPopReady = true
                impactOccurred(intensity: 1, location: panGesture.location(in: view))
            } else if isPopReady, !isActivationThresholdSatisfied
            {
                impactOccurred(intensity: 0.5, location: panGesture.location(in: view))
                isPopReady = false
            }
        }
    }

    // MARK: - DestinationLinkDelegate

    func navigationControllerCanBeginInteractivePop() -> Bool {
        guard let topViewController = navigationController?.topViewController else { return false }
        let delegate = delegates[ObjectIdentifier(topViewController)]?.value
        guard let delegate = delegate as? DestinationLinkDelegate else { return true }
        return delegate.navigationControllerCanBeginInteractivePop()
    }

    // MARK: - UINavigationControllerPresentationDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        didPop viewController: UIViewController,
        animated: Bool
    ) {
        let delegate = delegates[ObjectIdentifier(viewController)]?.value
        delegate?.navigationController(
            navigationController,
            didPop: viewController,
            isCancel: false,
            animated: animated
        )
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willPop viewControllers: [UIViewController],
        animated: Bool
    ) {
        for viewController in viewControllers {
            let delegate = delegates[ObjectIdentifier(viewController)]?.value
            delegate?.navigationController(
                navigationController,
                willPop: viewControllers,
                animated: animated
            )
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard
            let navigationController = navigationController,
            navigationController.viewControllers.count > 1 || navigationController.transitionCoordinator != nil,
            var fromVC = navigationController.topViewController
        else {
            return false
        }

        var isInturruptingCancel = false
        var isTransitionCancelled = false
        if let transitionCoordinator = navigationController.transitionCoordinator,
            transitionCoordinator.presentationStyle == .none
        {
            if transitionCoordinator.viewController(forKey: .to) != fromVC {
                return false
            } else if let from = transitionCoordinator.viewController(forKey: .from) {
                if transitionCoordinator.isCancelled {
                    fromVC = from
                    isInturruptingCancel = true
                } else if delegates[ObjectIdentifier(fromVC)]?.value == nil,
                    transitioningId == ObjectIdentifier(fromVC)
                {
                    // `isCancelled` reports false but it was cancelled
                    fromVC = from
                    isTransitionCancelled = true
                }
            }
        }

        let shouldBegin: Bool? = {
            guard let delegate = delegates[ObjectIdentifier(fromVC)]?.value else {
                return nil
            }
            let shouldBegin = delegate.navigationControllerShouldBeginInteractivePop(
                navigationController,
                gesture: gestureRecognizer
            )
            return shouldBegin
        }()

        if gestureRecognizer == interactivePopEdgeGestureRecognizer || gestureRecognizer == interactivePopPanGestureRecognizer {
            if gestureRecognizer == interactivePopEdgeGestureRecognizer, transition != nil, interactivePopPanGestureRecognizer.state == .began {
                return false
            }
            guard shouldBegin == true else { return false }
            if transition != nil, !isInturruptingCancel, !isTransitionCancelled {
                isInterruptedInteractiveTransition = true
                return true
            }
            if transition != nil, isInturruptingCancel {
                return true
            }
            isInterruptedInteractiveTransition = false
            return true
        } else {
            if shouldBegin == false || transition != nil {
                return false
            }
            if gestureRecognizer == navigationController.interactivePopGestureRecognizer {
                let canBegin = popGestureDelegate?.gestureRecognizerShouldBegin?(
                    gestureRecognizer
                )
                return canBegin ?? true
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController.interactiveContentPopGestureRecognizer {
                let canBegin = panGestureDelegate?.gestureRecognizerShouldBegin?(
                    gestureRecognizer
                )
                return canBegin ?? true
            }
            #endif
            return true
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer == interactivePopEdgeGestureRecognizer {
            return true
        } else if gestureRecognizer == interactivePopPanGestureRecognizer {
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), otherGestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                return false
            }
            #endif
            if otherGestureRecognizer.isZoomDismissGesture {
                return true
            }
            if let interactivePresentationPanGestureRecognizer = otherGestureRecognizer as? InteractivePresentationPanGestureRecognizer, interactivePresentationPanGestureRecognizer.edges.contains(.leading) {
                return false
            }
            if !isInterruptedInteractiveTransition,
                let panGesture = otherGestureRecognizer as? UIPanGestureRecognizer,
                !panGesture.isSimultaneousWithTransition,
                !panGesture.isZoomDismissGesture
            {
                simultaneousPanGestures.append(panGesture)
                return true
            }
            return false
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldRecognizeSimultaneouslyWith = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRecognizeSimultaneouslyWith: otherGestureRecognizer
                )
                return shouldRecognizeSimultaneouslyWith ?? false
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldRecognizeSimultaneouslyWith = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRecognizeSimultaneouslyWith: otherGestureRecognizer
                )
                return shouldRecognizeSimultaneouslyWith ?? false
            }
            #endif
            return false
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer == interactivePopEdgeGestureRecognizer {
            return false
        } else if gestureRecognizer == interactivePopPanGestureRecognizer {
            if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer || otherGestureRecognizer is UILongPressGestureRecognizer {
                return true
            }
            if otherGestureRecognizer.isSwiftUIGestureRecognizer, otherGestureRecognizer.state != .began {
                return true
            }
            return false
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldRequireFailureOf = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRequireFailureOf: otherGestureRecognizer
                )
                return shouldRequireFailureOf ?? false
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldRequireFailureOf = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRequireFailureOf: otherGestureRecognizer
                )
                return shouldRequireFailureOf ?? false
            }
            #endif
            return false
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer == interactivePopEdgeGestureRecognizer {
            if otherGestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                return true
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), otherGestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                return true
            }
            #endif
            if otherGestureRecognizer.isZoomDismissGesture || otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
            return false
        } else if gestureRecognizer == interactivePopPanGestureRecognizer {
            return false
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldBeRequiredToFailBy = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldBeRequiredToFailBy: otherGestureRecognizer
                )
                return shouldBeRequiredToFailBy ?? false
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldBeRequiredToFailBy = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldBeRequiredToFailBy: otherGestureRecognizer
                )
                return shouldBeRequiredToFailBy ?? false
            }
            #endif
            return false
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        if gestureRecognizer == interactivePopEdgeGestureRecognizer || gestureRecognizer == interactivePopPanGestureRecognizer {
            return true
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldReceive = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: touch
                )
                return shouldReceive ?? true
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldReceive = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: touch
                )
                return shouldReceive ?? true
            }
            #endif
            return true
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive press: UIPress
    ) -> Bool {
        if gestureRecognizer == interactivePopEdgeGestureRecognizer || gestureRecognizer == interactivePopPanGestureRecognizer {
            return true
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldReceive = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: press
                )
                return shouldReceive ?? true
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldReceive = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: press
                )
                return shouldReceive ?? true
            }
            #endif
            return true
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive event: UIEvent
    ) -> Bool {
        if gestureRecognizer == interactivePopEdgeGestureRecognizer || gestureRecognizer == interactivePopPanGestureRecognizer {
            return true
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldReceive = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: event
                )
                return shouldReceive ?? true
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldReceive = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: event
                )
                return shouldReceive ?? true
            }
            #endif
            return true
        }
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        if let delegate, delegate.responds(to: aSelector) {
            return true
        }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if responds(to: aSelector) {
            return nil
        }
        if let delegate, delegate.responds(to: aSelector) {
            return delegate
        }
        return nil
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        delegate?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
        for delegate in delegates.compactMap(\.value.value) {
            delegate.navigationController?(
                navigationController,
                willShow: viewController,
                animated: animated
            )
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {

        transitioningId = nil
        delegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )
        for delegate in delegates.compactMap(\.value.value) {
            delegate.navigationController?(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {

        if let id = transitioningId {
            let delegate = delegates[id]?.value
            let interactionController = delegate?.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            )
            return interactionController
        }
        return nil
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        let id = ObjectIdentifier(operation == .push ? toVC : fromVC)
        transitioningId = id
        let delegate = delegates[id]?.value
        let animationController = delegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
        if let interactiveTransition = animationController as? UIPercentDrivenInteractiveTransition {
            let isInteracting = interactivePopEdgeGestureRecognizer.isInteracting || interactivePopPanGestureRecognizer.isInteracting
            interactiveTransition.wantsInteractiveStart = interactiveTransition.wantsInteractiveStart && isInteracting
            transition = interactiveTransition
        }
        return animationController
    }
}

@available(iOS 14.0, *)
extension UINavigationController {

    private static var navigationDelegateKey: Bool = false

    var delegates: DestinationLinkDelegateProxy {
        guard let obj = objc_getAssociatedObject(self, &Self.navigationDelegateKey) as? ObjCBox<DestinationLinkDelegateProxy> else {
            let proxy = DestinationLinkDelegateProxy(for: self)
            let box = ObjCBox<DestinationLinkDelegateProxy>(value: proxy)
            objc_setAssociatedObject(self, &Self.navigationDelegateKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return proxy
        }
        return obj.value
    }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
class DestinationLinkDestinationViewControllerAdapter<
    Destination: View,
    Representable: UIViewRepresentable
>: ViewControllerAdapter<Destination, Representable> {

    typealias DestinationController = DestinationHostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    var transition: DestinationLinkTransition
    weak var sourceView: UIView?
    var environment: EnvironmentValues
    var isPresented: Binding<Bool>
    var onPop: (Int, Transaction) -> Void

    weak var navigationController: UINavigationController?

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: NSObject?

    init(
        destination: Destination,
        sourceView: UIView,
        transition: DestinationLinkTransition,
        context: Representable.Context,
        navigationController: UINavigationController?,
        isPresented: Binding<Bool>,
        onPop: @escaping (Int, Transaction) -> Void
    ) {
        self.transition = transition
        self.sourceView = sourceView
        self.environment = context.environment
        self.isPresented = isPresented
        self.onPop = onPop
        self.navigationController = navigationController
        super.init(content: destination, context: context)
    }

    func update(
        destination: Destination,
        context: Representable.Context,
        isPresented: Binding<Bool>
    ) {
        self.isPresented = isPresented
        self.environment = context.environment
        super.updateViewController(content: destination, context: context)
    }

    override func makeHostingController(
        content: Destination,
        context: Representable.Context
    ) -> UIViewController {
        let modifier = DestinationBridgeAdapter(
            destinationCoordinator: DestinationCoordinator(
                isPresented: isPresented.wrappedValue,
                sourceView: sourceView,
                seed: .constant(self),
                dismissBlock: { [weak self] in self?.pop($0, $1) }
            )
        )
        let hostingController = DestinationController(content: content.modifier(modifier))
        hostingController.sourceViewController = sourceView?.viewController as? AnyHostingController
        configure(
            hostingController,
            context: DestinationLinkTransitionRepresentableContext(
                sourceView: sourceView,
                options: transition.options,
                environment: context.environment,
                transaction: context.transaction
            )
        )
        return hostingController
    }

    override func updateHostingController(
        content: Destination,
        context: Representable.Context
    ) {
        let modifier = DestinationBridgeAdapter(
            destinationCoordinator: DestinationCoordinator(
                isPresented: isPresented.wrappedValue,
                sourceView: sourceView,
                seed: .constant(self),
                dismissBlock: { [weak self] in self?.pop($0, $1) }
            )
        )
        let hostingController = viewController as! DestinationController
        hostingController.update(content: content.modifier(modifier), transaction: context.transaction)
        configure(
            hostingController,
            context: DestinationLinkTransitionRepresentableContext(
                sourceView: sourceView,
                options: transition.options,
                environment: context.environment,
                transaction: context.transaction
            )
        )
    }

    override func transformViewControllerEnvironment(
        _ environment: inout EnvironmentValues
    ) {
        let destinationCoordinator = DestinationCoordinator(
            isPresented: isPresented.wrappedValue,
            sourceView: sourceView,
            seed: .constant(self),
            dismissBlock: { [weak self] in self?.pop($0, $1) }
        )
        environment.destinationCoordinator = destinationCoordinator
    }

    func pop(_ count: Int, _ transaction: Transaction) {
        onPop(count, transaction)
    }

    func configure<Content: View>(
        _ viewController: DestinationHostingController<Content>,
        context: DestinationLinkTransitionRepresentableContext
    ) {

        viewController.hidesBottomBarWhenPushed = transition.options.hidesBottomBarWhenPushed
        if let preferredPresentationBackgroundUIColor = transition.options.preferredPresentationBackgroundUIColor {
            viewController.view.backgroundColor = preferredPresentationBackgroundUIColor
        }

        if case .representable(let representable) = transition.value {
            representable.updateHostingController(
                presenting: viewController,
                context: context
            )
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct DestinationLinkAdapter_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            VStack {
                DestinationLinkAdapter(transition: .default, isPresented: .constant(false)) {

                } content: {
                    Color.yellow
                        .aspectRatio(1, contentMode: .fit)
                }
                .border(Color.red)

                DestinationLinkAdapter(transition: .default, isPresented: .constant(false)) {

                } content: {
                    Color.yellow
                        .frame(width: 44, height: 44)
                }
                .border(Color.red)

                DestinationLinkAdapter(transition: .default, isPresented: .constant(false)) {

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
