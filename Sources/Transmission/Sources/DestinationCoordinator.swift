//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Turbocharger

/// A coordinator that can be used to programatically dismiss a view.
///
/// See Also:
///  - ``DestinationLink``
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct DestinationCoordinator {
    public var isPresented: Bool

    @usableFromInline
    var dismissBlock: () -> Void

    /// Dismisses the presented view with an optional animation
    @inlinable
    public func pop(animation: Animation? = .default) {
        pop(transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented view with the transaction
    @inlinable
    public func pop(transaction: Transaction) {
        DestinationCoordinator.transaction = transaction
        withTransaction(transaction, dismissBlock)
    }

    @usableFromInline
    static var transaction: Transaction?
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
enum DestinationCoordinatorKey: EnvironmentKey {
    static let defaultValue: DestinationCoordinator? = nil
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension EnvironmentValues {

    /// A coordinator that can be used to programatically dismiss a view
    ///
    /// If a `PresentationLink` or `WindowLink` was not used to present
    /// the view, a coordinator will be created that wraps SwiftUI's `DismissAction`.
    ///
    public var destinationCoordinator: DestinationCoordinator {
        get {
            if let coordinator = self[DestinationCoordinatorKey.self] {
                return coordinator
            }
            if #available(iOS 15.0, *) {
                return DestinationCoordinator(
                    isPresented: isPresented,
                    dismissBlock: dismiss.callAsFunction
                )
            } else {
                let presentationMode = presentationMode
                return DestinationCoordinator(
                    isPresented: presentationMode.wrappedValue.isPresented
                ) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        set { self[DestinationCoordinatorKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DestinationBridgeAdapter: ViewModifier {
    var isPresented: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .modifier(_ViewInputsBridgeModifier())
            .environment(
                \.destinationCoordinator,
                 DestinationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    dismissBlock: {
                        isPresented.wrappedValue = false
                    })
            )
    }
}

#endif
