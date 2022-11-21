//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A wrapper for a `UIViewController`
public struct _ViewControllerRepresentableAdapter<
    Content: UIViewController
>: UIViewControllerRepresentable {

    var _makeUIViewController: () -> Content

    public init(makeUIViewController: @escaping () -> Content) {
        self._makeUIViewController = makeUIViewController
    }

    public func makeUIViewController(context: Context) -> Content {
        _makeUIViewController()
    }

    public func updateUIViewController(_ uiViewController: Content, context: Context) { }
}

// MARK: - Previews

struct _ViewControllerRepresentableAdapter_Previews: PreviewProvider {
    static var previews: some View {
        _ViewControllerRepresentableAdapter {
            let uiViewController = UIViewController()
            uiViewController.view.backgroundColor = .yellow
            uiViewController.preferredContentSize = CGSize(width: 40, height: 40)
            return uiViewController
        }
        .fixedSize()

        _ViewControllerRepresentableAdapter {
            let uiViewController = UIViewController()
            uiViewController.view.backgroundColor = .yellow
            return uiViewController
        }
    }
}

#endif
