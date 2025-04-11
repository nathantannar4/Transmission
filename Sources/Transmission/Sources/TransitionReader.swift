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

/// A modifier that binds the view's size to the ``PresentationCoordinator`` source view size. Intended
/// to be used with ``TransitionReader`` during a `.matchedGeometry` transition.
@frozen
@available(iOS 14.0, *)
public struct TransitionSourceViewFrameModifier: ViewModifier {

    public var isPresented: Bool

    @Environment(\.presentationCoordinator) var presentationCoordinator

    public init(isPresented: Bool) {
        self.isPresented = isPresented
    }

    public func body(content: Content) -> some View {
        let size = presentationCoordinator.sourceView?.frame.size
        let isEnabled = !isPresented && size != nil
        content
            .frame(idealWidth: size?.width, idealHeight: size?.height)
            .fixedSize(horizontal: isEnabled, vertical: isEnabled)
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that binds the view's size to the ``PresentationCoordinator`` source view size. Intended
    /// to be used with ``TransitionReader`` during a `.matchedGeometry` transition.
    public func transitionSourceViewFrame(isPresented: Bool) -> some View {
        modifier(TransitionSourceViewFrameModifier(isPresented: isPresented))
    }
}

private struct TransitionReaderAdapter: UIViewRepresentable {

    var proxy: Binding<TransitionReaderProxy>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(
            onDidMoveToWindow: { viewController in
                context.coordinator.presentingViewController = viewController
            }
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(proxy: proxy)
    }

    final class Coordinator: NSObject {
        let proxy: Binding<TransitionReaderProxy>

        weak var presentingViewController: UIViewController? {
            didSet {
                if oldValue != presentingViewController {
                    presentingViewControllerDidChange()
                }
            }
        }

        private var trackedViewControllers = NSHashTable<UIViewController>.weakObjects()
        private weak var transitionCoordinator: UIViewControllerTransitionCoordinator?
        private weak var displayLink: CADisplayLink?

        init(proxy: Binding<TransitionReaderProxy>) {
            self.proxy = proxy
        }

        deinit {
            presentingViewController = nil
        }

        private func reset() {
            for viewController in trackedViewControllers.allObjects {
                viewController.swizzle_beginAppearanceTransition(nil)
                viewController.swizzle_endAppearanceTransition(nil)
            }
            trackedViewControllers.removeAllObjects()
        }

        private func presentingViewControllerDidChange() {
            reset()

            if let presentingViewController {
                trackedViewControllers.add(presentingViewController)

                if let parent = presentingViewController.parent {
                    trackedViewControllers.add(parent)
                }
            }

            for viewController in trackedViewControllers.allObjects {
                viewController.swizzle_beginAppearanceTransition { [unowned self] in
                    self.transitionCoordinatorDidChange()
                }
                viewController.swizzle_endAppearanceTransition { [unowned self] in
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
                    } else {
                        transitionDidChange(transitionCoordinator)
                    }

                    transitionCoordinator.notifyWhenInteractionChanges { [weak self] ctx in
                        self?.transitionDidChange(ctx)
                    }
                } else if presentingViewController.isBeingPresented || presentingViewController.isBeingDismissed {
                    let isPresented = presentingViewController.isBeingPresented
                    let newValue: CGFloat = isPresented ? 1 : 0
                    guard proxy.wrappedValue.progress != newValue else { return }
                    let transaction = Transaction(animation: nil)
                    withTransaction(transaction) {
                        self.proxy.wrappedValue.progress = newValue
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
                transitionDidChange(transitionCoordinator)
            } else {
                displayLink.invalidate()
            }
        }

        private func transitionDidChange(
            _ transitionCoordinator: UIViewControllerTransitionCoordinatorContext
        ) {
            let from = transitionCoordinator.viewController(forKey: .from)
            let isPresenting = !trackedViewControllers.contains(from)

            if transitionCoordinator.isInteractive {
                let newValue = isPresenting
                    ? transitionCoordinator.percentComplete
                    : 1 - transitionCoordinator.percentComplete
                guard proxy.wrappedValue.progress != newValue else { return }
                var transaction = Transaction()
                transaction.isContinuous = true
                withTransaction(transaction) {
                    proxy.wrappedValue.progress = newValue
                }
            } else {
                let newValue: CGFloat = transitionCoordinator.isCancelled
                    ? isPresenting ? 0 : 1
                    : isPresenting ? 1 : 0
                guard proxy.wrappedValue.progress != newValue else { return }
                var transaction = Transaction(animation: nil)
                if transitionCoordinator.isAnimated {
                    if let animation = transitionCoordinator.animation, animation.resolved()?.timingCurve != .default {
                        transaction.animation = animation
                    } else {
                        let duration = transitionCoordinator.transitionDuration == 0 ? 0.35 : transitionCoordinator.transitionDuration
                        // Offset slightly so the curves aren't in sync with UIKit animation, or it appears more glitchy
                        let animation = transitionCoordinator.completionCurve.toSwiftUI(duration: duration)
                            .speed(1.15)
                        transaction.animation = animation
                    }
                }
                withTransaction(transaction) {
                    proxy.wrappedValue.progress = newValue
                }
            }
        }
    }
}

private var transitionCoordinatorAnimationKey: UInt = 0

extension UIViewControllerTransitionCoordinatorContext {

    var animation: Animation? {
        get {
            if let box = objc_getAssociatedObject(self, &transitionCoordinatorAnimationKey) as? ObjCBox<Animation?> {
                return box.value
            }
            return nil
        }
        set {
            let box = ObjCBox<Animation?>(value: newValue)
            objc_setAssociatedObject(self, &transitionCoordinatorAnimationKey, box, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension UIViewController {

    private static var beginAppearanceTransitionKey: Bool = false

    struct BeginAppearanceTransition {
        var value: () -> Void
    }

    func swizzle_beginAppearanceTransition(_ transition: (() -> Void)?) {
        let original = #selector(UIViewController.beginAppearanceTransition(_:animated:))
        let swizzled = #selector(UIViewController.swizzled_beginAppearanceTransition(_:animated:))

        if !Self.beginAppearanceTransitionKey {
            Self.beginAppearanceTransitionKey = true

            if let originalMethod = class_getInstanceMethod(Self.self, original),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
            {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }

        if let transition {
            let box = ObjCBox(value: BeginAppearanceTransition(value: transition))
            objc_setAssociatedObject(self, &Self.beginAppearanceTransitionKey, box, .OBJC_ASSOCIATION_RETAIN)
        } else {
            objc_setAssociatedObject(self, &Self.beginAppearanceTransitionKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc
    func swizzled_beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
        if let box = objc_getAssociatedObject(self, &Self.beginAppearanceTransitionKey) as? ObjCBox<BeginAppearanceTransition> {
            box.value.value()
        }

        typealias BeginAppearanceTransitionMethod = @convention(c) (NSObject, Selector, Bool, Bool) -> Void
        let swizzled = #selector(UIViewController.swizzled_beginAppearanceTransition(_:animated:))
        unsafeBitCast(method(for: swizzled), to: BeginAppearanceTransitionMethod.self)(self, swizzled, isAppearing, animated)
    }

    private static var endAppearanceTransitionKey: Bool = false

    struct EndAppearanceTransition {
        var value: () -> Void
    }

    func swizzle_endAppearanceTransition(_ transition: (() -> Void)?) {
        let original = #selector(UIViewController.endAppearanceTransition)
        let swizzled = #selector(UIViewController.swizzled_endAppearanceTransition)

        if !Self.endAppearanceTransitionKey {
            Self.endAppearanceTransitionKey = true

            if let originalMethod = class_getInstanceMethod(Self.self, original),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
            {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }

        if let transition {
            let box = ObjCBox(value: EndAppearanceTransition(value: transition))
            objc_setAssociatedObject(self, &Self.endAppearanceTransitionKey, box, .OBJC_ASSOCIATION_RETAIN)
        } else {
            objc_setAssociatedObject(self, &Self.endAppearanceTransitionKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc
    func swizzled_endAppearanceTransition() {
        if let box = objc_getAssociatedObject(self, &Self.endAppearanceTransitionKey) as? ObjCBox<EndAppearanceTransition> {
            box.value.value()
        }

        typealias EndAppearanceTransitionMethod = @convention(c) (NSObject, Selector) -> Void
        let swizzled = #selector(UIViewController.swizzled_endAppearanceTransition)
        unsafeBitCast(method(for: swizzled), to: EndAppearanceTransitionMethod.self)(self, swizzled)
    }
}

#endif
