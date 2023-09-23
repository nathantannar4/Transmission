//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@frozen
public struct TransitionReaderProxy {
    /// The progress state of the transition from 0 to 1 where 1 is fully presented.
    public var progress: CGFloat

    @usableFromInline
    init(progress: CGFloat) {
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

    @State var proxy = Proxy(progress: 0)

    @inlinable
    public init(@ViewBuilder content: @escaping (Proxy) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(proxy)
            .background(
                TransitionReaderAdapter(progress: $proxy.progress)
            )
    }
}

private struct TransitionReaderAdapter: UIViewRepresentable {

    var progress: Binding<CGFloat>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(
            presentingViewController: Binding(
                get: { context.coordinator.presentingViewController },
                set: { context.coordinator.presentingViewController = $0 }
            )
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: progress)
    }

    final class Coordinator: NSObject {
        let progress: Binding<CGFloat>

        weak var presentingViewController: UIViewController? {
            didSet {
                if oldValue != presentingViewController {
                    presentingViewControllerDidChange()
                }
            }
        }

        private weak var transitionCoordinator: UIViewControllerTransitionCoordinator?
        private weak var displayLink: CADisplayLink?

        init(progress: Binding<CGFloat>) {
            self.progress = progress
        }

        private func presentingViewControllerDidChange() {
            if let presentingViewController = presentingViewController {
                presentingViewController.swizzle_beginAppearanceTransition { [unowned self] in
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

                    transitionCoordinator.notifyWhenInteractionChanges { [unowned self] ctx in
                        self.transitionDidChange(ctx)
                    }
                } else {
                    withAnimation(.interactiveSpring()) {
                        self.progress.wrappedValue = 1
                    }
                }
            } else {
                displayLink?.invalidate()
                progress.wrappedValue = 0
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
            let isPresenting = from !== presentingViewController
            let percentComplete = isPresenting ? transitionCoordinator.percentComplete : 1 - transitionCoordinator.percentComplete

            if transitionCoordinator.isInteractive {
                var transaction = Transaction()
                transaction.isContinuous = true
                withTransaction(transaction) {
                    progress.wrappedValue = percentComplete
                }
            } else {
                let newValue: CGFloat = transitionCoordinator.isCancelled ? isPresenting ? 0 : 1 : isPresenting ? 1 : 0
                var transaction = Transaction(animation: nil)
                if transitionCoordinator.isAnimated {
                    let duration = transitionCoordinator.transitionDuration * percentComplete
                    let animation = transitionCoordinator.completionCurve.toSwiftUI(duration: duration)
                    transaction.animation = animation
                }
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.progress.wrappedValue = newValue
                }
            }
        }

        private func isDismissing(_ vc: UIViewController?) -> Bool {
            guard let vc = vc else {
                return false
            }
            if vc.isBeingDismissed == true || vc.parent == nil {
                return true
            } else if let navigationController = vc.navigationController {
                var current: UIViewController? = vc
                while let c = current {
                    let parent = c.parent
                    if parent == navigationController {
                        return !navigationController.viewControllers.contains(c)
                    }
                    current = parent
                }
            }
            return false
        }
    }
}

extension UIViewController {

    private static var beginAppearanceTransitionKey: Bool = false

    struct BeginAppearanceTransition {
        var value: () -> Void
    }

    func swizzle_beginAppearanceTransition(_ transition: @escaping () -> Void) {
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

        let box = ObjCBox(value: BeginAppearanceTransition(value: transition))
        objc_setAssociatedObject(self, &Self.beginAppearanceTransitionKey, box, .OBJC_ASSOCIATION_RETAIN)
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
}

#endif
