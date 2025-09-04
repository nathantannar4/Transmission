//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A wrapper for a `UIView`
@frozen
public struct ViewRepresentableAdapter<
    Content: UIView
>: UIViewRepresentable {

    @usableFromInline
    var _makeUIView: (Context) -> Content

    @inlinable
    public init(_ makeUIView: @escaping () -> Content) {
        self._makeUIView = { _ in makeUIView() }
    }

    @inlinable
    public init(_ makeUIView: @escaping (Context) -> Content) {
        self._makeUIView = makeUIView
    }

    public func makeUIView(context: Context) -> Content {
        _makeUIView(context)
    }

    public func updateUIView(_ uiView: Content, context: Context) { }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        let sizeThatFits = uiView.sizeThatFits(ProposedSize(proposedSize).replacingUnspecifiedDimensions(by: UIView.layoutFittingExpandedSize))
        if sizeThatFits != .zero {
            size = sizeThatFits
        }
    }
}

#endif
