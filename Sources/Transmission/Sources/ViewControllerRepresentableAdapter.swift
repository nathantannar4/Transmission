//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A wrapper for a `UIViewController`
@frozen
public struct ViewControllerRepresentableAdapter<
    Content: UIViewController
>: UIViewControllerRepresentable {

    @usableFromInline
    var _makeUIViewController: (Context) -> Content

    @inlinable
    public init(_ makeUIViewController: @escaping () -> Content) {
        self._makeUIViewController = { _ in makeUIViewController() }
    }

    @inlinable
    public init(_ makeUIViewController: @escaping (Context) -> Content) {
        self._makeUIViewController = makeUIViewController
    }

    public func makeUIViewController(context: Context) -> Content {
        _makeUIViewController(context)
    }

    public func updateUIViewController(_ uiViewController: Content, context: Context) { }
}

#endif
