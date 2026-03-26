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
            presentingViewController: presentingViewController
        )
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) { }
}

class ViewControllerReader: UIView {

    let presentingViewController: Binding<UIViewController?>

    init(presentingViewController: Binding<UIViewController?>) {
        self.presentingViewController = presentingViewController
        super.init(frame: .zero)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return size
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard presentingViewController.wrappedValue == nil else { return }
        let viewController = viewController
        withCATransaction { [presentingViewController] in
            presentingViewController.wrappedValue = viewController
        }
    }
}

#endif
