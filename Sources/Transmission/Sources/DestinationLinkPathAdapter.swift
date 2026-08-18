//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A modifier that manages the push of multiple destination views from a ``DestinationLinkPath``
///
/// > Tip: You can support deep linking to multiple views with this modifier
///
@available(iOS 14.0, *)
public struct DestinationLinkPathAdapterModifier<
    Value,
    Destination: View
>: ViewModifier {

    var path: Binding<DestinationLinkPath<Value>>
    var animation: Animation?
    var transition: (Value) -> DestinationLinkTransition
    var destination: (Value) -> Destination

    public init(
        path: Binding<DestinationLinkPath<Value>>,
        animation: Animation? = .default,
        transition: @escaping (Value) -> DestinationLinkTransition,
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
                DestinationLinkPathAdapter(
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

    public func destination<Value, Destination: View>(
        path: Binding<DestinationLinkPath<Value>>,
        animation: Animation? = .default,
        transition: @escaping (Value) -> DestinationLinkTransition = { _ in .default },
        destination: @escaping (Value) -> Destination
    ) -> some View {
        modifier(
            DestinationLinkPathAdapterModifier(
                path: path,
                animation: animation,
                transition: transition,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
private struct DestinationLinkPathAdapter<
    Value,
    Destination: View
>: UIViewRepresentable {

    var path: Binding<DestinationLinkPath<Value>>
    var transition: (Value) -> DestinationLinkTransition
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

    typealias Coordinator = DestinationLinkPathCoordinator<Value, Destination, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(path: path)
    }
}

@MainActor @preconcurrency
@available(iOS 14.0, *)
final class DestinationLinkPathCoordinator<
    Value,
    Destination: View,
    Representable: UIViewRepresentable
>: ViewControllerReaderDelegate {

    private var path: Binding<DestinationLinkPath<Value>>

    private typealias ChildCoordinator = DestinationLinkCoordinatorAdapter<Destination, Representable>
    private var ids: [DestinationLinkPath<Value>.ID] = []
    private var coordinators: [DestinationLinkPath<Value>.ID: ChildCoordinator] = [:]

    private var animation: Animation?

    private weak var presentingViewController: UIViewController?

    init(path: Binding<DestinationLinkPath<Value>>) {
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
        path: Binding<DestinationLinkPath<Value>>,
        transition: (Value) -> DestinationLinkTransition,
        destination: (Value) -> Destination,
        context: Representable.Context,
        sourceView: UIView
    ) {
        let oldValue = Set(ids)
        let newValue = Set(path.wrappedValue.ids)
        let removed: [DestinationLinkPath<Value>.ID] = {
            let difference = oldValue.subtracting(newValue)
            return ids.filter { difference.contains($0) }
        }()
        ids = path.wrappedValue.ids
        let added: [DestinationLinkPath<Value>.ID] = {
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
        guard let presentingViewController else { return }
        update(
            presentingViewController: presentingViewController,
            added: [],
            removed: ids,
            isAnimated: true
        )
        withCATransaction { [path] in
            withAnimation(.default) {
                path.wrappedValue.pop(count: .max)
            }
        }
    }

    private func update(
        presentingViewController: UIViewController,
        added: [DestinationLinkPath<Value>.ID],
        removed: [DestinationLinkPath<Value>.ID],
        isAnimated: Bool
    ) {
        guard let navigationController = presentingViewController._navigationController else { return }
        if let transitionCoordinator = navigationController.transitionCoordinator, transitionCoordinator.presentationStyle == .none {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.update(
                    navigationController: navigationController,
                    added: added,
                    removed: removed,
                    isAnimated: isAnimated
                )
            }
        } else {
            update(
                navigationController: navigationController,
                added: added,
                removed: removed,
                isAnimated: isAnimated
            )
        }
    }

    private func update(
        navigationController: UINavigationController,
        added: [DestinationLinkPath<Value>.ID],
        removed: [DestinationLinkPath<Value>.ID],
        isAnimated: Bool
    ) {
        guard let navigationController = presentingViewController?._navigationController else { return }

        var viewControllers = navigationController.viewControllers

        for id in added {
            guard let coordinator = coordinators[id] else { continue }
            coordinator.bind(to: navigationController)
            if let viewController = coordinator.viewController {
                viewControllers.append(viewController)
            }
        }

        for id in removed {
            guard let coordinator = coordinators.removeValue(forKey: id) else { continue }
            viewControllers.removeAll(where: { $0 === coordinator.viewController })
        }

        if navigationController.viewControllers != viewControllers {
            let update: () -> Void = {
                navigationController.setViewControllers(
                    viewControllers,
                    animated: isAnimated
                )
            }
            if let firstResponder = navigationController.topViewController?.firstResponder {
                withCATransaction {
                    firstResponder.resignFirstResponder()
                    update()
                }
            } else {
                update()
            }
        }
    }
}

#endif
