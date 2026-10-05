//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
public struct SegmentedControlStyle {

    struct Key: EnvironmentKey {
        static let defaultValue: SegmentedControlStyle = .plain
    }

    var selectedSegmentTintColor: Color?
    var selectedSegmentFont: Font?
    var selectedSegmentForegroundColor: Color?
    var unselectedSegmentTintColor: Color?
    var prefersDividers: Bool = true
    var prefersGlassBackground: Bool = false

    public static var plain: SegmentedControlStyle { .init() }

    public static func capsule(
        selectedSegmentTintColor: Color? = nil,
        selectedSegmentFont: Font? = nil,
        selectedSegmentForegroundColor: Color? = nil,
        unselectedSegmentTintColor: Color? = nil,
        prefersDividers: Bool = true,
    ) -> SegmentedControlStyle {
        SegmentedControlStyle(
            selectedSegmentTintColor: selectedSegmentTintColor,
            selectedSegmentFont: selectedSegmentFont,
            selectedSegmentForegroundColor: selectedSegmentForegroundColor,
            unselectedSegmentTintColor: unselectedSegmentTintColor,
            prefersDividers: prefersDividers
        )
    }

    @available(iOS 26.0, *)
    public static func glass(
        tintColor: Color? = nil,
        selectedSegmentFont: Font? = nil,
        selectedSegmentForegroundColor: Color? = nil
    ) -> SegmentedControlStyle {
        SegmentedControlStyle(
            selectedSegmentFont: selectedSegmentFont,
            selectedSegmentForegroundColor: selectedSegmentForegroundColor,
            unselectedSegmentTintColor: tintColor,
            prefersGlassBackground: true
        )
    }
}

extension View {

    public func segmentedControlStyle(
        _ style: SegmentedControlStyle
    ) -> some View {
        environment(\.segmentedControlStyle, style)
    }
}

public struct SegmentedControlItemAttributes: OptionSet {

    public var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static var disabled: SegmentedControlItemAttributes { SegmentedControlItemAttributes(rawValue: 1 << 0) }
}

@available(iOS 14.0, *)
public struct SegmentButton<ID: Hashable> {

    public var id: ID
    public var attributes: SegmentedControlItemAttributes
    public var label: LabelElement
    public var preferredSize: ProposedSize = .unspecified

    public init(
        id: ID,
        attributes: SegmentedControlItemAttributes = [],
        @LabelElementBuilder label: () -> LabelElement
    ) {
        self.id = id
        self.attributes = attributes
        self.label = label()
    }
}

@available(iOS 14.0, *)
extension SegmentButton {

    public func disabled(_ isDisabled: Bool) -> Self {
        var copy = self
        if isDisabled {
            copy.attributes.insert(.disabled)
        } else {
            copy.attributes.remove(.disabled)
        }
        return copy
    }

    public func frame(width: CGFloat? = nil, height: CGFloat? = nil) -> Self {
        var copy = self
        copy.preferredSize.width = width ?? copy.preferredSize.width
        copy.preferredSize.height = height ?? copy.preferredSize.height
        return copy
    }
}

@available(iOS 14.0, *)
public struct SegmentedControl<Selection: Hashable>: View {

    private var selection: Binding<Selection?>
    private var items: [SegmentButton<Selection>]

    @_disfavoredOverload
    public init(
        selection: Binding<Selection?>,
        options: [Selection],
        item: (Selection) -> SegmentButton<Selection>
    ) {
        self.selection = selection
        self.items = options.map { item($0) }
    }

    @_disfavoredOverload
    public init(
        selection: Binding<Selection>,
        options: [Selection],
        item: (Selection) -> SegmentButton<Selection>
    ) {
        self.init(
            selection: selection.asOptional(),
            options: options,
            item: item
        )
    }

    public init(
        selection: Binding<Selection?>,
        options: [Selection],
        @LabelElementBuilder item: (Selection) -> LabelElement
    ) {
        self.init(selection: selection, options: options) { option in
            SegmentButton(id: option) {
                item(option)
            }
        }
    }

    public init(
        selection: Binding<Selection>,
        options: [Selection],
        @LabelElementBuilder item: (Selection) -> LabelElement
    ) {
        self.init(selection: selection, options: options) { option in
            SegmentButton(id: option) {
                item(option)
            }
        }
    }

    public var body: some View {
        SegmentedControlBody(
            selection: selection,
            items: items
        )
    }
}

extension EnvironmentValues {

    fileprivate var segmentedControlStyle: SegmentedControlStyle {
        get { self[SegmentedControlStyle.Key.self] }
        set { self[SegmentedControlStyle.Key.self] = newValue }
    }
}

@available(iOS 14.0, *)
private struct SegmentedControlBody<Selection: Hashable>: UIViewRepresentable {

    var selection: Binding<Selection?>
    var items: [SegmentButton<Selection>]

    var selectedIndex: Binding<Int> {
        let ids = items.map({ $0.id })
        return selection.index(ids).unwrap(defaultValue: UIViewType.noSegment)
    }

    typealias UIViewType = SegmentedControlPlatformView

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        uiView.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let selectedIndex = selectedIndex
        context.coordinator.selectedIndex = selectedIndex

        let tintColor = context.environment.segmentedControlStyle.selectedSegmentTintColor?.toUIColor()
        let backgroundColor = context.environment.segmentedControlStyle.unselectedSegmentTintColor?.toUIColor()
        uiView.selectedSegmentTintColor = tintColor
        uiView.backgroundColor = backgroundColor

        uiView.setDividerImage(
            context.environment.segmentedControlStyle.prefersDividers ? nil : UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .normal,
            barMetrics: .default
        )
        if #available(iOS 26.0, *) {
            uiView.useGlass = context.environment.segmentedControlStyle.prefersGlassBackground
        }
        uiView.preferredSegmentHeight = items
            .map { $0.preferredSize.height }
            .reduce(into: nil) { preferredSegmentHeight, height in
                guard let height else { return }
                preferredSegmentHeight = preferredSegmentHeight.map { max($0, height) } ?? height
            }
        let priority: UILayoutPriority = items.allSatisfy({ $0.preferredSize.width != nil }) ? .required : .defaultLow
        uiView.setContentHuggingPriority(priority, for: .horizontal)

        var attributes = [NSAttributedString.Key: Any]()
        if let font = context.environment.font?.toUIFont(in: context.environment) {
            attributes[.font] = font
        }
        if let foregroundColor = context.environment.foregroundColor?.toUIColor() {
            attributes[.foregroundColor] = foregroundColor
        }
        uiView.setTitleTextAttributes(attributes.isEmpty ? nil : attributes, for: .normal)
        if let font = context.environment.segmentedControlStyle.selectedSegmentFont?.toUIFont(in: context.environment) {
            attributes[.font] = font
        }
        if let foregroundColor = context.environment.segmentedControlStyle.selectedSegmentForegroundColor?.toUIColor() {
            attributes[.foregroundColor] = foregroundColor
        }
        uiView.setTitleTextAttributes(attributes.isEmpty ? nil : attributes, for: .selected)

        for index in items.indices {
            let label = items[index].label
            let title = label.title?.resolve(in: context.environment)
            if uiView.numberOfSegments > index {
                uiView.setTitle(title, forSegmentAt: index)
            } else {
                uiView.insertSegment(withTitle: title, at: index, animated: false)
            }
            if let image = label.image?.toUIImage(in: context.environment) {
                uiView.setImage(image, forSegmentAt: index)
            }
            uiView.setEnabled(!items[index].attributes.contains(.disabled), forSegmentAt: index)
            uiView.setWidth(items[index].preferredSize.width ?? 0, forSegmentAt: index)
        }
        while uiView.numberOfSegments > items.count {
            uiView.removeSegment(at: uiView.numberOfSegments - 1, animated: false)
        }
        uiView.layoutIfNeeded()

        let selectedSegmentIndex = selectedIndex.wrappedValue
        if uiView.selectedSegmentIndex != selectedSegmentIndex {
            uiView.selectedSegmentIndex = selectedSegmentIndex
        }
    }

    class SegmentedControlPlatformView: UISegmentedControl {

        @available(iOS 26.0, *)
        var useGlass: Bool {
            get {
                guard
                    // useGlass
                    let aSelector = NSStringFromBase64EncodedString("dXNlR2xhc3M="),
                    responds(to: NSSelectorFromString(aSelector)),
                    let value = value(forKey: aSelector) as? Bool
                else {
                    return false
                }
                return value
            }
            set {
                guard
                    // _setUseGlass:
                    let aSelector = NSSelectorFromBase64EncodedString("X3NldFVzZUdsYXNzOg=="),
                    responds(to: aSelector),
                    // useGlass
                    let key = NSStringFromBase64EncodedString("dXNlR2xhc3M=")
                else {
                    return
                }
                setValue(newValue, forKey: key)
            }
        }

        var preferredSegmentHeight: CGFloat? {
            didSet {
                guard oldValue != preferredSegmentHeight else { return }
                invalidateIntrinsicContentSize()
            }
        }

        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            if let preferredSegmentHeight {
                size.height = preferredSegmentHeight
            }
            return size
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let imageViews = subviews.compactMap { $0 as? UIImageView }.prefix(numberOfSegments)
            for imageView in imageViews {
                imageView.isHidden = backgroundColor != nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedIndex: selectedIndex)
    }

    @MainActor
    class Coordinator: NSObject {
        var selectedIndex: Binding<Int>

        init(selectedIndex: Binding<Int>) {
            self.selectedIndex = selectedIndex
        }

        @objc
        func valueChanged(_ segmentedControl: UISegmentedControl) {
            let newValue = segmentedControl.selectedSegmentIndex
            withAnimation {
                selectedIndex.wrappedValue = newValue
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct SegmentedControl_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        enum Options: Hashable, CaseIterable {
            case one
            case two
            case three

            var label: String {
                switch self {
                case .one:
                    return "One"
                case .two:
                    return "Two"
                case .three:
                    return "Three"
                }
            }

            var image: String {
                switch self {
                case .one:
                    return "1.circle.fill"
                case .two:
                    return "2.circle.fill"
                case .three:
                    return "3.circle.fill"
                }
            }
        }
        @State var selection: Options = .one
        @State var showAll = true

        var body: some View {
            let options = showAll ? Options.allCases : [.one, .two]
            VStack {
                HStack {
                    Button {
                        withAnimation {
                            showAll.toggle()
                        }
                    } label: {
                        Text(showAll ? "Hide Three" : "Show All")
                    }

                    ForEach(options, id: \.self) { option in
                        Button {
                            withAnimation {
                                selection = option
                            }
                        } label: {
                            Text(option.label)
                        }
                    }
                }

                let segments = Group {
                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Text(option.label)
                    }
                    .fixedSize()

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Text(option.label)
                    }

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        SegmentButton(id: option) {
                            Text(option.label)
                        }
                        .disabled(option != .one)
                    }

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        SegmentButton(id: option) {
                            Text(option.label)
                        }
                        .frame(width: 80, height: 44)
                    }

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Text(option.label)
                        Image(systemName: option.image)
                    }

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Image(systemName: option.image)
                    }
                    .foregroundColor(.red)
                    .font(.headline.weight(.heavy))

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Text(option.label)
                    }
                    .foregroundColor(.red)
                    .segmentedControlStyle(
                        .capsule(
                            selectedSegmentFont: .headline.bold()
                        )
                    )

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Text(option.label)
                    }
                    .segmentedControlStyle(
                        .capsule(
                            selectedSegmentTintColor: .black,
                            selectedSegmentForegroundColor: .white,
                            unselectedSegmentTintColor: .red
                        )
                    )
                }

                segments

                if #available(iOS 26.0, *) {
                    let glassSegments = Group {
                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            Text(option.label)
                        }
                        .fixedSize()

                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            Text(option.label)
                        }

                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            SegmentButton(id: option) {
                                Text(option.label)
                            }
                            .disabled(option != .one)
                        }

                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            SegmentButton(id: option) {
                                Text(option.label)
                            }
                            .frame(width: 80, height: 44)
                        }

                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            Text(option.label)
                            Image(systemName: option.image)
                        }

                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            Image(systemName: option.image)
                        }
                        .foregroundColor(.red)

                        SegmentedControl(
                            selection: $selection,
                            options: options
                        ) { option in
                            Text(option.label)
                        }
                        .foregroundColor(.red)
                    }

                    glassSegments
                        .segmentedControlStyle(.glass())

                    SegmentedControl(
                        selection: $selection,
                        options: options
                    ) { option in
                        Text(option.label)
                    }
                    .foregroundColor(.white)
                    .segmentedControlStyle(.glass(tintColor: .red))
                }
            }
            .padding()
        }
    }
}

#endif
