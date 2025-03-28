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

    var animation: Animation?
    var label: Label

    @Environment(\.presentationCoordinator) var presentationCoordinator

    public init(
        animation: Animation? = .default,
        @ViewBuilder label: () -> Label
    ) {
        self.animation = animation
        self.label = label()
    }

    public var body: some View {
        Button {
            presentationCoordinator.dismiss(animation: animation)
        } label: {
            label
        }
        .disabled(!presentationCoordinator.isPresented)
    }
}

#endif
