//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
extension EnvironmentValues {

    public var inputAccessoryView: UIView? {
        get { self[InputAccessoryViewKey.self]?.view }
        set { self[InputAccessoryViewKey.self] = newValue.map { InputAccessoryViewKeyValue(view: $0) } }
    }
}

@available(iOS 14.0, *)
public struct InputAccessoryViewModifier<InputAccessoryView: View>: ViewModifier {

    var inputAccessoryView: InputAccessoryView

    @State private var hostingView: InputView<InputAccessoryView>
    @UpdatePhase private var phase

    public init(inputAccessoryView: InputAccessoryView) {
        self.inputAccessoryView = inputAccessoryView
        self._hostingView = State(
            wrappedValue: InputView(
                content: inputAccessoryView
            )
        )
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.inputAccessoryView, hostingView)
            .onChange(of: phase) { _ in
                hostingView.update(content: inputAccessoryView, transaction: Transaction(animation: .default))
            }
    }
}

@available(iOS 14.0, *)
extension View {

    public func inputAccessoryView<InputAccessoryView: View>(
        @ViewBuilder inputAccessoryView: () -> InputAccessoryView
    ) -> some View {
        modifier(InputAccessoryViewModifier(inputAccessoryView: inputAccessoryView()))
    }
}

@available(iOS 14.0, *)
struct InputAccessoryViewKey: EnvironmentKey {
    static let defaultValue: InputAccessoryViewKeyValue? = nil
}

@available(iOS 14.0, *)
struct InputAccessoryViewKeyValue: Equatable {
    weak var view: UIView?
}

public struct InputAccessoryRootView<Content: View>: View {

    var content: Content

    public var body: some View {
        content
    }
}

@available(iOS 14.0, *)
open class InputHostingView<Content: View>: HostingView<InputAccessoryRootView<Content>> {

    public init(content: Content) {
        super.init(content: InputAccessoryRootView(content: content))
        isHitTestingPassthrough = true
        invalidatesIntrinsicContentSizeOnIdealSizeChange = true
        automaticallyLayoutIntrinsicContentSizeChange = false
        disablesSafeArea = true
    }

    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(content: Content, transaction: Transaction) {
        update(content: InputAccessoryRootView(content: content), transaction: transaction)
    }
}

@available(iOS 14.0, *)
open class InputView<Content: View>: UIInputView {

    public var content: Content {
        get { hostingView.content.content }
        set { hostingView.content.content = newValue }
    }

    private let hostingView: InputHostingView<Content>

    public init(content: Content) {
        self.hostingView = InputHostingView(content: content)
        super.init(frame: .zero, inputViewStyle: .keyboard)
        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hostingView)
        allowsSelfSizing = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(content: Content, transaction: Transaction) {
        hostingView.update(content: content, transaction: transaction)
    }

    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        guard let view = UIResponder._current as? UIView else { return }
        view.reloadInputViews()
    }

    open override var intrinsicContentSize: CGSize {
        let size = hostingView.intrinsicContentSize
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct InputAccessoryViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var text = ""

        var body: some View {
            ScrollView {
                SinglelineTextField("Placeholder", text: $text)

                MultilineTextField("Placeholder", text: $text)
            }
            .background {
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
            }
            .inputAccessoryView {
                InputAccessoryView()
            }
        }

        struct InputAccessoryView: View {
            @State var flag = false
            var body: some View {
                Color.blue
                    .frame(height: flag ? 88 : 44)
                    .onTapGesture {
                        flag.toggle()
                    }
            }
        }
    }
}

#endif
