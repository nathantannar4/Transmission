//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A ``ViewInputFlag`` to force a ``TransitionLinkAdapter``
/// to lazy load its `UIViewRepresentable` to make it more performant.
///
/// By default, ``TransitionLinkAdapter`` detects when its in a built in
/// lazy view, such as `LazyVStack`, and will always lazy load.
///
/// Disable lazy loading via ``.defaultInput(TransitionLinkAdapterIsLazy.self)``
///
@available(iOS 14.0, *)
public struct TransitionLinkAdapterIsLazy: ViewInputFlag, ViewInputsCondition {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        if let isLazy = inputs[Self.self, default: nil] {
            return isLazy
        }
        return IsInLazyContainer.evaluate(inputs) || IsInHostingConfiguration.evaluate(inputs)
    }
}

@frozen
@available(iOS 14.0, *)
public enum LinkTransition: Sendable {
    case presentation(PresentationLinkTransition)
    case destination(DestinationLinkTransition)
}

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
///  - ``TransitionLinkModifier``
///  - ``PresentationLink``
///  - ``PresentationLinkTransition``
///  - ``PresentationSourceViewLink``
///  - ``DestinationLink``
///  - ``DestinationLinkTransition``
///  - ``DestinationSourceViewLink``
///  - ``TransitionReader``
///
@frozen
@available(iOS 14.0, *)
public struct TransitionLinkAdapter<
    Content: View,
    Destination: View
>: View {

    var transition: LinkTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var useHostingControllerAsSourceView: Bool
    var isPresented: Binding<Bool>
    var content: Content
    var destination: Destination

    public init(
        transition: LinkTransition,
        useHostingControllerAsSourceView: Bool = false,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) where Content == EmptyView {
        self.init(
            transition: transition,
            useHostingControllerAsSourceView: useHostingControllerAsSourceView,
            isPresented: isPresented,
            destination: destination,
            content: {
                EmptyView()
            }
        )
    }

    public init(
        transition: LinkTransition,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        useHostingControllerAsSourceView: Bool = false,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.useHostingControllerAsSourceView = useHostingControllerAsSourceView
        self.isPresented = isPresented
        self.content = content()
        self.destination = destination()
    }

    public var body: some View {
        UnaryViewAdaptor {
            ViewInputConditionalContent(TransitionLinkAdapterIsLazy.self) {
                LazyTransitionLinkAdapter(
                    transition: transition,
                    cornerRadius: cornerRadius,
                    backgroundColor: backgroundColor,
                    useHostingControllerAsSourceView: useHostingControllerAsSourceView,
                    isPresented: isPresented,
                    content: content,
                    destination: destination
                )
            } otherwise: {
                TransitionLinkAdapterBody(
                    transition: transition,
                    cornerRadius: cornerRadius,
                    backgroundColor: backgroundColor,
                    useHostingControllerAsSourceView: useHostingControllerAsSourceView,
                    isPresented: isPresented,
                    destination: destination,
                    sourceView: content
                )
            }
        }
    }
}

@available(iOS 14.0, *)
private struct LazyTransitionLinkAdapter<
    Content: View,
    Destination: View
>: View {

    var transition: LinkTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var useHostingControllerAsSourceView: Bool
    var isPresented: Binding<Bool>
    var content: Content
    var destination: Destination

    @State var isLazyLoaded = false

    var body: some View {
        if isPresented.wrappedValue || isLazyLoaded {
            TransitionLinkAdapterBody(
                transition: transition,
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor,
                useHostingControllerAsSourceView: useHostingControllerAsSourceView,
                isPresented: isPresented,
                destination: destination,
                sourceView: content
            )
            .transition(.identity)
            .onAppear {
                isLazyLoaded = true
            }
        } else {
            content
                .transition(.identity)
        }
    }
}

@available(iOS 14.0, *)
private struct TransitionLinkAdapterBody<
    Destination: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: LinkTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var useHostingControllerAsSourceView: Bool
    var isPresented: Binding<Bool>
    var destination: Destination
    var sourceView: SourceView

    typealias UIViewType = TransitionSourceView<SourceView>

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType(
            content: sourceView,
            useHostingController: useHostingControllerAsSourceView
        )
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.update(
            content: sourceView,
            transaction: context.transaction,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor?.toUIColor(in: context.environment)
        )
        context.coordinator.onUpdate(
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

    static func _modifyBridgedViewInputs(_ inputs: inout _ViewInputs) {
        if SourceView.self != EmptyView.self {
            inputs.bridgeHostingView()
        }
    }

    static func dismantleUIView(
        _ uiView: UIViewType,
        coordinator: Coordinator
    ) {
        coordinator.onDismantle()
    }

    typealias Coordinator = TransitionLinkCoordinator<Destination, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented)
    }
}

@MainActor @preconcurrency
@available(iOS 14.0, *)
final class TransitionLinkCoordinator<
    Destination: View,
    Representable: UIViewRepresentable
>: TransitionSourceViewDelegate {

    typealias PresentationCoordinator = PresentationLinkCoordinatorAdapter<Destination, Representable>
    typealias DestinationCoordinator = DestinationLinkCoordinatorAdapter<Destination, Representable>

    var isPresented: Binding<Bool>
    var presentationCoordinator: PresentationCoordinator
    var destinationCoordinator: DestinationCoordinator

    init(isPresented: Binding<Bool>) {
        self.isPresented = isPresented
        self.presentationCoordinator = PresentationCoordinator(isPresented: .constant(false))
        self.destinationCoordinator = DestinationCoordinator(isPresented: .constant(false))
    }

    func transitionSourceViewDidMoveToWindow(_ view: UIView) {
        presentationCoordinator.transitionSourceViewDidMoveToWindow(view)
        destinationCoordinator.transitionSourceViewDidMoveToWindow(view)
    }

    func onUpdate(
        isPresented: Binding<Bool>,
        transition: LinkTransition,
        destination: Destination,
        context: Representable.Context,
        sourceView: UIView
    ) {
        self.isPresented = isPresented
        switch transition {
        case .presentation(let transition):
            presentationCoordinator.onUpdate(
                isPresented: isPresented,
                transition: transition,
                destination: destination,
                context: context,
                sourceView: sourceView
            )
            destinationCoordinator.onUpdate(
                isPresented: .constant(false),
                transition: .default,
                destination: destination,
                context: context,
                sourceView: sourceView
            )

        case .destination(let transition):
            presentationCoordinator.onUpdate(
                isPresented: .constant(false),
                transition: .default,
                destination: destination,
                context: context,
                sourceView: sourceView
            )
            destinationCoordinator.onUpdate(
                isPresented: isPresented,
                transition: transition,
                destination: destination,
                context: context,
                sourceView: sourceView
            )
        }
    }

    func onDismantle() {
        presentationCoordinator.onDismantle()
        destinationCoordinator.onDismantle()
    }
}

#endif
