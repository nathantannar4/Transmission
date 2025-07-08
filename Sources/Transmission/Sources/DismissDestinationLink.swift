//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A button that's action dismisses the presented view.
///
/// Compatible with ``DestinationLink``.
///
/// > Note: The button is disabled if there is no presented view
/// 
@available(iOS 14.0, *)
@frozen
public struct DismissDestinationLink<Label: View>: View {

    var animation: Animation?
    var label: Label
    var onDismiss: (() -> Void)?

    @Environment(\.destinationCoordinator) var destinationCoordinator

    public init(
        animation: Animation? = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.animation = animation
        self.label = label()
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Button {
            onDismiss?()
            destinationCoordinator.pop(animation: animation)
        } label: {
            label
        }
        .disabled(!destinationCoordinator.isPresented)
    }
}

#endif
