//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct TextView: View {

    var text: Text

    public init(
        _ text: Text
    ) {
        self.text = text
    }

    public init(
        _ text: LocalizedStringKey
    ) {
        self.init(Text(text))
    }

    public init<S: StringProtocol>(
        _ text: S
    ) {
        self.init(Text(text))
    }

    public var body: some View {
        TextViewBody(
            text: text
        )
    }
}

@available(iOS 14.0, *)
private struct TextViewBody: UIViewRepresentable {

    var text: Text

    typealias UIViewType = TextViewPlatformView

    func makeUIView(context: Context) -> UIViewType {
        let uiView: UIViewType
        if #available(iOS 16.0, *) {
            uiView = UIViewType()
            uiView.textLayoutManager?.usesFontLeading = false
        } else {
            uiView = UIViewType()
            uiView.layoutManager.usesFontLeading = false
        }
        uiView.delegate = context.coordinator
        uiView.textContainerInset = .zero
        uiView.textContainer.lineFragmentPadding = 0
        uiView.isScrollEnabled = false
        uiView.isEditable = false
        uiView.contentInsetAdjustmentBehavior = .never
        uiView.clipsToBounds = false
        uiView.backgroundColor = nil
        uiView.dataDetectorTypes = .all
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

        context.coordinator.onOpenURL = context.environment.openURL

        let font = context.environment.font?.toUIFont(in: context.environment)
            ?? .preferredFont(forTextStyle: .body, compatibleWith: context.environment.traitCollectionForFontResolution())
        let textColor = context.environment.foregroundColor?.toUIColor()
        let tintColor = context.environment.tintColor?.toUIColor()
        uiView.font = font
        uiView.textColor = textColor
        uiView.tintColor = tintColor

        uiView.adjustsFontForContentSizeCategory = false

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

        if text.isAttributed {
            uiView.attributedText = text.resolveAttributed(in: context.environment)
        } else {
            let text = text.resolve(in: context.environment)
            if uiView.text != text {
                uiView.text = text
            }
        }
    }

    final class TextViewPlatformView: UITextView {

        var lineLimitRange: ClosedRange<Int>? {
            didSet {
                textContainer.maximumNumberOfLines = lineLimitRange?.upperBound ?? 0
            }
        }

        var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
            didSet {
                textContainer.lineBreakMode = lineBreakMode
            }
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var sizeThatFits = super.sizeThatFits(size)
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
            let size = sizeThatFits(fittingSize)
            return size
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onOpenURL: OpenURLAction?

        func textView(
            _ textView: UITextView,
            shouldInteractWith url: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            if interaction == .invokeDefaultAction, let onOpenURL, !onOpenURL.isDefault {
                if #available(iOS 15.0, *) {
                    let result: OpenURLAction.OpenResult = onOpenURL(url)
                    switch result {
                    case .handled:
                        return false
                    default:
                        break
                    }
                } else {
                    onOpenURL(url)
                    return false
                }
            }
            return true
        }
    }
}

@available(iOS 14.0, *)
struct TextView_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var textA = "Lorem ipsum"
        @State var textB = "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat."

        var body: some View {
            ScrollView {
                VStack(alignment: .center) {
                    VStack(alignment: .center, spacing: 48) {
                        Text(textA)
                            .withDebugOverlay(label: "Text", color: .yellow)

                        TextView(
                            textA
                        )
                        .withDebugOverlay(label: "TextField", color: .blue)

                        if #available(iOS 16.0, *) {
                            TextView(
                                textA
                            )
                            .lineLimit(2...)
                            .withDebugOverlay(label: "TextField", color: .blue)
                        }
                    }
                    .padding(.vertical, 24)

                    TextView(
                        textA
                    )

                    TextView(
                        textA
                    )
                    .multilineTextAlignment(.center)

                    TextView(
                        textA
                    )
                    .multilineTextAlignment(.trailing)

                    TextView(
                        textA
                    )
                    .font(.headline)
                    .foregroundColor(.blue)

                    if #available(iOS 15.0, *) {
                        TextView(
                            textA
                        )
                        .dynamicTypeSize(.accessibility1)
                    }

                    TextView(
                        textB
                    )
                    .lineLimit(2)

                    if #available(iOS 15.0, *) {
                        TextView(
                            "https://github.com"
                        )
                        .environment(\.openURL, OpenURLAction { url in
                            print(url)
                            return .handled
                        })

                        TextView(
                            "https://github.com"
                        )
                        .environment(\.openURL, OpenURLAction { url in
                            return .systemAction
                        })

                        TextView(
                            "https://github.com"
                        )
                        .environment(\.openURL, OpenURLAction { url in
                            return .discarded
                        })
                    }
                }
            }
        }
    }
}

#endif
