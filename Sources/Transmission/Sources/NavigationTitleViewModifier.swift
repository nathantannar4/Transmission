//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

@frozen
public enum NavigationTitleViewPreferredPlacement: Equatable {
    /// Sizes intrinsically
    case automatic

    /// Sizes to fill, then leading aligns the content
    case leading

    /// Sizes to fill, then center aligns the content
    case center
}

@frozen
public struct NavigationTitleViewModifier<TitleView: View>: ViewModifier {

    public var label: Text?
    public var preferredPlacement: NavigationTitleViewPreferredPlacement?
    public var titleView: TitleView

    public init(
        label: Text?,
        preferredPlacement: NavigationTitleViewPreferredPlacement?,
        titleView: TitleView
    ) {
        self.label = label
        self.preferredPlacement = preferredPlacement
        self.titleView = titleView
    }

    public func body(content: Content) -> some View {
        content
            .background(
                NavigationTitleViewAdapter(
                    preferredPlacement: preferredPlacement,
                    titleView: titleView
                )
            )
            .navigationBarTitle(
                label ?? Text(verbatim: ""),
                displayMode: titleView.isEmptyView ? .automatic : .inline
            )
    }
}

extension View {

    public func navigationTitleView<TitleView: View>(
        label: Text? = nil,
        preferredPlacement: NavigationTitleViewPreferredPlacement? = nil,
        @ViewBuilder titleView: () -> TitleView
    ) -> some View {
        modifier(
            NavigationTitleViewModifier(
                label: label,
                preferredPlacement: preferredPlacement,
                titleView: titleView()
            )
        )
    }

    public func navigationTitleView(
        preferredPlacement: NavigationTitleViewPreferredPlacement? = nil,
        @TextBuilder label: () -> Text
    ) -> some View {
        let label = label()
        return navigationTitleView(label: label, preferredPlacement: preferredPlacement) {
            label
        }
    }

    public func navigationTitleView<TitleView: View>(
        preferredPlacement: NavigationTitleViewPreferredPlacement? = nil,
        @ViewBuilder titleView: () -> TitleView,
        @TextBuilder label: () -> Text?
    ) -> some View {
        navigationTitleView(label: label(), preferredPlacement: preferredPlacement, titleView: titleView)
    }

    public func navigationTitleView<TitleView: View>(
        label: LocalizedStringKey,
        preferredPlacement: NavigationTitleViewPreferredPlacement? = nil,
        @ViewBuilder titleView: () -> TitleView
    ) -> some View {
        navigationTitleView(label: Text(label), preferredPlacement: preferredPlacement, titleView: titleView)
    }

    @_disfavoredOverload
    public func navigationTitleView<S: StringProtocol, TitleView: View>(
        label: S?,
        preferredPlacement: NavigationTitleViewPreferredPlacement? = nil,
        @ViewBuilder titleView: () -> TitleView
    ) -> some View {
        navigationTitleView(label: Text(label), preferredPlacement: preferredPlacement, titleView: titleView)
    }
}

private struct NavigationTitleViewAdapter<TitleView: View>: UIViewRepresentable {

    var preferredPlacement: NavigationTitleViewPreferredPlacement?
    var titleView: TitleView

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        context.coordinator.onUpdate(
            content: titleView,
            preferredPlacement: preferredPlacement,
            context: context
        )
    }

    static func dismantleUIView(_ uiView: ViewControllerReader, coordinator: Coordinator) {
        coordinator.onDismantle()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator: ViewControllerReaderDelegate {
        var titleView: NavigationTitleViewContentView<NavigationTitleViewHostingView<TitleView>>?
        weak var sourceItem: UINavigationItem?

        func viewControllerReaderDidMoveToWindow(_ view: UIView) {
            guard let sourceItem, sourceItem.titleView == nil else { return }
            sourceItem.titleView = titleView
        }

        func onUpdate(
            content: TitleView,
            preferredPlacement: NavigationTitleViewPreferredPlacement?,
            context: NavigationTitleViewAdapter<TitleView>.Context
        ) {
            guard let viewController = context.environment.hostingController else { return }
            let navigationItem = viewController.navigationItem
            if navigationItem != sourceItem {
                onDismantle()
            }
            guard navigationItem.titleView == nil || navigationItem.titleView === titleView else { return }
            sourceItem = navigationItem

            if content.isEmptyView {
                navigationItem.titleView = nil
            } else {
                if let titleView {
                    titleView.preferredPlacement = preferredPlacement
                    titleView.contentView.update(content: content, transaction: context.transaction)
                } else {
                    titleView = NavigationTitleViewContentView(
                        contentView: NavigationTitleViewHostingView(
                            content: content
                        )
                    )
                    titleView?.preferredPlacement = preferredPlacement
                }
                if navigationItem.titleView !== titleView {
                    UINavigationItem.fixTitleView()
                    navigationItem._titleView = titleView
                }
            }
        }

        func onDismantle() {
            guard let sourceItem, sourceItem.titleView === titleView else { return }
            sourceItem.titleView = nil
        }
    }
}

public struct NavigationTitleView<Content: View>: View {

    public var content: Content

    public init(content: Content) {
        self.content = content
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.headline.weight(.medium))
            .lineLimit(1)
    }
}

open class NavigationTitleViewHostingView<Content: View>: HostingView<NavigationTitleView<Content>> {

    public init(content: Content) {
        super.init(content: NavigationTitleView(content: content))
        invalidatesIntrinsicContentSizeOnIdealSizeChange = true
        automaticallyLayoutIntrinsicContentSizeChange = false
        disablesSafeArea = true
        isHitTestingPassthrough = false
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(content: Content, transaction: Transaction) {
        update(content: NavigationTitleView(content: content), transaction: transaction)
    }
}

open class NavigationTitleViewContentView<ContentView: UIView>: UIView {

    open override var intrinsicContentSize: CGSize {
        let intrinsicContentSize = contentView.intrinsicContentSize
        switch placement {
        case .automatic:
            return intrinsicContentSize
        case .leading, .center:
            return CGSize(width: UIView.layoutFittingExpandedSize.width, height: intrinsicContentSize.height)
        }
    }

    open var preferredPlacement: NavigationTitleViewPreferredPlacement? {
        didSet {
            guard oldValue != preferredPlacement else { return }
            setNeedsLayout()
        }
    }

    open var placement: NavigationTitleViewPreferredPlacement {
        if let preferredPlacement {
            return preferredPlacement
        }
        guard
            traitCollection.horizontalSizeClass == .regular,
            let navigationBar,
            navigationBar.hasLeadingItems
        else {
            return .automatic
        }
        return .leading
    }

    public var navigationBar: UINavigationBar? {
        _firstAncestor(ofType: UINavigationBar.self)
    }

    public let contentView: ContentView

    public init(contentView: ContentView) {
        self.contentView = contentView
        super.init(frame: .zero)
        addSubview(contentView)
        translatesAutoresizingMaskIntoConstraints = false

        UINavigationBar.fixHitTesting()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if preferredPlacement == nil, previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setNeedsLayout()
        }
    }

    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        switch placement {
        case .automatic:
            return contentView.sizeThatFits(size)
        case .leading, .center:
            var sizeThatFits = contentView.sizeThatFits(size)
            sizeThatFits.width = max(sizeThatFits.width, size.width)
            return sizeThatFits
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if preferredPlacement == .center {
            setNeedsLayout()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let contentFrame: CGRect
        let placement = placement
        if placement == .automatic {
            contentFrame = bounds
        } else {
            let size = contentView.sizeThatFits(bounds.size)
            let targetY = max(0, ((bounds.height - size.height) / 2).rounded(scale: traitCollection.displayScale))
            if placement == .center, let navigationBar {
                let navigationBarContentBounds = navigationBar.bounds.inset(by: navigationBar.safeAreaInsets)
                let center = navigationBar
                    .convert(CGPoint(x: navigationBarContentBounds.midX, y: navigationBarContentBounds.midY), to: self)
                    .applying(transform)
                let targetWidth = min(size.width, bounds.width)
                let targetX = (center.x - (targetWidth / 2)).rounded(scale: traitCollection.displayScale)
                let dx = 2 * targetX
                let offset = targetWidth - abs(dx)
                if offset <= 0 {
                    contentFrame = CGRect(
                        x: targetX,
                        y: targetY,
                        width: targetWidth,
                        height: size.height
                    )
                } else {
                    let intrinsicContentSize = contentView.intrinsicContentSize
                    if intrinsicContentSize.width >= 0, offset >= intrinsicContentSize.width {
                        contentFrame = CGRect(
                            x: max(0, dx),
                            y: targetY,
                            width: targetWidth - abs(dx),
                            height: size.height
                        )
                    } else if intrinsicContentSize.width >= 0, intrinsicContentSize.width <= targetWidth {
                        let dx = ((offset - intrinsicContentSize.width) / 2).rounded(scale: traitCollection.displayScale)
                        contentFrame = CGRect(
                            x: max(0, dx),
                            y: targetY,
                            width: intrinsicContentSize.width,
                            height: size.height
                        )
                    } else {
                        let targetX = max(0, (bounds.width - size.width) / 2)
                        contentFrame = CGRect(
                            origin: CGPoint(
                                x: targetX,
                                y: targetY
                            ),
                            size: size
                        )
                    }
                }
            } else if placement == .leading {
                let intrinsicContentSize = contentView.intrinsicContentSize
                let targetWidth = min(min(intrinsicContentSize.width > 0 ? intrinsicContentSize.width : .infinity, size.width), bounds.width)
                let targetX = effectiveUserInterfaceLayoutDirection == .rightToLeft ? bounds.width - targetWidth : 0
                contentFrame = CGRect(
                    x: targetX,
                    y: targetY,
                    width: targetWidth,
                    height: size.height
                )
            } else {
                let targetX = max(0, (bounds.width - size.width) / 2)
                contentFrame = CGRect(
                    origin: CGPoint(
                        x: targetX,
                        y: targetY
                    ),
                    size: size
                )
            }
        }

        contentView.frame = contentFrame
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden, isUserInteractionEnabled else { return false }
        let point = convert(point, to: contentView)
        return contentView.point(inside: point, with: event)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, isUserInteractionEnabled else { return nil }
        let point = convert(point, to: contentView)
        return contentView.hitTest(point, with: event)
    }
}

extension UINavigationBar {

    public var hasLeadingItems: Bool {
        guard let topItem else { return false }
        var hasLeadingItems = false
        if #available(iOS 16.0, *) {
            for group in topItem.leadingItemGroups where !group.isHidden {
                for item in group.barButtonItems where !item._isHidden {
                    hasLeadingItems = true
                    if isInNavigationBar(item: item) {
                        return true
                    }
                }
            }
        } else {
            let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
            if let leadingItems = isRTL ? topItem.rightBarButtonItems : topItem.leftBarButtonItems {
                for item in leadingItems where !item._isHidden {
                    hasLeadingItems = true
                    if isInNavigationBar(item: item) {
                        return true
                    }
                }
            }
            if let leadingItem = isRTL ? topItem.rightBarButtonItem : topItem.leftBarButtonItem, !leadingItem._isHidden {
                hasLeadingItems = true
                if isInNavigationBar(item: leadingItem)  {
                    return true
                }
            }
        }
        let isBackButtonVisible: Bool = {
            guard !topItem.hidesBackButton, topItem.backBarButtonItem != nil, backItem != nil else { return false }
            if hasLeadingItems {
                return topItem.leftItemsSupplementBackButton
            }
            return true
        }()
        if isBackButtonVisible {
            return true
        }
        return false
    }

    private func isInNavigationBar(item: UIBarButtonItem) -> Bool {
        #if XCODE_27_1
        if #available(iOS 27.1, *), item.axisBehavior != .horizontalOnly {
            switch traitCollection.verticalBarEdge {
            case .leading:
                return true
            case .trailing:
                return false
            case .unspecified:
                return false
            @unknown default:
                return true
            }
        }
        #endif
        return true
    }
}

extension UIBarButtonItem {

    var _isHidden: Bool {
        if #available(iOS 16.0, *) {
            return isHidden
        }
        return false
    }
}

extension UINavigationItem {

    private static var didFixTitleView = false
    static func fixTitleView() {
        guard !didFixTitleView else { return }
        didFixTitleView = true
        swizzle(
            target: UINavigationItem.self,
            source: UINavigationItem.self,
            aSelector: #selector(setter: UINavigationItem.titleView),
            aSwizzledSelector: #selector(swizzled_setTitleView(_:))
        )
    }

    var _titleView: UIView? {
        get {
            if let box = objc_getAssociatedObject(self, &Self.didFixTitleView) as? ObjCWeakBox<UIView> {
                return box.value
            }
            return nil
        }
        set {
            if let newValue {
                if let box = objc_getAssociatedObject(self, &Self.didFixTitleView) as? ObjCWeakBox<UIView> {
                    box.value = newValue
                } else {
                    let box = ObjCWeakBox(value: newValue)
                    objc_setAssociatedObject(self, &Self.didFixTitleView, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            } else {
                objc_setAssociatedObject(self, &Self.didFixTitleView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            titleView = newValue
        }
    }

    public func setTitleView(_ titleView: UIView) {
        _titleView = titleView
    }

    @objc
    private func swizzled_setTitleView(_ titleView: UIView?) {
        // Prevent SwiftUI from resetting the titleView
        guard _titleView == nil || _titleView == titleView else { return }
        self.swizzled_setTitleView(_titleView ?? titleView)
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct NavigationTitleViewModifier_Previews: PreviewProvider {

    struct TitleView: View {
        var alignment: HorizontalAlignment = .center
        var isLong: Bool = false

        @State var isExpanded = false

        var body: some View {
            VStack(alignment: alignment) {
                Text(isLong ? "Very Very Very Long Navigation Title" : "Navigation Title")

                if isExpanded {
                    Text("Subtitle")
                        .font(.caption)
                }
            }
            .modifier(GeometryGroupModifier())
            .withDebugOverlay(color: .red)
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }

    struct LeadingToolbarModifier: ViewModifier {
        @State var isHidden = false
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isHidden.toggle()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        if !isHidden {
                            Button {
                                isHidden.toggle()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
        }
    }

    struct TrailingToolbarModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {

                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
    }

    static var previews: some View {
        VStack {
            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .automatic) {
                            TitleView()
                        }
                        .modifier(LeadingToolbarModifier())
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .center) {
                            TitleView()
                        }
                        .modifier(LeadingToolbarModifier())
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .leading) {
                            TitleView(alignment: .leading)
                        }
                        .modifier(LeadingToolbarModifier())
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .center) {
                            TitleView()
                        }
                        .modifier(LeadingToolbarModifier())
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .center) {
                            TitleView(isLong: true)
                        }
                        .modifier(LeadingToolbarModifier())
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .center) {
                            TitleView()
                        }
                        .modifier(LeadingToolbarModifier())
                        .modifier(TrailingToolbarModifier())
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationTitleView(preferredPlacement: .center) {
                            TitleView(isLong: true)
                        }
                        .modifier(LeadingToolbarModifier())
                        .modifier(TrailingToolbarModifier())
                }
            }
        }
    }
}

#endif
