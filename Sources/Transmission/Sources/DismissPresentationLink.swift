//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A button that's action dismisses the presented view.
///
/// > Note: The button is disabled if there is no presented view
/// 
@available(iOS 14.0, *)
@frozen
public struct DismissPresentationLink<Label: View>: View {

    var label: Label

    @Environment(\.presentationCoordinator) var presentationCoordinator

    public init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }

    public var body: some View {
        Button {
            presentationCoordinator.dismiss(animation: .default)
        } label: {
            label
        }
        .disabled(!presentationCoordinator.isPresented)
    }
}

#endif
