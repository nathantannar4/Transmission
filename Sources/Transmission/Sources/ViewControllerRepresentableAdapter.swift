//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A wrapper for a `UIViewController`
public struct ViewControllerRepresentableAdapter<
    Content: UIViewController
>: UIViewControllerRepresentable {

    var _makeUIViewController: (Context) -> Content

    public init(makeUIViewController: @escaping (Context) -> Content) {
        self._makeUIViewController = makeUIViewController
    }

    public func makeUIViewController(context: Context) -> Content {
        _makeUIViewController(context)
    }

    public func updateUIViewController(_ uiViewController: Content, context: Context) { }
}

#endif
