//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public enum ConditionalLinkTransition: Sendable {
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
///  - ``ConditionalLinkModifier``
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
public struct ConditionalLinkAdapter<
    Value,
    Content: View,
    Destination: View
>: View {

    var transition: (Value) -> ConditionalLinkTransition
    var useHostingControllerAsSourceView: Bool
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var value: Binding<Value?>
    var content: Content
    var destination: (Value) -> Destination

    public init(
        value: Binding<Value?>,
        useHostingControllerAsSourceView: Bool = false,
        transition: @escaping (Value) -> ConditionalLinkTransition,
        @ViewBuilder destination: @escaping (Value) -> Destination
    ) where Content == EmptyView {
        self.init(
            value: value,
            useHostingControllerAsSourceView: useHostingControllerAsSourceView,
            transition: transition,
            destination: destination,
            content: {
                EmptyView()
            }
        )
    }

    public init(
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        value: Binding<Value?>,
        useHostingControllerAsSourceView: Bool = false,
        transition: @escaping (Value) -> ConditionalLinkTransition,
        @ViewBuilder destination: @escaping (Value) -> Destination,
        @ViewBuilder content: () -> Content
    ) {
        self.transition = transition
        self.useHostingControllerAsSourceView = useHostingControllerAsSourceView
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.value = value
        self.content = content()
        self.destination = destination
    }

    public var body: some View {
        ConditionalLinkAdapterBody(
            transition: transition,
            useHostingControllerAsSourceView: useHostingControllerAsSourceView,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            value: value,
            destination: destination,
            sourceView: content
        )
    }
}

@available(iOS 14.0, *)
private struct ConditionalLinkAdapterBody<
    Value,
    Destination: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: (Value) -> ConditionalLinkTransition
    var useHostingControllerAsSourceView: Bool
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var value: Binding<Value?>
    var destination: (Value) -> Destination
    var sourceView: SourceView

    @WeakState var presentingViewController: UIViewController?

    typealias UIViewType = TransitionSourceView<SourceView>

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType(
            presentingViewController: $presentingViewController,
            content: sourceView,
            useHostingController: useHostingControllerAsSourceView
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.update(content: sourceView, transaction: context.transaction)
        uiView.hostingView?.cornerRadius = cornerRadius
        uiView.hostingView?.backgroundColor = backgroundColor?.toUIColor()
        context.coordinator.onUpdate(
            presentingViewController: presentingViewController,
            value: value,
            transition: transition,
            destination: destination,
            context: context,
            sourceView: uiView.hostingView ?? uiView
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
        size = uiView.sizeThatFits(ProposedSize(proposedSize))
    }

    static func dismantleUIView(
        _ uiView: UIViewType,
        coordinator: Coordinator
    ) {
        coordinator.onDismantle()
    }

    typealias Coordinator = ConditionalLinkCoordinator<Value, Destination, Self>

    func makeCoordinator() -> Coordinator {
        Coordinator(value: value)
    }
}

@MainActor @preconcurrency
@available(iOS 14.0, *)
final class ConditionalLinkCoordinator<
    Value,
    Destination: View,
    Representable: UIViewRepresentable
> {

    typealias PresentationCoordinator = PresentationLinkCoordinator<Destination, Representable>
    typealias DestinationCoordinator = DestinationLinkCoordinator<Destination, Representable>

    var value: Binding<Value?>
    var presentationCoordinator: PresentationCoordinator
    var destinationCoordinator: DestinationCoordinator

    init(value: Binding<Value?>) {
        self.value = value
        self.presentationCoordinator = PresentationCoordinator(isPresented: .constant(false))
        self.destinationCoordinator = DestinationCoordinator(isPresented: .constant(false))
    }

    func onUpdate(
        presentingViewController: UIViewController?,
        value: Binding<Value?>,
        transition: (Value) -> ConditionalLinkTransition,
        destination: (Value) -> Destination,
        context: Representable.Context,
        sourceView: UIView
    ) {
        self.value = value
        if let value = value.wrappedValue {
            let transition = transition(value)
            switch transition {
            case .presentation(let transition):
                presentationCoordinator.onUpdate(
                    presentingViewController: presentingViewController,
                    isPresented: self.value.isNotNil(),
                    transition: transition,
                    destination: destination(value),
                    context: context,
                    sourceView: sourceView
                )
                destinationCoordinator.onPop(1, transaction: context.transaction)

            case .destination(let transition):
                presentationCoordinator.onDismiss(1, transaction: context.transaction)
                destinationCoordinator.onUpdate(
                    presentingViewController: presentingViewController,
                    isPresented: self.value.isNotNil(),
                    transition: transition,
                    destination: destination(value),
                    context: context,
                    sourceView: sourceView
                )
            }
        }
    }

    func onDismantle() {
        presentationCoordinator.onDismantle()
        destinationCoordinator.onDismantle()
    }
}

#endif
