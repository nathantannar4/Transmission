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
public struct DestinationLinkPathAdapterModifier<Value: Sendable, Destination: View>: ViewModifier {

    @Binding var path: DestinationLinkPath<Value>
    var transition: (Value) -> DestinationLinkTransition
    var destination: (Value) -> Destination

    public init(
        path: Binding<DestinationLinkPath<Value>>,
        transition: @escaping (Value) -> DestinationLinkTransition,
        destination: @escaping (Value) -> Destination
    ) {
        self._path = path
        self.transition = transition
        self.destination = destination
    }

    public func body(content: Content) -> some View {
        content
            .background(
                DestinationLinkPathAdapter(
                    path: $path,
                    transition: transition,
                    destination: destination
                )
            )
    }
}

@available(iOS 14.0, *)
extension View {

    public func destination<Value, Destination: View>(
        path: Binding<DestinationLinkPath<Value>>,
        transition: @escaping (Value) -> DestinationLinkTransition = { _ in .default },
        destination: @escaping (Value) -> Destination
    ) -> some View {
        modifier(
            DestinationLinkPathAdapterModifier(
                path: path,
                transition: transition,
                destination: destination
            )
        )
    }
}

@available(iOS 14.0, *)
private struct DestinationLinkPathAdapter<
    Value: Sendable,
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
    Value: Sendable,
    Destination: View,
    Representable: UIViewRepresentable
>: ViewControllerReaderDelegate {

    var path: Binding<DestinationLinkPath<Value>>

    typealias ChildCoordinator = DestinationLinkCoordinator<Destination, Representable>
    var coordinators: [DestinationLinkPath<Value>.ID: ChildCoordinator] = [:]

    weak var presentingViewController: UIViewController?

    init(path: Binding<DestinationLinkPath<Value>>) {
        self.path = path
    }

    func viewControllerReaderDidMoveToWindow(_ view: UIView) {
        guard presentingViewController == nil else { return }
        if let viewController = view.viewController {
            presentingViewController = viewController
            if !coordinators.isEmpty {
                pushPop(
                    presentingViewController: viewController,
                    added: Set(coordinators.keys),
                    removed: [],
                    isAnimated: false
                )
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
        var added = Set<DestinationLinkPath<Value>.ID>()
        var removed = self.path.wrappedValue.ids
            .subtracting(path.wrappedValue.ids)
        self.path = path

        for (index, value) in path.wrappedValue.enumerated() {
            let id = path.wrappedValue.id(for: index)
            guard let value else {
                removed.insert(id)
                continue
            }
            let isPresented = path[index].isNotNil()
            let coordinator = {
                if let coordinator = coordinators[id] {
                    return coordinator
                }
                let coordinator = ChildCoordinator(isPresented: isPresented, isChildCoordinator: true)
                coordinators[id] = coordinator
                added.insert(id)
                return coordinator
            }()
            coordinator.onUpdate(
                isPresented: isPresented,
                transition: transition(value),
                destination: destination(value),
                context: context,
                sourceView: sourceView
            )
        }

        if let presentingViewController {
            pushPop(
                presentingViewController: presentingViewController,
                added: added,
                removed: removed,
                isAnimated: context.transaction.isAnimated
            )
        }
    }

    func onDismantle() {
        for coordinator in coordinators.values {
            coordinator.onDismantle()
        }
    }

    private func pushPop(
        presentingViewController: UIViewController?,
        added: Set<DestinationLinkPath<Value>.ID>,
        removed: Set<DestinationLinkPath<Value>.ID>,
        isAnimated: Bool
    ) {
        guard let navigationController = presentingViewController?._navigationController else { return }

        var viewControllers = navigationController.viewControllers

        for added in added {
            guard let coordinator = coordinators[added] else { continue }
            coordinator.bind(to: navigationController)
            if let viewController = coordinator.viewController {
                viewControllers.append(viewController)
            }
        }

        for remove in removed {
            guard let coordinator = coordinators.removeValue(forKey: remove) else { continue }
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
