//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A coordinator that can be used to programatically dismiss a view.
///
/// See Also:
///  - ``PresentationLink``
///  - ``WindowLink``
///
@available(iOS 14.0, *)
@frozen
public struct PresentationCoordinator: @unchecked Sendable {
    public var isPresented: Bool

    public weak var sourceView: UIView?

    @usableFromInline
    var dismissBlock: @MainActor (Int, Transaction) -> Void

    @inlinable
    public init(
        isPresented: Bool,
        dismiss: @MainActor @escaping (Transaction) -> Void
    ) {
        self.isPresented = isPresented
        self.dismissBlock = { count, transaction in
            assert(count == 1, "custom PresentationCoordinator only supports dismissing one view at a time")
            dismiss(transaction)
        }
    }

    @inlinable
    init(
        isPresented: Bool,
        sourceView: UIView?,
        dismissBlock: @MainActor @escaping (Int, Transaction) -> Void
    ) {
        self.isPresented = isPresented
        self.sourceView = sourceView
        self.dismissBlock = dismissBlock
    }

    /// Dismisses all presented views with an optional animation
    @MainActor
    @inlinable
    public func dismissToRoot(animation: Animation? = .default) {
        dismiss(count: .max, transaction: Transaction(animation: animation))
    }

    /// Dismisses all presented views with the transaction
    @MainActor
    @inlinable
    public func dismissToRoot(transaction: Transaction) {
        dismiss(count: .max, transaction: transaction)
    }

    /// Dismisses the presented view with an optional animation
    @MainActor
    @inlinable
    public func dismiss(animation: Animation? = .default) {
        dismiss(count: 1, transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented view with the transaction
    @MainActor
    @inlinable
    public func dismiss(transaction: Transaction) {
        dismiss(count: 1, transaction: transaction)
    }

    /// Dismisses the presented views with an optional animation
    @MainActor
    @inlinable
    public func dismiss(count: Int, animation: Animation? = .default) {
        dismiss(count: count, transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented views with the transaction
    @MainActor
    @inlinable
    public func dismiss(count: Int, transaction: Transaction) {
        dismissBlock(count, transaction)
    }
}

@available(iOS 14.0, *)
enum PresentationCoordinatorKey: EnvironmentKey {
    static let defaultValue: PresentationCoordinator? = nil
}

@available(iOS 14.0, *)
extension EnvironmentValues {

    /// A coordinator that can be used to programatically dismiss a view
    ///
    /// If a `PresentationLink` or `WindowLink` was not used to present
    /// the view, a coordinator will be created that wraps SwiftUI's `DismissAction`.
    ///
    public var presentationCoordinator: PresentationCoordinator {
        get {
            if let coordinator = self[PresentationCoordinatorKey.self] {
                return coordinator
            }
            if #available(iOS 15.0, *) {
                let dismissAction = dismiss
                return PresentationCoordinator(
                    isPresented: isPresented,
                    dismiss: { transaction in
                        withTransaction(transaction) {
                            dismissAction()
                        }
                    }
                )
            } else {
                return PresentationCoordinator(
                    isPresented: false,
                    dismiss: { _ in }
                )
            }
        }
        set { self[PresentationCoordinatorKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
struct PresentationBridgeAdapter: ViewModifier {
    var presentationCoordinator: PresentationCoordinator
    @EnvironmentOrValue(\.colorScheme) var colorScheme: ColorScheme

    init(
        presentationCoordinator: PresentationCoordinator
    ) {
        self.presentationCoordinator = presentationCoordinator
        self._colorScheme = .init(\.colorScheme)
    }

    init(
        presentationCoordinator: PresentationCoordinator,
        colorScheme: ColorScheme
    ) {
        self.presentationCoordinator = presentationCoordinator
        self._colorScheme = .init(colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .modifier(_ViewInputsBridgeModifier())
            .environment(\.presentationCoordinator, presentationCoordinator)
            .environment(\.colorScheme, colorScheme)
    }
}

#endif
