//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit
import Engine

@frozen
public enum NavigationPalettePlacement {
    case top
    case bottom
}

@frozen
public struct NavigationPaletteViewModifier<PaletteView: View>: ViewModifier {

    public var placement: NavigationPalettePlacement
    public var displaysWhenSearchActive: Bool
    public var paletteView: PaletteView

    public init(
        placement: NavigationPalettePlacement,
        displaysWhenSearchActive: Bool = false,
        paletteView: PaletteView
    ) {
        self.placement = placement
        self.displaysWhenSearchActive = displaysWhenSearchActive
        self.paletteView = paletteView
    }

    public func body(content: Content) -> some View {
        content
            .background(
                NavigationPaletteViewAdapter(
                    placement: placement,
                    displaysWhenSearchActive: displaysWhenSearchActive,
                    paletteView: paletteView
                )
            )
    }
}

extension View {

    public func navigationPalette<PaletteView: View>(
        placement: NavigationPalettePlacement = .bottom,
        displaysWhenSearchActive: Bool = false,
        @ViewBuilder paletteView: () -> PaletteView
    ) -> some View {
        modifier(
            NavigationPaletteViewModifier(
                placement: placement,
                displaysWhenSearchActive: displaysWhenSearchActive,
                paletteView: paletteView()
            )
        )
    }
}

private struct NavigationPaletteViewAdapter<PaletteView: View>: UIViewRepresentable {

    var placement: NavigationPalettePlacement
    var displaysWhenSearchActive: Bool
    var paletteView: PaletteView

    func makeUIView(context: Context) -> ViewControllerReader {
        let uiView = ViewControllerReader()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: ViewControllerReader, context: Context) {
        context.coordinator.onUpdate(
            content: paletteView,
            placement: placement,
            displaysWhenSearchActive: displaysWhenSearchActive,
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
        var palette: _UINavigationBarPalette?
        var paletteView: NavigationPaletteContentView<NavigationPaletteHostingView<PaletteView>>?
        var placement: NavigationPalettePlacement?
        weak var sourceItem: UINavigationItem?

        func viewControllerReaderDidMoveToWindow(_ view: UIView) {
            guard let sourceItem, let placement, sourceItem.palette(for: placement) == nil, let palette else { return }
            sourceItem.setPalette(palette, for: placement)
        }

        func onUpdate(
            content: PaletteView,
            placement: NavigationPalettePlacement,
            displaysWhenSearchActive: Bool,
            context: NavigationPaletteViewAdapter<PaletteView>.Context
        ) {
            guard let viewController = context.environment.hostingController else { return }
            let navigationItem = viewController.navigationItem
            if navigationItem != sourceItem || self.placement != placement {
                onDismantle()
            }
            guard navigationItem.palette(for: placement) == nil || navigationItem.palette(for: placement) === palette else { return }
            sourceItem = navigationItem

            if content.isEmptyView {
                navigationItem.setPalette(nil, for: placement)
            } else {
                if let paletteView {
                    paletteView.contentView.update(content: content, transaction: context.transaction)
                } else {
                    paletteView = NavigationPaletteContentView(
                        contentView: NavigationPaletteHostingView(
                            content: content
                        )
                    )
                }
                if let palette {
                    palette.displaysWhenSearchActive = displaysWhenSearchActive
                } else if let paletteView {
                    palette = UINavigationBarPalette(contentView: paletteView)
                    palette?.displaysWhenSearchActive = displaysWhenSearchActive
                }
                if navigationItem.palette(for: placement) !== palette {
                    navigationItem.setPalette(palette, for: placement)
                    self.placement = placement
                }
            }
        }

        func onDismantle() {
            guard let sourceItem else { return }
            if sourceItem.bottomPalette === palette {
                sourceItem.bottomPalette = nil
            }
            if sourceItem.topPalette === palette {
                sourceItem.topPalette = nil
            }
        }
    }
}

extension UINavigationItem {

    public func palette(for placement: NavigationPalettePlacement) -> _UINavigationBarPalette? {
        switch placement {
        case .top:
            return topPalette
        case .bottom:
            return bottomPalette
        }
    }

    public func setPalette(_ palette: _UINavigationBarPalette?, for placement: NavigationPalettePlacement) {
        switch placement {
        case .top:
            topPalette = palette
        case .bottom:
            bottomPalette = palette
        }
    }
}

public struct NavigationPaletteView<Content: View>: View {

    public var content: Content

    public init(content: Content) {
        self.content = content
    }

    public var body: some View {
        content
            .lineLimit(1)
    }
}

open class NavigationPaletteHostingView<Content: View>: HostingView<NavigationPaletteView<Content>> {

    public init(content: Content) {
        super.init(content: NavigationPaletteView(content: content))
        invalidatesIntrinsicContentSizeOnIdealSizeChange = true
        automaticallyLayoutIntrinsicContentSizeChange = false
        disablesSafeArea = true
        isHitTestingPassthrough = false
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(content: Content, transaction: Transaction) {
        update(content: NavigationPaletteView(content: content), transaction: transaction)
    }
}

open class NavigationPaletteContentView<ContentView: UIView>: UIView {

    open override var intrinsicContentSize: CGSize {
        contentView.intrinsicContentSize
    }

    public let contentView: ContentView

    public init(contentView: ContentView) {
        self.contentView = contentView
        super.init(frame: .zero)
        addSubview(contentView)
        autoresizingMask = [.flexibleHeight]

        UINavigationBar.fixHitTesting()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let height = intrinsicContentSize.height
        if let palette = superview as? _UINavigationBarPalette {
            palette.minimumHeight = height
            palette.preferredHeight = height
        }
        let sizeThatFits = contentView.sizeThatFits(bounds.size)
        contentView.frame = CGRect(
            x: (bounds.width - sizeThatFits.width) / 2,
            y: 0,
            width: min(bounds.width, sizeThatFits.width),
            height: max(sizeThatFits.height, height)
        )
    }

    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        setNeedsLayout()
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

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct NavigationPaletteViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationPalette(placement: .bottom) {
                            Text("Bottom Palette")
                        }
                        .navigationTitle("Title")
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationPalette(placement: .top) {
                            Text("Top Palette")
                        }
                        .navigationTitle("Title")
                }
            }

            NavigationView {
                VStack {
                    Text("Hello, World")
                        .navigationPalette(placement: .top) {
                            Text("Top Palette")
                        }
                        .navigationPalette(placement: .bottom) {
                            Text("Bottom Palette")
                        }
                        .navigationTitle("Title")
                }
            }
        }
    }
}

#endif
