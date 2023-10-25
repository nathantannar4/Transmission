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
///  - ``PresentationLink``
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct PresentationCoordinator {
    public var isPresented: Bool

    public weak var sourceView: UIView?

    @usableFromInline
    var dismissBlock: () -> Void

    public init(isPresented: Bool, sourceView: UIView? = nil, dismissBlock: @escaping () -> Void) {
        self.isPresented = isPresented
        self.sourceView = sourceView
        self.dismissBlock = dismissBlock
    }

    /// Dismisses the presented view with an optional animation
    @inlinable
    public func dismiss(animation: Animation? = .default) {
        dismiss(transaction: Transaction(animation: animation))
    }

    /// Dismisses the presented view with the transaction
    @inlinable
    public func dismiss(transaction: Transaction) {
        PresentationCoordinator.transaction = transaction
        withTransaction(transaction, dismissBlock)
    }

    @usableFromInline
    static var transaction: Transaction?
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
enum PresentationCoordinatorKey: EnvironmentKey {
    static let defaultValue: PresentationCoordinator? = nil
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
    public var presentationCoordinator: PresentationCoordinator {
        get {
            if let coordinator = self[PresentationCoordinatorKey.self] {
                return coordinator
            }
            if #available(iOS 15.0, *) {
                return PresentationCoordinator(
                    isPresented: isPresented,
                    dismissBlock: dismiss.callAsFunction
                )
            } else {
                let presentationMode = presentationMode
                return PresentationCoordinator(
                    isPresented: presentationMode.wrappedValue.isPresented
                ) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        set { self[PresentationCoordinatorKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PresentationBridgeAdapter: ViewModifier {
    var isPresented: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .modifier(_ViewInputsBridgeModifier())
            .environment(
                \.presentationCoordinator,
                 PresentationCoordinator(
                    isPresented: isPresented.wrappedValue,
                    dismissBlock: {
                        isPresented.wrappedValue = false
                    })
            )
    }
}

#endif
