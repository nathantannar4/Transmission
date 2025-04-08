//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
public struct ViewControllerReaderAdapter<Content: View>: View {

    let content: (UIViewController?) -> Content

    @WeakState var presentingViewController: UIViewController?

    public init(
        @ViewBuilder content: @escaping (UIViewController?) -> Content
    ) {
        self.content = content
    }

    public var body: some View {
        content(presentingViewController)
            .background(ViewControllerReaderAdapterBody(presentingViewController: $presentingViewController))
    }
}

private struct ViewControllerReaderAdapterBody: UIViewRepresentable {
    var presentingViewController: Binding<UIViewController?>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader(
            onDidMoveToWindow: { viewController in
                withCATransaction {
                    presentingViewController.wrappedValue = viewController
                }
            }
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) { }
}


#endif
