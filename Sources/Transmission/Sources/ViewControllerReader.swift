//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
public struct ViewControllerReaderAdapter<Content: View>: View {

    let content: (UIViewController?) -> Content

    @State var presentingViewController = ObjCWeakBox<UIViewController>(value: nil)

    public init(
        @ViewBuilder content: @escaping (UIViewController?) -> Content
    ) {
        self.content = content
    }

    public var body: some View {
        content(presentingViewController.value)
            .background(
                ViewControllerReaderAdapterBody(
                    presentingViewController: $presentingViewController
                )
            )
    }
}

private struct ViewControllerReaderAdapterBody: UIViewRepresentable {
    var presentingViewController: Binding<ObjCWeakBox<UIViewController>>

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(presentingViewController: presentingViewController)
    }

    class Coordinator: ViewControllerReaderDelegate {
        var presentingViewController: Binding<ObjCWeakBox<UIViewController>>

        init(presentingViewController: Binding<ObjCWeakBox<UIViewController>>) {
            self.presentingViewController = presentingViewController
        }

        func viewControllerReaderDidMoveToWindow(_ view: UIView) {
            guard presentingViewController.wrappedValue.value == nil else { return }
            presentingViewController.wrappedValue = ObjCWeakBox(value: view.viewController)
        }
    }
}

protocol ViewControllerReaderDelegate: AnyObject {

    @MainActor @preconcurrency func viewControllerReaderDidMoveToWindow(_ view: UIView)
}

class ViewControllerReader: UIView {

    weak var delegate: ViewControllerReaderDelegate?

    init() {
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
        delegate?.viewControllerReaderDidMoveToWindow(self)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct ViewControllerReaderAdapter_Previews: PreviewProvider {

    class PreviewHostingController<Content: View>: HostingController<Content> {
        deinit {
            print("deinit PreviewHostingController")
        }
    }

    struct Preview: View {
        var body: some View {
            ViewControllerReaderAdapter { viewController in
                VStack {
                    Text(viewController?.description ?? "nil")

                    Button { [weak viewController] in
                        let hostingController = PreviewHostingController(content: Preview())
                        viewController?.present(hostingController, animated: true)
                    } label: {
                        Text("Present")
                    }
                }
            }
        }
    }

    static var previews: some View {
        ZStack {
            Preview()
        }
    }
}

#endif
