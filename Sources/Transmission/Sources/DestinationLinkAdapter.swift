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
        transition: DestinationLinkTransition,
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

    public init<ViewController: UIViewController>(
        transition: DestinationLinkTransition,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        isPresented: Binding<Bool>,
        destination: @escaping () -> ViewController,
        @ViewBuilder content: () -> Content
    ) where Destination == ViewControllerRepresentableAdapter<ViewController> {
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.isPresented = isPresented
        self.content = content()
        self.destination = ViewControllerRepresentableAdapter(destination)
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

        context.coordinator.presentingViewController = presentingViewController

        if let presentingViewController = presentingViewController, isPresented.wrappedValue {

            context.coordinator.isPresented = isPresented

            let isAnimated = context.transaction.isAnimated
                || (presentingViewController.transitionCoordinator?.isAnimated ?? false)
                || (try? swift_getFieldValue("transaction", Transaction?.self, presentingViewController))?.isAnimated == true
            let animation = context.transaction.animation
                ?? (isAnimated ? .default : nil)
            context.coordinator.animation = animation

            let sourceView = uiView.hostingView ?? uiView
            if let adapter = context.coordinator.adapter {
                adapter.transition = transition.value
                adapter.update(
                    destination: destination,
                    context: context,
                    isPresented: isPresented
                )
            } else if let navigationController = presentingViewController.navigationController {
                let adapter = DestinationLinkDestinationViewControllerAdapter(
                    destination: destination,
                    sourceView: sourceView,
                    transition: transition.value,
                    context: context,
                    navigationController: navigationController,
                    isPresented: isPresented,
                    onPop: { [weak coordinator = context.coordinator] in
                        coordinator?.onPop($0, transaction: $1)
                    }
                )
                context.coordinator.adapter = adapter
                switch adapter.transition {
                case .`default`:
                    break

                case .zoom(let options):
                    if #available(iOS 18.0, *) {
                        let zoomOptions = UIViewController.Transition.ZoomOptions()
                        zoomOptions.dimmingColor = options.dimmingColor?.toUIColor()
                        zoomOptions.dimmingVisualEffect = options.dimmingVisualEffect.map { UIBlurEffect(style: $0) }
                        zoomOptions.interactiveDismissShouldBegin = { [weak adapter] context in
                            context.willBegin && (adapter?.transition.options.isInteractive ?? true)
                        }
                        let coordinator = context.coordinator
                        adapter.viewController.preferredTransition = .zoom(options: zoomOptions) { [weak coordinator] _ in
                            guard let sourceView = coordinator?.sourceView, sourceView.window != nil else { return nil }
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

                case .representable(_, let transition):
                    assert(!swift_getIsClassType(transition), "DestinationLinkCustomTransition must be value types (either a struct or an enum); it was a class")
                    context.coordinator.sourceView = sourceView
                }

                navigationController.delegates.add(delegate: context.coordinator, for: adapter.viewController)
                context.coordinator.isPushing = true
                if let firstResponder = navigationController.topViewController?.firstResponder {
                    withCATransaction {
                        firstResponder.resignFirstResponder()
                        navigationController.pushViewController(adapter.viewController, animated: isAnimated) {
                            context.coordinator.animation = nil
                            context.coordinator.didPresentAnimated = isAnimated
                        }
                    }
                } else {
                    navigationController.pushViewController(adapter.viewController, animated: isAnimated) {
                        context.coordinator.animation = nil
                        context.coordinator.didPresentAnimated = isAnimated
                    }
                }
            }
        } else if context.coordinator.adapter != nil, !isPresented.wrappedValue {
            context.coordinator.isPresented = isPresented
            context.coordinator.onPop(1, transaction: context.transaction)
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
                             DestinationLinkDelegate
    {
        var isPresented: Binding<Bool>
        var adapter: DestinationLinkDestinationViewControllerAdapter<Destination, SourceView>?
        var animation: Animation?
        var didPresentAnimated = false
        var isPushing: Bool?
        weak var sourceView: UIView?

        var isZoomTransitionDismissReady = false
        var feedbackGenerator: UIImpactFeedbackGenerator?

        var wasNavigationBarHidden: Bool?

        weak var presentingViewController: UIViewController?

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
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
            guard let viewController = adapter?.viewController else { return }
            animation = transaction.animation
            didPresentAnimated = false
            isPushing = false
            if let presented = viewController.presentedViewController {
                presented.dismiss(animated: transaction.isAnimated) {
                    viewController._popViewController(
                        count: count,
                        animated: transaction.isAnimated
                    ) { [weak self] success in
                        guard success, self?.adapter?.viewController == viewController else { return }
                        self?.onPop(transaction)
                    }
                }
            } else {
                viewController._popViewController(
                    count: count,
                    animated: transaction.isAnimated
                ) { [weak self] success in
                    guard success, self?.adapter?.viewController == viewController else { return }
                    self?.onPop(transaction)
                }
            }
        }

        func willPop(_ transaction: Transaction) {
            if isPresented.wrappedValue == true {
                withTransaction(transaction) {
                    self.isPresented.wrappedValue = false
                }
            }
        }

        func onPop(_ transaction: Transaction) {
            willPop(transaction)
            didPop()
        }

        func didPop() {
            if let viewController = adapter?.viewController {
                adapter?.navigationController?.delegates
                    .remove(
                        delegate: self,
                        for: viewController
                    )
            }
            adapter = nil
        }

        func navigationControllerShouldBeginInteractivePop(
            _ navigationController: UINavigationController,
            gesture: UIGestureRecognizer,
            edge: Bool
        ) -> Bool {
            guard let transition = adapter?.transition else { return true }
            switch transition {
            case .zoom:
                return false
            default:
                guard transition.options.isInteractive else { return false }
                if !edge, !transition.options.prefersPanGesturePop {
                    return false
                }
                let isBuiltInGesture = {
                    if gesture == navigationController.interactivePopGestureRecognizer {
                        return true
                    }
                    if #available(iOS 26.0, *), gesture == navigationController.interactiveContentPopGestureRecognizer {
                        return true
                    }
                    return false
                }()
                if case .default = transition {
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
            didPop viewController: UIViewController,
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
            if let transitionCoordinator = navigationController.transitionCoordinator ?? viewController.transitionCoordinator {
                if transitionCoordinator.viewController(forKey: .from) == viewController {
                    if transitionCoordinator.isInteractive {
                        transitionCoordinator.notifyWhenInteractionChanges { [weak self] ctx in
                            if !ctx.isCancelled {
                                self?.onPop(transaction)
                            }
                        }
                    } else {
                        transitionCoordinator.animate { _ in
                            self.onPop(transaction)
                        }
                    }
                } else {
                    transitionCoordinator.animate(alongsideTransition: nil) { ctx in
                        if !ctx.isCancelled {
                            self.onPop(transaction)
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

                if isPushing == nil {
                    if isPresented.wrappedValue {
                        onPop(Transaction())
                    } else {
                        didPop()
                    }
                }
                isPushing = nil
            }

            #if !targetEnvironment(macCatalyst)
            if #available(iOS 16.0, *),
               let sheetPresentationController = presentingViewController?._activePresentationController as? SheetPresentationController,
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
            let isNavigationBarHidden = isPushing == true ? adapter?.transition.options.isNavigationBarHidden : wasNavigationBarHidden
            if let isNavigationBarHidden, navigationController.isNavigationBarHidden != isNavigationBarHidden {
                wasNavigationBarHidden = navigationController.isNavigationBarHidden
                navigationController.setNavigationBarHidden(
                    isNavigationBarHidden,
                    animated: animated
                )
            }
            if isPushing != true {
                if navigationController.interactivePopGestureRecognizer?.isInteracting == true {
                    sourceView?.alpha = 1
                }
                if #available(iOS 26.0, *), navigationController.interactiveContentPopGestureRecognizer?.isInteracting == true {
                    sourceView?.alpha = 1
                }
            }
            if isPushing != true {
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
            switch adapter?.transition {

            case .representable(let options, let transition):
                if isPushing == true {
                    return transition.navigationController(
                        navigationController,
                        interactionControllerForPush: animationController,
                        context: makeContext(options: options)
                    )

                } else {
                    return transition.navigationController(
                        navigationController,
                        interactionControllerForPop: animationController,
                        context: makeContext(options: options)
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
            switch adapter?.transition {

            case .representable(let options, let transition):
                switch operation {
                case .push:
                    guard adapter?.viewController == toVC else { return nil }
                    return transition.navigationController(
                        navigationController,
                        pushing: toVC,
                        from: fromVC,
                        context: makeContext(options: options)
                    )

                case .pop:
                    guard
                        adapter?.viewController == fromVC,
                        presentingViewController == toVC || presentingViewController?.isDescendent(of: toVC) == true
                    else {
                        return nil
                    }
                    let animationController = transition.navigationController(
                        navigationController,
                        popping: fromVC,
                        to: toVC,
                        context: makeContext(options: options)
                    )
                    if let transition = animationController as? UIPercentDrivenInteractiveTransition {
                        transition.wantsInteractiveStart = transition.wantsInteractiveStart && options.isInteractive
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
        coordinator.sourceView = nil
        if let adapter = coordinator.adapter {
            if adapter.transition.options.shouldAutomaticallyDismissDestination {
                if coordinator.isPushing != false {
                    let transaction = Transaction(animation: coordinator.didPresentAnimated ? .default : nil)
                    withCATransaction {
                        coordinator.onPop(1, transaction: transaction)
                    }
                }
            } else {
                adapter.coordinator = coordinator
            }
        }
    }
}

@objc
protocol DestinationLinkDelegate: UINavigationControllerDelegate{

    func navigationControllerShouldBeginInteractivePop(
        _ navigationController: UINavigationController,
        gesture: UIGestureRecognizer,
        edge: Bool
    ) -> Bool

    func navigationControllerHapticsForInteractivePop(
        _ navigationController: UINavigationController
    ) -> Int

    func navigationController(
        _ navigationController: UINavigationController,
        didPop viewController: UIViewController,
        animated: Bool
    )
}

@available(iOS 14.0, *)
final class DestinationLinkDelegateProxy: NSObject,
    UINavigationControllerDelegate,
    UIGestureRecognizerDelegate,
    UINavigationControllerPresentationDelegate
{

    private weak var navigationController: UINavigationController?
    private weak var delegate: UINavigationControllerDelegate?
    private var delegates = [ObjectIdentifier: ObjCWeakBox<DestinationLinkDelegate>]()

    var transitioningId: ObjectIdentifier?
    weak var transition: UIPercentDrivenInteractiveTransition?

    private weak var popGestureDelegate: UIGestureRecognizerDelegate?
    private weak var panGestureDelegate: UIGestureRecognizerDelegate?
    private var interactivePopEdgeGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    private var interactivePopPanGestureRecognizer: UIPanGestureRecognizer!

    private var wantsInteractiveTransition = false
    private var queuedTransition: UIPercentDrivenInteractiveTransition?
    private var isInterruptedInteractiveTransition: Bool = false

    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var isPopReady = false
    private let threshold: CGFloat = 0.55

    init(for navigationController: UINavigationController) {
        super.init()
        self.delegate = navigationController.delegate
        popGestureDelegate = navigationController.interactivePopGestureRecognizer?.delegate
        navigationController.interactivePopGestureRecognizer?.delegate = self
        if #available(iOS 26.0, *) {
            panGestureDelegate = navigationController.interactiveContentPopGestureRecognizer?.delegate
            navigationController.interactiveContentPopGestureRecognizer?.delegate = self
        }
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
            interactivePopEdgeGestureRecognizer.edges = [.left]
            interactivePopEdgeGestureRecognizer.delaysTouchesBegan = true
        }
        navigationController.view.addGestureRecognizer(interactivePopEdgeGestureRecognizer)

        interactivePopPanGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureDidChange(_:))
        )
        interactivePopPanGestureRecognizer.delegate = self
        navigationController.view.addGestureRecognizer(interactivePopPanGestureRecognizer)

        navigationController.pushDelegate = self
    }

    func add(
        delegate: DestinationLinkDelegate,
        for viewController: UIViewController
    ) {
        delegates[ObjectIdentifier(viewController)] = ObjCWeakBox(value: delegate)
    }

    func remove(
        delegate: DestinationLinkDelegate,
        for viewController: UIViewController
    ) {
        delegates[ObjectIdentifier(viewController)] = nil
    }

    @objc
    private func interactivePopGestureDidChange(
        _ gestureRecognizer: UIScreenEdgePanGestureRecognizer
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
            let navigationController,
            let transition
        else {
            gestureRecognizer.isEnabled = false
            gestureRecognizer.isEnabled = true
            panGestureDidEnd()
            return
        }

        let translation = gestureRecognizer.translation(in: view)
        let velocity = gestureRecognizer.velocity(in: view)
        var percentage: CGFloat
        if isInterruptedInteractiveTransition {
            percentage = 1 - min(max(0, translation.x / view.bounds.width), 1)
        } else {
            percentage = min(max(0, translation.x / view.bounds.width), 1)
        }

        switch gestureRecognizer.state {
        case .began:
            if isInterruptedInteractiveTransition {
                if let topViewController = navigationController.topViewController,
                   let frame = topViewController.view.layer.presentation()?.frame
                {
                    gestureRecognizer.setTranslation(frame.origin, in: nil)
                }
            } else {
                navigationController.popViewController(animated: true)
            }

        case .changed:
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
            if gestureRecognizer.state == .ended {
                let targetVelocityThreshold: CGFloat = isInterruptedInteractiveTransition ? 100 : 0
                if interactivePopEdgeGestureRecognizer.edges.contains(.left), !shouldFinish {
                    shouldFinish = (percentage >= threshold && targetVelocity >= -targetVelocityThreshold) || (percentage > 0 && targetVelocity >= 800)
                }
                if interactivePopEdgeGestureRecognizer.edges.contains(.right), !shouldFinish {
                    shouldFinish = (percentage >= threshold && targetVelocity <= targetVelocityThreshold) || (percentage > 0 && targetVelocity <= -800)
                }
            }
            // `completionSpeed` handling seems to differ across iOS version
            if #available(iOS 18.0, *) {
                if shouldFinish {
                    transition.completionSpeed = max(1 - percentage, 0.35)
                } else {
                    transition.completionSpeed = max(percentage, 0.35)
                }
            } else {
                transition.completionSpeed = max(1 - percentage, 0.35)
            }
            let delta = (!shouldFinish || isInterruptedInteractiveTransition ? (1 - percentage) : percentage) * navigationController.view.frame.width
            if isInterruptedInteractiveTransition || !shouldFinish {
                targetVelocity = -targetVelocity
            }
            var dx = delta >= 1 ? targetVelocity / delta : 0
            if dx < 0 {
                dx = max(dx, -25)
            } else {
                dx = min(dx, 25)
            }
            let initialVelocity = CGVector(
                dx: dx,
                dy: 0
            )
            transition.timingCurve = UISpringTimingParameters(
                dampingRatio: 0.84,
                initialVelocity: initialVelocity
            )
            if shouldFinish {
                transition.finish()
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
                        animated: true
                    )
                }
            }
            panGestureDidEnd()

        default:
            break
        }
    }

    private func panGestureDidEnd() {
        transition = nil
        transitioningId = nil
        queuedTransition = nil
        isInterruptedInteractiveTransition = false
        isPopReady = false
        feedbackGenerator = nil
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

    // MARK: - UINavigationControllerPresentationDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        didPop viewController: UIViewController,
        animated: Bool
    ) {
        let delegate = delegates[ObjectIdentifier(viewController)]?.value
        delegate?.navigationController(navigationController, didPop: viewController, animated: animated)
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard
            let navigationController = navigationController,
            navigationController.viewControllers.count > 1,
            navigationController.presentedViewController?.isBeingDismissed ?? true,
            let fromVC = navigationController.topViewController,
            fromVC.presentedViewController?.isBeingDismissed ?? true
        else {
            return false
        }

        let shouldBegin: Bool? = {
            guard let delegate = delegates[ObjectIdentifier(fromVC)]?.value else {
                return nil
            }
            let isEdge = gestureRecognizer == interactivePopEdgeGestureRecognizer || gestureRecognizer == navigationController.interactivePopGestureRecognizer
            let shouldBegin = delegate.navigationControllerShouldBeginInteractivePop(
                navigationController,
                gesture: gestureRecognizer,
                edge: isEdge
            )
            return shouldBegin
        }()

        if gestureRecognizer == interactivePopEdgeGestureRecognizer || gestureRecognizer == interactivePopPanGestureRecognizer {
            guard shouldBegin == true else { return false }
            if let transition, transition != queuedTransition {
                isInterruptedInteractiveTransition = true
                return true
            }
            isInterruptedInteractiveTransition = false
            wantsInteractiveTransition = true; defer { wantsInteractiveTransition = false }
            let animationController = self.navigationController(
                navigationController,
                animationControllerFor: .pop,
                from: fromVC,
                to: navigationController.viewControllers[navigationController.viewControllers.count - 2]
            )
            guard
                let interactiveTransition = animationController as? UIPercentDrivenInteractiveTransition,
                interactiveTransition.wantsInteractiveStart
            else {
                transitioningId = nil
                queuedTransition = nil
                return false
            }
            queuedTransition = interactiveTransition
            return true
        } else {
            if shouldBegin == false {
                return false
            }
            if gestureRecognizer == navigationController.interactivePopGestureRecognizer {
                let canBegin = popGestureDelegate?.gestureRecognizerShouldBegin?(
                    gestureRecognizer
                )
                return canBegin ?? true
            }
            if #available(iOS 26.0, *), gestureRecognizer == navigationController.interactiveContentPopGestureRecognizer {
                let canBegin = panGestureDelegate?.gestureRecognizerShouldBegin?(
                    gestureRecognizer
                )
                return canBegin ?? true
            }
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
            return otherGestureRecognizer.isZoomDismissGesture
        } else {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                let shouldRecognizeSimultaneouslyWith = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRecognizeSimultaneouslyWith: otherGestureRecognizer
                )
                return shouldRecognizeSimultaneouslyWith ?? false
            }
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldRecognizeSimultaneouslyWith = popGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRecognizeSimultaneouslyWith: otherGestureRecognizer
                )
                return shouldRecognizeSimultaneouslyWith ?? false
            }
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
            if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer || otherGestureRecognizer is UILongPressGestureRecognizer ||
                otherGestureRecognizer.isSwiftUIGestureResponder {
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
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldRequireFailureOf = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldRequireFailureOf: otherGestureRecognizer
                )
                return shouldRequireFailureOf ?? false
            }
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
            if #available(iOS 26.0, *), otherGestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                return true
            }
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
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldBeRequiredToFailBy = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldBeRequiredToFailBy: otherGestureRecognizer
                )
                return shouldBeRequiredToFailBy ?? false
            }
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
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldReceive = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: touch
                )
                return shouldReceive ?? true
            }
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
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldReceive = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: press
                )
                return shouldReceive ?? true
            }
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
            if #available(iOS 26.0, *), gestureRecognizer == navigationController?.interactiveContentPopGestureRecognizer {
                let shouldReceive = panGestureDelegate?.gestureRecognizer?(
                    gestureRecognizer,
                    shouldReceive: event
                )
                return shouldReceive ?? true
            }
            return true
        }
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
        transition = nil
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

        guard let transitioningId else { return nil }
        let delegate = delegates[transitioningId]?.value
        let interactionController = delegate?.navigationController?(
            navigationController,
            interactionControllerFor: animationController
        )
        return interactionController
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        if queuedTransition != nil, !interactivePopEdgeGestureRecognizer.isInteracting && !interactivePopPanGestureRecognizer.isInteracting {
            queuedTransition = nil
        }
        let id = ObjectIdentifier(operation == .push ? toVC : fromVC)
        if let transition, transitioningId == id {
            return transition as? UIViewControllerAnimatedTransitioning
        }

        let delegate = delegates[id]?.value
        let animationController = delegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
        if let transition = animationController as? UIPercentDrivenInteractiveTransition {
            transition.wantsInteractiveStart = transition.wantsInteractiveStart && wantsInteractiveTransition
        }
        transitioningId = animationController != nil ? id : nil
        transition = animationController as? UIPercentDrivenInteractiveTransition
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
private class DestinationLinkDestinationViewControllerAdapter<
    Destination: View,
    SourceView: View
>: ViewControllerAdapter<Destination, DestinationLinkAdapterBody<Destination, SourceView>> {

    typealias DestinationController = DestinationHostingController<ModifiedContent<Destination, DestinationBridgeAdapter>>

    var transition: DestinationLinkTransition.Value
    weak var sourceView: UIView?
    var environment: EnvironmentValues
    var isPresented: Binding<Bool>
    var onPop: (Int, Transaction) -> Void

    weak var navigationController: UINavigationController?

    // Set to create a retain cycle if !shouldAutomaticallyDismissDestination
    var coordinator: DestinationLinkAdapterBody<Destination, SourceView>.Coordinator?

    init(
        destination: Destination,
        sourceView: UIView,
        transition: DestinationLinkTransition.Value,
        context: DestinationLinkAdapterBody<Destination, SourceView>.Context,
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
        self.viewController.overrideUserInterfaceStyle = .init(transition.options.preferredPresentationColorScheme)
    }

    func update(
        destination: Destination,
        context: DestinationLinkAdapterBody<Destination, SourceView>.Context,
        isPresented: Binding<Bool>
    ) {
        self.isPresented = isPresented
        self.environment = context.environment
        self.viewController.overrideUserInterfaceStyle = .init(transition.options.preferredPresentationColorScheme)
        super.updateViewController(content: destination, context: context)
    }

    override func makeHostingController(
        content: Destination,
        context: DestinationLinkAdapterBody<Destination, SourceView>.Context
    ) -> UIViewController {
        let modifier =  DestinationBridgeAdapter(
            destinationCoordinator: DestinationCoordinator(
                isPresented: isPresented.wrappedValue,
                sourceView: sourceView,
                seed: unsafeBitCast(self, to: UInt.self),
                dismissBlock: { [weak self] in self?.pop($0, $1) }
            )
        )
        let hostingController = DestinationController(content: content.modifier(modifier))
        hostingController.sourceViewController = sourceView?.viewController as? AnyHostingController
        transition.update(
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
        context: DestinationLinkAdapterBody<Destination, SourceView>.Context
    ) {
        let modifier = DestinationBridgeAdapter(
            destinationCoordinator: DestinationCoordinator(
                isPresented: isPresented.wrappedValue,
                sourceView: sourceView,
                seed: unsafeBitCast(self, to: UInt.self),
                dismissBlock: { [weak self] in self?.pop($0, $1) }
            )
        )
        let hostingController = viewController as! DestinationController
        hostingController.update(content: content.modifier(modifier), transaction: context.transaction)
        transition.update(
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
            seed: unsafeBitCast(self, to: UInt.self),
            dismissBlock: { [weak self] in self?.pop($0, $1) }
        )
        environment.destinationCoordinator = destinationCoordinator
    }

    func pop(_ count: Int, _ transaction: Transaction) {
        onPop(count, transaction)
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition.Value {

    func update<Content: View>(
        _ viewController: DestinationHostingController<Content>,
        context: @autoclosure () -> DestinationLinkTransitionRepresentableContext
    ) {

        viewController.hidesBottomBarWhenPushed = options.hidesBottomBarWhenPushed
        if let preferredPresentationBackgroundUIColor = options.preferredPresentationBackgroundUIColor {
            viewController.view.backgroundColor = preferredPresentationBackgroundUIColor
        }

        if case .representable(_, let representable) = self {
            representable.updateHostingController(
                presenting: viewController,
                context: context()
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
