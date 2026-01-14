//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@frozen
public struct TransitionReaderProxy: Equatable {

    /// The progress state of the transition from 0 to 1 where 1 is fully presented.
    public var progress: CGFloat

    public var isPresented: Bool { progress > 0 }

    @usableFromInline
    init() {
        self.progress = 0
    }
}

/// A container view that defines its content as a function of its hosting view's
/// `UIViewControllerTransitionCoordinator` transition progress.
///
/// > Tip: Use a ``TransitionReader`` to build interactive presentation and dismissal
/// transitions
///
@frozen
public struct TransitionReader<Content: View>: View {

    public typealias Proxy = TransitionReaderProxy

    @usableFromInline
    var content: (Proxy) -> Content

    @State var proxy = Proxy()

    @inlinable
    public init(@ViewBuilder content: @escaping (Proxy) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(proxy)
            .background(
                TransitionReaderAdapter(proxy: $proxy)
            )
    }
}

private struct TransitionReaderAdapter: UIViewRepresentable {

    var proxy: Binding<TransitionReaderProxy>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(
            onDidMoveToWindow: { viewController in
                var parent = viewController
                while let next = parent?.parent {
                    parent = next
                }
                context.coordinator.presentingViewController = parent
            }
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) { }

    func makeCoordinator() -> TransitionReaderCoordinator {
        TransitionReaderCoordinator(proxy: proxy)
    }
}

@MainActor @preconcurrency
final class TransitionReaderCoordinator: NSObject {
    let proxy: Binding<TransitionReaderProxy>

    weak var presentingViewController: UIViewController? {
        didSet {
            if oldValue != presentingViewController {
                oldValue?.transitionReaderCoordinator = nil
                presentingViewControllerDidChange()
            }
        }
    }

    private weak var transitionCoordinator: UIViewControllerTransitionCoordinator?
    private weak var displayLink: CADisplayLink?

    init(proxy: Binding<TransitionReaderProxy>) {
        self.proxy = proxy
    }

    deinit {
        presentingViewController = nil
    }

    func update(isPresented: Bool) {
        proxy.wrappedValue.progress = isPresented ? 1 : 0
    }

    private func presentingViewControllerDidChange() {
        if let presentingViewController {
            presentingViewController.transitionReaderCoordinator = self

            presentingViewController.swizzle_beginAppearanceTransition { [unowned self] in
                self.transitionCoordinatorDidChange()
            }
            presentingViewController.swizzle_endAppearanceTransition { [unowned self] in
                self.transitionCoordinatorDidChange()
            }
        }

        transitionCoordinatorDidChange()
    }

    private func transitionCoordinatorDidChange() {
        if let presentingViewController = presentingViewController {
            if let transitionCoordinator = presentingViewController.transitionCoordinator, displayLink == nil {
                if transitionCoordinator.isInteractive {
                    let displayLink = CADisplayLink(target: self, selector: #selector(onClockTick(displayLink:)))
                    displayLink.add(to: .current, forMode: .common)
                    self.displayLink = displayLink
                    self.transitionCoordinator = transitionCoordinator

                    transitionCoordinator.notifyWhenInteractionChanges { [weak self] ctx in
                        self?.transitionDidChange(ctx, isInProgress: true)
                    }
                } else {
                    transitionDidChange(transitionCoordinator, isInProgress: false)
                    transitionCoordinator.animate { [weak self] ctx in
                        self?.transitionDidChange(ctx, isInProgress: true)
                    }
                }
            } else if presentingViewController.isBeingPresented || presentingViewController.isBeingDismissed {
                let isPresented = presentingViewController.isBeingPresented
                let newValue: CGFloat = isPresented ? 1 : 0
                guard proxy.wrappedValue.progress != newValue else { return }
                let transaction = Transaction(animation: nil)
                withTransaction(transaction) {
                    self.proxy.wrappedValue.progress = newValue
                }
            } else {
                let transaction = Transaction(animation: nil)
                withTransaction(transaction) {
                    self.proxy.wrappedValue.progress = 1
                }
            }
        } else {
            displayLink?.invalidate()
            proxy.wrappedValue.progress = 0
        }
    }

    @objc
    private func onClockTick(displayLink: CADisplayLink) {
        if let transitionCoordinator = transitionCoordinator {
            transitionDidChange(transitionCoordinator, isInProgress: true)
        } else {
            displayLink.invalidate()
        }
    }

    private func transitionDidChange(
        _ transitionContext: UIViewControllerTransitionCoordinatorContext,
        isInProgress: Bool
    ) {
        let isPresenting = transitionContext.viewController(forKey: .to) == presentingViewController
        let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented?.view

        if transitionContext.isInteractive {
            let newValue = isPresenting
                ? transitionContext.percentComplete
                : 1 - transitionContext.percentComplete
            guard proxy.wrappedValue.progress != newValue else { return }
            var transaction = Transaction()
            transaction.isContinuous = true
            withTransaction(transaction) {
                proxy.wrappedValue.progress = newValue
            }
        } else if isInProgress || transitionContext.isCancelled || transitionContext.presentationStyle == .none {
            let newValue: CGFloat = transitionContext.isCancelled
                ? isPresenting ? 0 : 1
                : isPresenting ? 1 : 0
            guard proxy.wrappedValue.progress != newValue else { return }
            var transaction = Transaction(animation: nil)
            if transitionContext.isAnimated {
                if let animation = presented?.transitionReaderAnimation, animation.resolved()?.timingCurve != .default {
                    transaction.animation = animation
                } else {
                    let duration = transitionContext.transitionDuration == 0 ? 0.35 : transitionContext.transitionDuration
                    let animation = transitionContext.completionCurve.toSwiftUI(duration: duration)
                    transaction.animation = animation
                }
            }
            withTransaction(transaction) {
                proxy.wrappedValue.progress = newValue
            }
            if isInProgress {
                presentedView?.layoutIfNeeded()
            }
        }
    }
}

private nonisolated(unsafe) var transitionReaderAnimationKey: UInt = 0

private nonisolated(unsafe) var transitionReaderCoordinatorKey: UInt = 0

extension UIViewController {

    var transitionReaderAnimation: Animation? {
        get {
            if let box = objc_getAssociatedObject(self, &transitionReaderAnimationKey) as? ObjCBox<Animation?> {
                return box.value
            }
            return nil
        }
        set {
            let box = newValue.map { ObjCBox<Animation?>(value: $0) }
            objc_setAssociatedObject(self, &transitionReaderAnimationKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var transitionReaderCoordinator: TransitionReaderCoordinator? {
        get {
            if let box = objc_getAssociatedObject(self, &transitionReaderCoordinatorKey) as? ObjCWeakBox<TransitionReaderCoordinator> {
                return box.value
            }
            return nil
        }
        set {
            let box = newValue.map { ObjCWeakBox<TransitionReaderCoordinator>(value: $0) }
            objc_setAssociatedObject(self, &transitionReaderCoordinatorKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

#endif
