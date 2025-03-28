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
public struct PresentationCoordinator {
    public var isPresented: Bool

    public weak var sourceView: UIView?

    @usableFromInline
    var dismissBlock: (Int, Transaction) -> Void

    /// Dismisses all presented views with an optional animation
    @inlinable
    public func dismissToRoot(animation: Animation? = .default) {
        dismiss(count: .max, transaction: Transaction(animation: animation))
    }

    /// Dismisses all presented views with the transaction
    @inlinable
    public func dismissToRoot(transaction: Transaction) {
        dismiss(count: .max, transaction: transaction)
    }

    /// Dismisses the presented view with an optional animation
    @inlinable
    public func dismiss(animation: Animation? = .default) {
        dismiss(count: 1, transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented view with the transaction
    @inlinable
    public func dismiss(transaction: Transaction) {
        dismiss(count: 1, transaction: transaction)
    }

    /// Dismisses the presented views with an optional animation
    @inlinable
    public func dismiss(count: Int, animation: Animation? = .default) {
        dismiss(count: count, transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented views with the transaction
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
                    dismissBlock: { _, transaction in
                        withTransaction(transaction) {
                            dismissAction()
                        }
                    }
                )
            } else {
                let presentationMode = presentationMode
                return PresentationCoordinator(
                    isPresented: presentationMode.wrappedValue.isPresented,
                    dismissBlock: { _, transaction in
                        withTransaction(transaction) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
        set { self[PresentationCoordinatorKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
struct PresentationBridgeAdapter: ViewModifier {
    var presentationCoordinator: PresentationCoordinator
    @State var didAppear = false

    func body(content: Content) -> some View {
        content
            .modifier(_ViewInputsBridgeModifier())
            .environment(\.presentationCoordinator, presentationCoordinator)
            .onAppear {
                // Need to trigger a render update during presentation to fix DatePicker
                withCATransaction {
                    didAppear = true
                }
            }
    }
}

#endif
