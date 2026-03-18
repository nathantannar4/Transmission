//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A button that's action dismisses the presented view.
///
/// Compatible with ``PresentationLink`` and ``WindowLink``.
///
/// > Note: The button is disabled if there is no presented view
/// 
@available(iOS 14.0, *)
@frozen
public struct DismissPresentationLink<Label: View>: View {

    var count: Int
    var animation: Animation?
    var label: Label
    var onDismiss: (() -> Void)?

    @Environment(\.presentationCoordinator) var presentationCoordinator

    public init(
        count: Int = 1,
        animation: Animation? = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.count = count
        self.animation = animation
        self.label = label()
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Button {
            onDismiss?()
            presentationCoordinator.dismiss(count: count, animation: animation)
        } label: {
            label
        }
        .disabled(!presentationCoordinator.isPresented)
    }
}

#endif
