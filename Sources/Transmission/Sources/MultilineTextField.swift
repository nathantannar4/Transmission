//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct MultilineTextField: View {

    var placeholder: Text?
    var text: Binding<String>
    var isScrollEnabled: Bool
    var isFirstResponder: FirstResponderState<Bool>.Binding? = nil

    public init(
        _ placeholder: Text? = nil,
        text: Binding<String>,
        isScrollEnabled: Bool = false,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isScrollEnabled = isScrollEnabled
        self.isFirstResponder = isFirstResponder
    }

    public init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        isScrollEnabled: Bool = false,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) {
        self.init(
            Text(placeholder),
            text: text,
            isScrollEnabled: isScrollEnabled,
            isFirstResponder: isFirstResponder
        )
    }

    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ placeholder: S?,
        text: Binding<String>,
        isScrollEnabled: Bool = false,
        isFirstResponder: FirstResponderState<Bool>.Binding? = nil
    ) {
        self.init(
            Text(placeholder),
            text: text,
            isScrollEnabled: isScrollEnabled,
            isFirstResponder: isFirstResponder
        )
    }

    public var body: some View {
        MultilineTextFieldBody(
            placeholder: placeholder,
            text: text,
            isScrollEnabled: isScrollEnabled,
            isFirstResponder: isFirstResponder
        )
    }
}

@available(iOS 14.0, *)
private struct MultilineTextFieldBody: UIViewRepresentable {

    var placeholder: Text?
    var text: Binding<String>
    var isScrollEnabled: Bool
    var isFirstResponder: FirstResponderState<Bool>.Binding? = nil

    typealias UIViewType = MultilineTextFieldPlatformView

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        uiView.delegate = context.coordinator
        uiView.textContainerInset = .zero
        uiView.textContainer.lineFragmentPadding = 0
        uiView.keyboardDismissMode = .interactive
        uiView.clipsToBounds = false
        uiView.backgroundColor = nil
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

        uiView.isScrollEnabled = isScrollEnabled
        uiView.contentInsetAdjustmentBehavior = isScrollEnabled ? .always : .never
        if #available(iOS 16.0, *), let textLayoutManager = uiView.textLayoutManager {
            textLayoutManager.usesFontLeading = isScrollEnabled
        } else {
            uiView.layoutManager.usesFontLeading = isScrollEnabled
        }

        uiView.adjustsFontForContentSizeCategory = !isScrollEnabled
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

        if #available(iOS 16.0, *) {
            uiView.lineLimitRange = context.environment.lineLimitRange
        } else if let lineLimit = context.environment.lineLimit {
            uiView.lineLimitRange = 0...lineLimit
        } else {
            uiView.lineLimitRange = nil
        }
        uiView.lineBreakMode = {
            switch context.environment.truncationMode {
            case .head:
                return .byTruncatingHead
            case .middle:
                return .byTruncatingMiddle
            default:
                return .byTruncatingTail
            }
        }()

        let alignment = NSTextAlignment(
            alignment: context.environment.multilineTextAlignment,
            layoutDirection: context.environment.layoutDirection
        )
        uiView.textAlignment = alignment

        var placeholderLineHeight: CGFloat?
        if let placeholder {
            if placeholder.isAttributed {
                let attributedPlaceholder: NSAttributedString = placeholder.resolveAttributed(in: context.environment)
                attributedPlaceholder.enumerateAttribute(
                    .font,
                    in: NSRange(location: 0, length: attributedPlaceholder.length)
                ) { font, _, _ in
                    if let font = font as? UIFont {
                        placeholderLineHeight = max(placeholderLineHeight ?? 0, font.lineHeight)
                    }
                }
                uiView.attributedPlaceholder = attributedPlaceholder
            } else {
                uiView.placeholder = placeholder.resolve(in: context.environment)
            }
        } else {
            uiView.placeholder = nil
        }
        if let placeholderLineHeight, let lineHeight = uiView.font?.lineHeight {
            let dy = placeholderLineHeight - lineHeight
            uiView.textContainerInset.top = dy / 2
            uiView.textContainerInset.bottom = dy / 2
        } else {
            uiView.textContainerInset = .zero
        }

        uiView.setTextPreservingSelection(text.wrappedValue)

        isFirstResponder?.updateUIResponder(
            uiView,
            transitionCoordinator: {
                let viewController = context.environment.hostingController ?? uiView._viewController
                return viewController?.transitionCoordinator
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
        guard !uiView.isScrollEnabled else { return nil }
        return uiView.sizeThatFits(ProposedSize(proposal))
    }

    func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        let proposedSize = ProposedSize(proposedSize)
        let sizeThatFits = uiView.sizeThatFits(proposedSize)
        if uiView.isScrollEnabled {
            if proposedSize.height == nil {
                size.height = max(size.height, sizeThatFits.height)
            }
        } else {
            size = sizeThatFits
        }
    }

    final class MultilineTextFieldPlatformView: UITextView {

        override var text: String! {
            didSet {
                textDidChange()
            }
        }

        var placeholder: String? {
            get { placeholderLabel.text }
            set {
                placeholderLabel.text = newValue
                accessibilityLabel = newValue
            }
        }

        var attributedPlaceholder: NSAttributedString? {
            get { placeholderLabel.attributedText }
            set {
                placeholderLabel.attributedText = newValue
                accessibilityAttributedLabel = newValue
            }
        }

        override var font: UIFont? {
            didSet {
                placeholderLabel.font = font
            }
        }

        override var textAlignment: NSTextAlignment {
            didSet {
                placeholderLabel.textAlignment = textAlignment
            }
        }

        var lineLimitRange: ClosedRange<Int>? {
            didSet {
                textContainer.maximumNumberOfLines = lineLimitRange?.upperBound ?? 0
                placeholderLabel.numberOfLines = lineLimitRange?.upperBound ?? 0
            }
        }

        var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
            didSet {
                textContainer.lineBreakMode = lineBreakMode
                placeholderLabel.lineBreakMode = lineBreakMode
            }
        }

        override var adjustsFontForContentSizeCategory: Bool {
            didSet {
                placeholderLabel.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory
            }
        }

        private let placeholderLabel = UILabel()

        override init(frame: CGRect, textContainer: NSTextContainer?) {
            super.init(frame: frame, textContainer: textContainer)

            placeholderLabel.textColor = .placeholderText
            placeholderLabel.isAccessibilityElement = false
            placeholderLabel.adjustsFontSizeToFitWidth = false
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(placeholderLabel, at: 0)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textDidChange),
                name: UITextView.textDidChangeNotification,
                object: nil
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let placeholderSizeThatFits = placeholderLabel.sizeThatFits(bounds.size)
            placeholderLabel.frame = CGRect(
                x: 0,
                y: max(0, -textContainerInset.top),
                width: bounds.width,
                height: placeholderSizeThatFits.height
            )
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var sizeThatFits = super.sizeThatFits(size)
            let placeholderSize = placeholderLabel.sizeThatFits(size)
            sizeThatFits.height = max(sizeThatFits.height, placeholderSize.height)
            sizeThatFits.width = max(sizeThatFits.width, placeholderSize.width)
            if let minimumNumberOfLines = lineLimitRange?.lowerBound, minimumNumberOfLines > 1, let font {
                let minHeight = CGFloat(minimumNumberOfLines) * font.lineHeight + CGFloat(max(0, minimumNumberOfLines - 1)) * font.leading
                sizeThatFits.height = max(sizeThatFits.height, minHeight)
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

        @objc
        private func textDidChange() {
            placeholderLabel.isHidden = text.map { !$0.isEmpty } ?? true
            if isScrollEnabled {
                invalidateIntrinsicContentSize()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var onSubmit: SubmitAction?
        var isFirstResponder: FirstResponderState<Bool>.Binding? = nil

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFirstResponder?.didBecomeFirstResponder(textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFirstResponder?.didResignFirstResponder(textView)
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText string: String
        ) -> Bool {
            if string == "\n", onSubmit != nil, textViewShouldEndEditing(textView) {
                return false
            }
            return true
        }

        func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
            let didResign = textView.resignFirstResponder()
            if didResign {
                onSubmit?()
            }
            return didResign
        }

        func textView(
            _ textView: UITextView,
            shouldInteractWith URL: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            return false
        }
    }
}

@available(iOS 14.0, *)
struct MultilineTextField_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
        ZStack {
            MultilineTextField(
                "Placeholder",
                text: .constant(""),
                isScrollEnabled: true
            )
            .ignoresSafeArea()
            .withDebugOverlay(label: "TextField", color: .blue)
        }
        ZStack {
            MultilineTextField(
                "Placeholder",
                text: .constant(""),
                isScrollEnabled: true
            )
            .withDebugOverlay(label: "TextField", color: .blue)
            .frame(maxHeight: 100)
        }
        ZStack {
            ScrollView {
                MultilineTextField(
                    "Placeholder",
                    text: .constant(""),
                    isScrollEnabled: true
                )
                .withDebugOverlay(label: "TextField", color: .blue)
            }
        }
    }

    struct Preview: View {
        @State var textA = ""
        @State var textB = "Lorem ipsum"
        @State var textC = "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat."
        @State var isAttributedPlaceholder = false

        var body: some View {
            ScrollView {
                VStack(alignment: .center) {
                    VStack(alignment: .center, spacing: 48) {
                        Toggle(isOn: $isAttributedPlaceholder) {
                            Text("isAttributedPlaceholder")
                        }
                        let placeholder = isAttributedPlaceholder ? Text("AttributedPlaceholder").font(.title.bold()) : Text("Placeholder")

                        placeholder
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .withDebugOverlay(label: "Text", color: .yellow)

                        MultilineTextField(
                            placeholder,
                            text: $textA
                        )
                        .withDebugOverlay(label: "TextField", color: .blue)

                        MultilineTextField(
                            "Placeholder\nPlaceholder",
                            text: $textA
                        )
                        .withDebugOverlay(label: "TextField", color: .blue)

                        if #available(iOS 16.0, *) {
                            MultilineTextField("Placeholder", text: .constant(""))
                                .lineLimit(2...)
                                .withDebugOverlay(label: "TextField", color: .blue)
                        }
                    }
                    .padding(.vertical, 24)

                    MultilineTextField(
                        Text("Placeholder").foregroundColor(.blue).font(.title),
                        text: $textA
                    )

                    MultilineTextField(
                        Text("Placeholder").foregroundColor(.blue).font(.caption),
                        text: $textA
                    )

                    MultilineTextField(
                        "Placeholder",
                        text: $textA
                    )
                    .multilineTextAlignment(.center)

                    MultilineTextField(
                        "Placeholder",
                        text: $textA
                    )
                    .multilineTextAlignment(.trailing)

                    MultilineTextField(
                        "Placeholder",
                        text: $textB
                    )

                    VStack(alignment: .center) {
                        MultilineTextField(
                            "Placeholder",
                            text: $textA
                        )

                        MultilineTextField(
                            "Placeholder",
                            text: $textB
                        )
                    }
                    .environment(\.layoutDirection, .rightToLeft)

                    MultilineTextField(
                        "Placeholder",
                        text: $textB
                    )
                    .font(.headline)
                    .foregroundColor(.blue)

                    MultilineTextField(
                        "Placeholder",
                        text: $textB
                    )
                    .textContentType(.password)

                    if #available(iOS 15.0, *) {
                        MultilineTextField(
                            "Placeholder",
                            text: $textB
                        )
                        .dynamicTypeSize(.accessibility1)
                    }

                    MultilineTextField(
                        textC,
                        text: $textA
                    )

                    MultilineTextField(
                        "Placeholder",
                        text: $textC
                    )

                    MultilineTextField(
                        textC,
                        text: $textA
                    )
                    .lineLimit(2)

                    MultilineTextField(
                        "Placeholder",
                        text: $textC
                    )
                    .lineLimit(2)
                }
            }
        }
    }
}

#endif
