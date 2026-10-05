//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Playgrounds

@available(iOS 14.0, *)
public struct SinglelineTextField: View {

    var placeholder: Text?
    var text: Binding<String>
    var isFormatted: Bool
    var isFirstResponder: FirstResponderState<Bool>.Binding? = nil

    public init(
        _ placeholder: Text? = nil,
        text: Binding<String>,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isFormatted = false
        self.isFirstResponder = isFirstResponder
    }

    public init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) {
        self.init(Text(placeholder), text: text, isFirstResponder: isFirstResponder)
    }

    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ placeholder: S?,
        text: Binding<String>,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) {
        self.init(Text(placeholder), text: text, isFirstResponder: isFirstResponder)
    }

    @available(iOS 15.0, *)
    public init<F>(
        _ placeholder: Text? = nil,
        value: Binding<F.FormatInput>,
        format: F,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) where F: ParseableFormatStyle, F.FormatInput: Hashable, F.FormatOutput == String {
        self.placeholder = placeholder
        self.text = value.format(format)
        self.isFormatted = true
        self.isFirstResponder = isFirstResponder
    }

    @available(iOS 15.0, *)
    public init<F>(
        _ placeholder: LocalizedStringKey,
        value: Binding<F.FormatInput>,
        format: F,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) where F: ParseableFormatStyle, F.FormatInput: Hashable, F.FormatOutput == String {
        self.init(Text(placeholder), value: value, format: format, isFirstResponder: isFirstResponder)
    }

    @available(iOS 15.0, *)
    public init<S: StringProtocol, F>(
        _ placeholder: S?,
        value: Binding<F.FormatInput>,
        format: F,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) where F: ParseableFormatStyle, F.FormatInput: Hashable, F.FormatOutput == String {
        self.init(Text(placeholder), value: value, format: format, isFirstResponder: isFirstResponder)
    }

    @available(iOS 15.0, *)
    public init<V: Hashable, F>(
        _ placeholder: Text? = nil,
        value: Binding<V?>,
        format: F,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) where F: ParseableFormatStyle, F.FormatOutput == String, F.FormatInput == V {
        self.placeholder = placeholder
        self.text = value.format(format, defaultValue: "")
        self.isFormatted = true
        self.isFirstResponder = isFirstResponder
    }

    @available(iOS 15.0, *)
    public init<V: Hashable, F>(
        _ placeholder: LocalizedStringKey,
        value: Binding<V?>,
        format: F,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) where F: ParseableFormatStyle, F.FormatOutput == String, F.FormatInput == V {
        self.init(Text(placeholder), value: value, format: format, isFirstResponder: isFirstResponder)
    }

    @available(iOS 15.0, *)
    public init<S: StringProtocol, V: Hashable, F>(
        _ placeholder: S?,
        value: Binding<V?>,
        format: F,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) where F: ParseableFormatStyle, F.FormatOutput == String, F.FormatInput == V {
        self.init(Text(placeholder), value: value, format: format, isFirstResponder: isFirstResponder)
    }

    public var body: some View {
        SinglelineTextFieldBody(
            placeholder: placeholder,
            text: text,
            isFormatted: isFormatted,
            isFirstResponder: isFirstResponder
        )
    }
}

@available(iOS 14.0, *)
private struct SinglelineTextFieldBody: UIViewRepresentable {

    var placeholder: Text?
    var text: Binding<String>
    var isFormatted: Bool
    var isFirstResponder: FirstResponderState<Bool>.Binding? = nil

    typealias UIViewType = SinglelineTextFieldPlatformView

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        uiView.delegate = context.coordinator
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textFieldDidChange),
            name: UITextField.textDidChangeNotification,
            object: uiView
        )

        uiView.clipsToBounds = false
        uiView.backgroundColor = nil
        uiView.contentVerticalAlignment = .center
        uiView.inputAccessoryView = context.environment.inputAccessoryView
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

        context.coordinator.onSubmit = context.environment.submit
        context.coordinator.text = text

        let font = context.environment.font?.toUIFont(in: context.environment)
            ?? .preferredFont(forTextStyle: .body, compatibleWith: context.environment.traitCollectionForFontResolution())
        let textColor = context.environment.foregroundColor?.toUIColor()
        let tintColor = context.environment.tintColor?.toUIColor()
        uiView.font = font
        uiView.textColor = textColor
        uiView.tintColor = tintColor

        uiView.minimumFontSize = (context.environment.minimumScaleFactor * font.pointSize).rounded()
        uiView.adjustsFontSizeToFitWidth = context.environment.minimumScaleFactor < 1
        if #available(iOS 15.0, *) {
            uiView.minimumContentSizeCategory = UIContentSizeCategory(context.environment.allowedDynamicTypeSize.lowerBound)
            uiView.maximumContentSizeCategory = UIContentSizeCategory(context.environment.allowedDynamicTypeSize.upperBound)
        }

        let textContentType = context.environment.textContentType
        uiView.textContentType = textContentType
        let isSecureTextEntry = textContentType == .password || textContentType == .newPassword
        uiView.isSecureTextEntry = isSecureTextEntry
        uiView.keyboardType = context.environment.keyboardType
        let autocorrectionDisabled = context.environment.autocorrectionDisabled
        uiView.autocorrectionType = autocorrectionDisabled ? .no : .default
        uiView.spellCheckingType = autocorrectionDisabled ? .no : .default
        uiView.autocapitalizationType = context.environment.autocapitalizationType ?? .sentences
        let returnKeyType = context.environment.returnKeyType ?? (context.coordinator.onSubmit != nil ? .done : .default)
        uiView.returnKeyType = returnKeyType

        uiView.clearsOnBeginEditing = isFormatted || isSecureTextEntry
        let textAlignment = context.environment.multilineTextAlignment
        uiView.clearButtonMode = textAlignment == .leading && (isFormatted || textContentType != nil) ? .whileEditing : .never

        let alignment = NSTextAlignment(
            alignment: textAlignment,
            layoutDirection: context.environment.layoutDirection
        )
        uiView.textAlignment = alignment

        if let placeholder {
            if placeholder.isAttributed {
                uiView.placeholder = nil
                uiView.attributedPlaceholder = placeholder.resolveAttributed(in: context.environment)
            } else {
                uiView.attributedPlaceholder = nil
                uiView.placeholder = placeholder.resolve(in: context.environment)
            }
        } else {
            uiView.placeholder = nil
            uiView.attributedPlaceholder = nil
        }

        uiView.setTextPreservingSelection(text.wrappedValue, isFormatted: isFormatted)

        isFirstResponder?.updateUIResponder(
            uiView,
            transitionCoordinator: {
                let viewController = context.environment.hostingController ?? uiView._viewController
                return viewController?._transitionCoordinator
            }(),
            isAttaching: context.coordinator.isFirstResponder == nil
        )
        context.coordinator.isFirstResponder = isFirstResponder
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        if uiView.isFirstResponder, !uiView.resignFirstResponder() {
            coordinator.isFirstResponder?.wrappedValue = false
        }
    }

    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIViewType,
        context: Context
    ) -> CGSize? {
        return uiView.sizeThatFits(ProposedSize(proposal))
    }

    func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize))
    }

    final class SinglelineTextFieldPlatformView: UITextField {

        override var intrinsicContentSize: CGSize {
            var intrinsicContentSize = super.intrinsicContentSize
            if let font {
                intrinsicContentSize.height -= font.leading
            }
            return intrinsicContentSize
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var sizeThatFits = super.sizeThatFits(size)
            if let font {
                sizeThatFits.height -= font.leading
            }
            return sizeThatFits
        }

        func sizeThatFits(_ proposal: ProposedSize) -> CGSize {
            let fittingSize = proposal
                .replacingUnspecifiedDimensions(
                    by: CGSize(
                        width: CGFloat.infinity,
                        height: CGFloat.infinity
                    )
                )
            var size = sizeThatFits(fittingSize)
            if let width = proposal.width {
                size.width = width
            }
            return size
        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let isInside = super.point(inside: point, with: event)
            return isInside || bounds.insetBy(dx: -4, dy: -4).contains(point)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var onSubmit: SubmitAction?
        var isFirstResponder: FirstResponderState<Bool>.Binding?

        init(text: Binding<String>) {
            self.text = text
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFirstResponder?.didBecomeFirstResponder(textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            textField.text = text.wrappedValue
            isFirstResponder?.didResignFirstResponder(textField)
        }

        @objc
        func textFieldDidChange(_ notification: Notification) {
            text.wrappedValue = (notification.object as? UITextField)?.text ?? ""
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            if string == "\n", textFieldShouldReturn(textField) {
                return false
            }
            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let didResign = textField.resignFirstResponder()
            if didResign {
                onSubmit?()
            }
            return didResign
        }
    }
}

@available(iOS 14.0, *)
struct SinglelineTextField_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var textA = ""
        @State var textB = "Lorem ipsum"
        @State var textC = "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat."
        @State var isAttributedPlaceholder = false
        @State var number = 1000

        var body: some View {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 48) {
                    Toggle(isOn: $isAttributedPlaceholder) {
                        Text("isAttributedPlaceholder")
                    }
                    let placeholder = isAttributedPlaceholder ? Text("Attributed Placeholder").font(.title.bold()) : Text("Placeholder")

                    placeholder
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .withDebugOverlay(label: "Text", color: .yellow)
                    
                    SinglelineTextField(
                        placeholder,
                        text: $textA,
                        isFirstResponder: .automatic
                    )
                    .inputAccessoryView {
                        HStack {
                            Button {
                                let keyWindow = UIApplication.shared.connectedScenes
                                    .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                                    .first(where: { $0.isKeyWindow })
                                keyWindow?.endEditing(true)
                            } label: {
                                Text("Done")
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue.ignoresSafeArea())
                    }
                    .withDebugOverlay(label: "TextField", color: .blue)
                }
                .padding(.vertical, 24)

                if #available(iOS 15.0, *) {
                    SinglelineTextField(
                        Text("Placeholder"),
                        value: $number,
                        format: .number
                    )
                }

                SinglelineTextField(
                    Text("Placeholder").foregroundColor(.blue).font(.title),
                    text: $textA
                )

                SinglelineTextField(
                    Text("Placeholder").foregroundColor(.blue).font(.caption),
                    text: $textA
                )

                SinglelineTextField(
                    "Placeholder",
                    text: $textA
                )
                .multilineTextAlignment(.center)

                SinglelineTextField(
                    "Placeholder",
                    text: $textA
                )
                .multilineTextAlignment(.trailing)

                SinglelineTextField(
                    "Placeholder",
                    text: $textB
                )

                VStack(alignment: .center) {
                    SinglelineTextField(
                        "Placeholder",
                        text: $textA
                    )

                    SinglelineTextField(
                        "Placeholder",
                        text: $textB
                    )
                }
                .environment(\.layoutDirection, .rightToLeft)

                SinglelineTextField(
                    "Placeholder",
                    text: $textB
                )
                .font(.headline)
                .foregroundColor(.blue)

                SinglelineTextField(
                    "Placeholder",
                    text: $textB
                )
                .textContentType(.password)

                if #available(iOS 15.0, *) {
                    SinglelineTextField(
                        "Placeholder",
                        text: $textB
                    )
                    .dynamicTypeSize(.accessibility1)
                }

                SinglelineTextField(
                    "Placeholder",
                    text: $textC
                )

                SinglelineTextField(
                    "Placeholder",
                    text: $textC
                )
                .minimumScaleFactor(0.5)
            }
        }
    }
}

#endif
