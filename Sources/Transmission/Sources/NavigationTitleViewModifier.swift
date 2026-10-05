//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

@frozen
public enum NavigationTitleViewPreferredPlacement: Equatable {
    case leading
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
            .navigationTitle(label ?? Text(verbatim: ""))
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

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        uiView.isHidden = true
        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onUpdate(
            content: titleView,
            preferredPlacement: preferredPlacement,
            context: context
        )
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.onDismantle()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator {
        var titleView: NavigationTitleViewContentView<NavigationTitleViewHostingView<TitleView>>?
        weak var sourceItem: UINavigationItem?

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
                    navigationItem.titleView = titleView
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
            .dynamicTypeSize(...DynamicTypeSize.large)
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
        CGSize(width: UIView.layoutFittingExpandedSize.width, height: min(contentView.intrinsicContentSize.height, 44))
    }

    open var preferredPlacement: NavigationTitleViewPreferredPlacement? {
        didSet {
            guard oldValue != preferredPlacement else { return }
            setNeedsLayout()
        }
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

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if preferredPlacement != .leading {
            setNeedsLayout()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let size = contentView.sizeThatFits(bounds.size)
        let targetY = ((bounds.height - size.height) / 2).rounded(scale: traitCollection.displayScale)
        let navigationBar = _firstAncestor(ofType: UINavigationBar.self)
        let placement = placement(in: navigationBar)
        if placement == .center, let navigationBar {
            let navigationBarContentBounds = navigationBar.bounds.inset(by: navigationBar.safeAreaInsets)
            let center = navigationBar
                .convert(CGPoint(x: navigationBarContentBounds.midX, y: navigationBarContentBounds.midY), to: self)
            let targetWidth = min(size.width, bounds.width)
            let targetX = (center.x - (targetWidth / 2)).rounded(scale: traitCollection.displayScale)
            let dx = 2 * targetX
            let offset = targetWidth - abs(dx)
            let frame: CGRect
            if offset <= 0 {
                frame = CGRect(
                    x: targetX,
                    y: targetY,
                    width: targetWidth,
                    height: size.height
                )
            } else if offset >= contentView.intrinsicContentSize.width {
                frame = CGRect(
                    x: max(0, dx),
                    y: max(0, targetY),
                    width: targetWidth - abs(dx),
                    height: size.height
                )
            } else {
                frame = CGRect(origin: .zero, size: size)
            }
            if abs(contentView.frame.origin.x - frame.origin.x) > (1 / traitCollection.displayScale) {
                UIView.performWithoutAnimation {
                    contentView.frame = CGRect(
                        x: frame.origin.x,
                        y: contentView.frame.origin.y,
                        width: frame.size.width,
                        height: contentView.frame.size.height
                    )
                }
            }
            contentView.frame = frame
        } else if placement == .leading {
            let targetWidth = min(min(contentView.intrinsicContentSize.width, size.width), bounds.width)
            let targetX = effectiveUserInterfaceLayoutDirection == .rightToLeft ? bounds.width - targetWidth : 0
            contentView.frame = CGRect(
                x: targetX,
                y: targetY,
                width: targetWidth,
                height: size.height
            )
        } else {
            contentView.frame = CGRect(origin: CGPoint(x: 0, y: targetY), size: size)
        }
    }

    open func placement(in navigationBar: UINavigationBar?) -> NavigationTitleViewPreferredPlacement {
        if let preferredPlacement {
            return preferredPlacement
        }
        return navigationBar?.preferredTitleViewPlacement ?? .center
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let point = convert(point, to: contentView)
        return contentView.point(inside: point, with: event)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let point = convert(point, to: contentView)
        return contentView.hitTest(point, with: event)
    }
}

extension UINavigationBar {

    public var preferredTitleViewPlacement: NavigationTitleViewPreferredPlacement? {
        guard let topItem else { return nil }
        guard traitCollection.horizontalSizeClass == .regular else { return .center }

        var hasLeadingItems = false
        if #available(iOS 16.0, *) {
            for group in topItem.leadingItemGroups where !group.isHidden {
                for item in group.barButtonItems where !item._isHidden {
                    hasLeadingItems = true
                    if isInNavigationBar(item: item) {
                        return .leading
                    }
                }
            }
        } else {
            let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
            if let leadingItems = isRTL ? topItem.rightBarButtonItems : topItem.leftBarButtonItems {
                for item in leadingItems where !item._isHidden {
                    hasLeadingItems = true
                    if isInNavigationBar(item: item) {
                        return .leading
                    }
                }
            }
            if let leadingItem = isRTL ? topItem.rightBarButtonItem : topItem.leftBarButtonItem, !leadingItem._isHidden {
                hasLeadingItems = true
                if isInNavigationBar(item: leadingItem)  {
                    return .leading
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
            return .leading
        }
        return .center
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

#endif
