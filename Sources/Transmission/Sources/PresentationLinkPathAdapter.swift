//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that manages the presentation of destination views from a ``PresentationLinkPath``
///
/// > Tip: You can support deep linking to multiple views with this modifier
///
@available(iOS 14.0, *)
public struct PresentationLinkPathAdapterModifier<
    Value,
    Destination: View
>: ViewModifier {

    var path: Binding<PresentationLinkPath<Value>>
    var animation: Animation?
    var transition: (Value) -> PresentationLinkTransition
    var destination: (Value) -> Destination

    public init(
        path: Binding<PresentationLinkPath<Value>>,
        animation: Animation? = .default,
        transition: @escaping (Value) -> PresentationLinkTransition,
        destination: @escaping (Value) -> Destination
    ) {
        self.path = path
        self.animation = animation
        self.transition = transition
        self.destination = destination
    }

    public func body(content: Content) -> some View {
        content
            .background(
                PresentationLinkPathAdapter(
                    path: path,
                    transition: transition,
                    destination: destination
                )
                .modifier(
                    OptionalAnimationModifier(
                        animation: animation,
                        value: path.wrappedValue.ids
                    )
                )
            )
    }
}

@available(iOS 14.0, *)
extension View {

    public func presentation<Value, Destination: View>(
        path: Binding<PresentationLinkPath<Value>>,
        animation: Animation? = .default,
        transition: @escaping (Value) -> PresentationLinkTransition = { _ in .default },
        destination: @escaping (Value) -> Destination
    ) -> some View {
        modifier(
            PresentationLinkPathAdapterModifier(
                path: path,
                animation: animation,
                transition: transition,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
private struct PresentationLinkPathAdapter<
    Value,
    Destination: View
>: UIViewRepresentable {

    var path: Binding<PresentationLinkPath<Value>>
    var transition: (Value) -> PresentationLinkTransition
    var destination: (Value) -> Destination

    typealias UIViewType = ViewControllerReader

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.onUpdate(
            path: path,
            transition: transition,
            destination: destination,
            context: context,
            sourceView: uiView
        )
    }

    static func dismantleUIView(
        _ uiView: UIViewType,
        coordinator: Coordinator
    ) {
        coordinator.onDismantle()
    }

    typealias Coordinator = PresentationLinkPathCoordinator<Value, Destination, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(path: path)
    }
}

@MainActor @preconcurrency
@available(iOS 14.0, *)
final class PresentationLinkPathCoordinator<
    Value,
    Destination: View,
    Representable: UIViewRepresentable
>: ViewControllerReaderDelegate {

    private var path: Binding<PresentationLinkPath<Value>>

    private typealias ChildCoordinator = PresentationLinkCoordinatorAdapter<Destination, Representable>
    private var ids: [PresentationLinkPath<Value>.ID] = []
    private var coordinators: [PresentationLinkPath<Value>.ID: ChildCoordinator] = [:]

    private var animation: Animation?

    private weak var presentingViewController: UIViewController?

    init(path: Binding<PresentationLinkPath<Value>>) {
        self.path = path
    }

    func viewControllerReaderDidMoveToWindow(_ view: UIView) {
        guard presentingViewController == nil else { return }
        if let viewController = view.viewController {
            presentingViewController = viewController
            if !coordinators.isEmpty {
                let isAnimated = animation != nil
                withCATransaction { [ids] in
                    self.update(
                        presentingViewController: viewController,
                        added: ids,
                        removed: [],
                        isAnimated: isAnimated
                    )
                }
            }
        }
    }

    func onUpdate(
        path: Binding<PresentationLinkPath<Value>>,
        transition: (Value) -> PresentationLinkTransition,
        destination: (Value) -> Destination,
        context: Representable.Context,
        sourceView: UIView
    ) {
        let oldValue = Set(ids)
        let newValue = Set(path.wrappedValue.ids)
        let removed: [PresentationLinkPath<Value>.ID] = {
            let difference = oldValue.subtracting(newValue)
            return ids.filter { difference.contains($0) }
        }()
        ids = path.wrappedValue.ids
        let added: [PresentationLinkPath<Value>.ID] = {
            let difference = newValue.subtracting(oldValue)
            return ids.filter { difference.contains($0) }
        }()
        self.path = path
        animation = context.transaction.animation

        for id in ids {
            let coordinator = {
                if let coordinator = coordinators[id] {
                    return coordinator
                }
                let coordinator = ChildCoordinator(isPresented: .constant(false), isChildCoordinator: true)
                coordinators[id] = coordinator
                return coordinator
            }()
            if let value = path.wrappedValue[id] {
                var transition = transition(value)
                transition.options.shouldAutomaticallyDismissPresentedView = false
                transition.options.shouldAutomaticallyDismissDestination = true
                coordinator.presentingViewController = presentingViewController
                coordinator.onUpdate(
                    isPresented: path[id].isNotNil(),
                    transition: transition,
                    destination: destination(value),
                    context: context,
                    sourceView: sourceView
                )
            }
        }

        if let presentingViewController {
            update(
                presentingViewController: presentingViewController,
                added: added,
                removed: removed,
                isAnimated: context.transaction.isAnimated
            )
        }
    }

    func onDismantle() {
        if let id = ids.first {
            dismiss(id: id, isAnimated: true)
        }
        withCATransaction { [path] in
            withAnimation(.default) {
                path.wrappedValue.pop(count: .max)
            }
        }
    }

    private func update(
        presentingViewController: UIViewController,
        added: [PresentationLinkPath<Value>.ID],
        removed: [PresentationLinkPath<Value>.ID],
        isAnimated: Bool
    ) {
        if let id = removed.first {
            dismiss(id: id, isAnimated: isAnimated)
        }
        var remaining = added
        if !remaining.isEmpty {
            let id = remaining.removeFirst()
            present(
                presentingViewController: presentingViewController,
                id: id,
                isAnimated: isAnimated
            ) { [weak self, remaining] in
                self?.update(
                    presentingViewController: presentingViewController,
                    added: remaining,
                    removed: [],
                    isAnimated: isAnimated
                )
            }
        }
    }

    private func dismiss(
        id: PresentationLinkPath<Value>.ID,
        isAnimated: Bool
    ) {
        guard let coordinator = coordinators.removeValue(forKey: id) else { return }
        coordinator.viewController?._dismiss(animated: isAnimated)
    }

    private func present(
        presentingViewController: UIViewController,
        id: PresentationLinkPath<Value>.ID,
        isAnimated: Bool,
        completion: (@MainActor @Sendable () -> Void)?
    ) {
        guard let coordinator = coordinators[id] else {
            completion?()
            return
        }
        coordinator.present(
            presentingViewController: presentingViewController,
            isAnimated: isAnimated,
            completion: completion
        )
    }
}

#endif
