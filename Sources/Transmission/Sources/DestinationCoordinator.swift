//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A coordinator that can be used to programatically dismiss a view.
///
/// See Also:
///  - ``DestinationLink``
///
@available(iOS 14.0, *)
@frozen
public struct DestinationCoordinator {
    public var isPresented: Bool

    public weak var sourceView: UIView?

    @usableFromInline
    var dismissBlock: (Int, Transaction) -> Void

    @inlinable
    public init(
        isPresented: Bool,
        dismiss: @escaping (Transaction) -> Void
    ) {
        self.isPresented = isPresented
        self.dismissBlock = { count, transaction in
            assert(count == 1, "custom DestinationCoordinator only supports dismissing one view at a time")
            dismiss(transaction)
        }
    }

    @inlinable
    init(
        isPresented: Bool,
        sourceView: UIView?,
        dismissBlock: @escaping (Int, Transaction) -> Void
    ) {
        self.isPresented = isPresented
        self.sourceView = sourceView
        self.dismissBlock = dismissBlock
    }

    /// Dismisses all presented views with an optional animation
    @inlinable
    public func popToRoot(animation: Animation? = .default) {
        pop(count: .max, animation: animation)
    }

    /// Dismisses all presented views with the transaction
    @inlinable
    public func popToRoot(transaction: Transaction) {
        pop(count: .max, transaction: transaction)
    }

    /// Dismisses the presented view with an optional animation
    @inlinable
    public func pop(animation: Animation? = .default) {
        pop(count: 1, animation: animation)
    }

    /// Dismisses the presented view with the transaction
    @inlinable
    public func pop(transaction: Transaction) {
        pop(count: 1, transaction: transaction)
    }

    /// Dismisses the presented view with an optional animation
    @inlinable
    public func pop(count: Int, animation: Animation? = .default) {
        pop(count: count, transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented view with the transaction
    @inlinable
    public func pop(count: Int, transaction: Transaction) {
        dismissBlock(count, transaction)
    }
}

@available(iOS 14.0, *)
enum DestinationCoordinatorKey: EnvironmentKey {
    static let defaultValue: DestinationCoordinator? = nil
}

@available(iOS 14.0, *)
extension EnvironmentValues {

    /// A coordinator that can be used to programatically dismiss a view
    public var destinationCoordinator: DestinationCoordinator {
        get {
            if let coordinator = self[DestinationCoordinatorKey.self] {
                return coordinator
            }
            if #available(iOS 15.0, *) {
                let dismissAction = dismiss
                return DestinationCoordinator(
                    isPresented: isPresented,
                    dismiss: { transaction in
                        withTransaction(transaction) {
                            dismissAction()
                        }
                    }
                )
            } else {
                let presentationMode = presentationMode
                return DestinationCoordinator(
                    isPresented: presentationMode.wrappedValue.isPresented,
                    dismiss: { transaction in
                        withTransaction(transaction) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
        set { self[DestinationCoordinatorKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
struct DestinationBridgeAdapter: ViewModifier {
    var destinationCoordinator: DestinationCoordinator
    @State var didAppear = false

    func body(content: Content) -> some View {
        content
            .modifier(_ViewInputsBridgeModifier())
            .environment(\.destinationCoordinator, destinationCoordinator)
            .onAppear {
                // Need to trigger a render update during presentation to fix DatePicker
                withCATransaction {
                    didAppear = true
                }
            }
    }
}

#endif
