//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

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
        TransitionLinkAdapterBody(
            transition: transition,
            useHostingControllerAsSourceView: useHostingControllerAsSourceView,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            isPresented: isPresented,
            destination: destination,
            sourceView: content
        )
    }
}

@available(iOS 14.0, *)
private struct TransitionLinkAdapterBody<
    Destination: View,
    SourceView: View
>: UIViewRepresentable {

    var transition: LinkTransition
    var useHostingControllerAsSourceView: Bool
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var isPresented: Binding<Bool>
    var destination: Destination
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
> {

    typealias PresentationCoordinator = PresentationLinkCoordinator<Destination, Representable>
    typealias DestinationCoordinator = DestinationLinkCoordinator<Destination, Representable>

    var isPresented: Binding<Bool>
    var presentationCoordinator: PresentationCoordinator
    var destinationCoordinator: DestinationCoordinator

    init(isPresented: Binding<Bool>) {
        self.isPresented = isPresented
        self.presentationCoordinator = PresentationCoordinator(isPresented: .constant(false))
        self.destinationCoordinator = DestinationCoordinator(isPresented: .constant(false))
    }

    func onUpdate(
        presentingViewController: UIViewController?,
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
                presentingViewController: presentingViewController,
                isPresented: isPresented,
                transition: transition,
                destination: destination,
                context: context,
                sourceView: sourceView
            )
            destinationCoordinator.onUpdate(
                presentingViewController: presentingViewController,
                isPresented: .constant(false),
                transition: .default,
                destination: destination,
                context: context,
                sourceView: sourceView
            )

        case .destination(let transition):
            presentationCoordinator.onUpdate(
                presentingViewController: presentingViewController,
                isPresented: .constant(false),
                transition: .default,
                destination: destination,
                context: context,
                sourceView: sourceView
            )
            destinationCoordinator.onUpdate(
                presentingViewController: presentingViewController,
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
