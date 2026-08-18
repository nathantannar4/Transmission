//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// The location of the context menu accessory view
@frozen
@available(iOS 14.0, *)
public enum ContextMenuAccessoryLayoutLocation: Sendable {
    case background
    case preview
    case menu
}

@frozen
@available(iOS 14.0, *)
public struct ContextMenuAccessoryViewLayoutProperties {
    public var location: ContextMenuAccessoryLayoutLocation
    public var alignment: Alignment
    public var anchor: UnitPoint
    public var offset: CGPoint
    public var trackingAxis: Axis.Set

    @inlinable
    public init(
        location: ContextMenuAccessoryLayoutLocation,
        alignment: Alignment,
        anchor: UnitPoint,
        offset: CGPoint,
        trackingAxis: Axis.Set
    ) {
        self.location = location
        self.alignment = alignment
        self.anchor = anchor
        self.offset = offset
        self.trackingAxis = trackingAxis
    }
}

/// Don't use directly, instead use ``ContextMenuAccessoryView``
@available(iOS 14.0, *)
public protocol ContextMenuAccessoryViewLayoutRepresentable {
    var layoutProperties: ContextMenuAccessoryViewLayoutProperties { get }
}

/// A view that can be presented alongside the preview of a context menu
@frozen
@available(iOS 14.0, *)
public struct ContextMenuAccessoryView<Content: View>: View, ContextMenuAccessoryViewLayoutRepresentable {

    public var content: Content
    public var layoutProperties: ContextMenuAccessoryViewLayoutProperties

    @inlinable
    public init(
        location: ContextMenuAccessoryLayoutLocation = .preview,
        alignment: Alignment,
        anchor: UnitPoint = .center,
        offset: CGPoint = .zero,
        trackingAxis: Axis.Set = [],
        @ViewBuilder content: () -> Content
    ) {
        self.layoutProperties = ContextMenuAccessoryViewLayoutProperties(
            location: location,
            alignment: alignment,
            anchor: anchor,
            offset: offset,
            trackingAxis: trackingAxis
        )
        self.content = content()
    }

    public var body: some View {
        content
    }
}

@MainActor
@available(iOS 14.0, *)
class ContextMenuAccessoryViewAdapter<
    AccessoryViews: View
> {

    private(set) var accessoryViews: [UIView] = []

    init(
        accessoryViews: AccessoryViews,
        interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration
    ) {
        var vistor = InitVisitor(
            interaction: interaction,
            configuration: configuration,
            adapter: self
        )
        accessoryViews.visit(visitor: &vistor)
    }

    func update(
        accessoryViews: AccessoryViews,
        transaction: Transaction
    ) {
        var visitor = UpdateVisitor(
            adapter: self,
            transaction: transaction
        )
        accessoryViews.visit(visitor: &visitor)
    }

    @MainActor
    @available(iOS 14.0, *)
    private struct InitVisitor: @preconcurrency MultiViewVisitor {

        let interaction: UIContextMenuInteraction
        let configuration: UIContextMenuConfiguration
        let adapter: ContextMenuAccessoryViewAdapter<AccessoryViews>

        mutating func visit<Content>(
            content: Content,
            context: Context,
            stop: inout Bool
        ) where Content: View {
            if let accessoryView = content.makeUIAccessoryView(interaction: interaction, configuration: configuration) {
                adapter.accessoryViews.append(accessoryView)
            }
        }
    }

    @MainActor
    private struct UpdateVisitor: @preconcurrency MultiViewVisitor {
        var adapter: ContextMenuAccessoryViewAdapter<AccessoryViews>
        var transaction: Transaction
        var index = 0

        mutating func visit<Content>(
            content: Content,
            context: Context,
            stop: inout Bool
        ) where Content: View {
            stop = index >= adapter.accessoryViews.count
            if !stop, let hostingView = adapter.accessoryViews[index].accessoryHostingView as? AccessoryHostingView<Content> {
                hostingView.update(
                    content: content,
                    transaction: transaction
                )
            }
            index += 1
        }
    }
}

@available(iOS 14.0, *)
extension View {

    func makeUIAccessoryView(
        interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration
    ) -> UIView? {
        let presentationCoordinator = PresentationCoordinator(
            isPresented: true,
            sourceView: nil,
            seed: Seed.constant(ObjectIdentifier(configuration))
        ) { [weak interaction] _, transaction in
            if transaction.isAnimated {
                interaction?.dismissMenu()
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                interaction?.dismissMenu()
                CATransaction.commit()
            }
        }
        let hostingView = AccessoryHostingView(
            content: AccessoryView(
                content: self,
                presentationCoordinator: presentationCoordinator
            )
        )

        let accessoryView = UIContextMenuInteraction.makeUIAccessoryView(
            contentView: hostingView,
            layout: (self as? ContextMenuAccessoryViewLayoutRepresentable)?.layoutProperties,
            interaction: interaction,
            configuration: configuration
        )
        accessoryView?.accessoryHostingView = hostingView
        return accessoryView
    }
}

@available(iOS 14.0, *)
extension UIContextMenuInteraction {

    public static func makeUIAccessoryView(
        contentView: UIView,
        layout: ContextMenuAccessoryViewLayoutProperties? = nil,
        interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration
    ) -> UIView? {
        typealias Init = @convention(c) (AnyObject, Selector, CGRect, AnyObject) -> Unmanaged<UIView>
        guard
            // initWithFrame:configuration:
            let initSelector = NSSelectorFromBase64EncodedString("aW5pdFdpdGhGcmFtZTpjb25maWd1cmF0aW9uOg=="),
            // _UIContextMenuAccessoryView
            let aClass = NSClassFromBase64EncodedString("X1VJQ29udGV4dE1lbnVBY2Nlc3NvcnlWaWV3") as? UIView.Type,
            aClass.instancesRespond(to: initSelector),
            let initMethod = class_getInstanceMethod(aClass, initSelector)
        else {
            return nil
        }

        let `init` = unsafeBitCast(method_getImplementation(initMethod), to: Init.self)
        let allocSelector = NSSelectorFromString("alloc")
        guard let instance = aClass.perform(allocSelector)?.takeUnretainedValue() else { return nil }

        let location = layout?.location ?? .menu
        let alignment = layout?.alignment ?? {
            switch location {
            case .background: return .center
            case .preview: return .topLeading
            case .menu: return .topLeading
            }
        }()

        lazy var previewViewController = configuration.previewViewController
        let fittingSize: CGSize = {
            guard let view = interaction.view, let window = view.window else { return UIScreen.main.bounds.size }
            let insets = window.layoutMargins
            let fittingRect = window.frame.inset(by: insets)
            guard location != .background else { return fittingRect.size }
            if alignment.vertical == .center {
                if let previewViewController {
                    if previewViewController.preferredContentSize != .zero {
                        return previewViewController.preferredContentSize
                    }
                    return fittingRect.size
                }
                return view.bounds.size
            } else {
                let frameInWindow: CGRect = {
                    if let previewViewController {
                        let size = previewViewController.preferredContentSize
                        if size != .zero {
                            return CGRect(
                                x: window.bounds.midX - size.width / 2,
                                y: window.bounds.midY - size.height / 2,
                                width: size.width,
                                height: size.height
                            )
                        }
                        return fittingRect
                    }
                    return view.convert(view.bounds, to: view.window)
                }()
                var leadingInset = min(frameInWindow.minX, insets.left)
                var trailingInset = min(window.bounds.width - frameInWindow.maxX, insets.right)
                let scale = max(1, view.bounds.height / fittingRect.height)
                if scale > 1 {
                    let aspectRatio = view.bounds.height / view.bounds.width
                    leadingInset += (scale * (insets.left + aspectRatio)).rounded(scale: view.traitCollection.displayScale)
                    trailingInset += (scale * (insets.right + aspectRatio)).rounded(scale: view.traitCollection.displayScale)
                }
                switch alignment.horizontal {
                case .leading:
                    return CGSize(
                        width: fittingRect.width - leadingInset - insets.right,
                        height: fittingRect.height
                    )

                case .trailing:
                    return CGSize(
                        width: fittingRect.width - trailingInset - insets.left,
                        height: fittingRect.height
                    )

                default:
                    return CGSize(
                        width: frameInWindow.width + (leadingInset + trailingInset),
                        height: fittingRect.height
                    )
                }
            }
        }()
        contentView.frame.size = contentView.sizeThatFits(fittingSize)

        let accessoryView = `init`(instance, initSelector, contentView.bounds, configuration).takeRetainedValue()

        // setLocation:
        if let aSelector = NSSelectorFromBase64EncodedString("c2V0TG9jYXRpb246"),
            accessoryView.responds(to: aSelector)
        {
            let rawValue: Int = switch location {
            case .background: 0
            case .preview: 1
            case .menu: 2
            }
            accessoryView.setValue(rawValue, forKey: "location")
        }

        // setAnchor:
        if let aSelector = NSSelectorFromBase64EncodedString("c2V0QW5jaG9yOg=="),
            accessoryView.responds(to: aSelector),
            let method = class_getInstanceMethod(aClass, aSelector)
        {
            var anchor = ContextMenuAccessoryViewAnchor(
                placement: {
                    switch alignment.vertical {
                    case .top: return 1
                    case .center: return 0
                    case .bottom: return 4
                    default:
                        switch alignment.horizontal {
                        case .leading: return 2
                        case .trailing: return 3
                        default:
                            return 0
                        }
                    }
                }(),
                alignment: {
                    switch alignment.horizontal {
                    case .leading: return 2
                    case .center: return 3
                    case .trailing: return 8
                    default:
                        return 3
                    }
                }(),
                placementOffset: 0,
                alignmentOffset: 0,
                gravity: 0
            )
            withUnsafePointer(to: &anchor) { anchorPtr in
                let setAnchor = unsafeBitCast(
                    method_getImplementation(method),
                    to: (@convention(c) (AnyObject, Selector, UnsafeRawPointer) -> Void).self
                )
                setAnchor(accessoryView, aSelector, anchorPtr)
            }
        }

        // setOffset:
        if let aSelector = NSSelectorFromBase64EncodedString("c2V0T2Zmc2V0Og=="),
            accessoryView.responds(to: aSelector)
        {
            var offset = layout?.offset ?? .zero
            let spacing: CGFloat = 16
            let inset: CGFloat = layout?.anchor ?? .center == .center ? spacing : 0
            // Mirror spacing between menu and preview
            if offset.y == 0, location == .preview {
                if alignment.vertical == .top {
                    offset.y -= inset
                } else if alignment.vertical == .bottom {
                    offset.y += inset
                }
            }
            if let anchor = layout?.anchor {
                offset.x += (anchor.x - 0.5) * contentView.frame.size.width
                offset.y += (anchor.y - 0.5) * contentView.frame.size.height
            }
            if location == .preview, let view = interaction.view, let window = view.window {
                let insets = window.layoutMargins
                let frameInWindow: CGRect = {
                    if let previewViewController {
                        let size = previewViewController.preferredContentSize
                        if size != .zero {
                            return CGRect(
                                x: window.bounds.midX - size.width / 2,
                                y: window.bounds.midY - size.height / 2,
                                width: size.width,
                                height: size.height
                            )
                        }
                        return window.bounds.inset(by: insets)
                    }
                    return view.convert(view.bounds, to: view.window)
                }()
                if alignment.vertical == .top {
                    offset.y += min(insets.top + offset.y + 2, max(insets.top - offset.y - (frameInWindow.minY - contentView.frame.size.height), 0))
                } else if alignment.vertical == .bottom {
                    offset.y -= min(insets.bottom + offset.y - 2, max(insets.bottom + offset.y - (window.frame.height - frameInWindow.maxY - contentView.frame.size.height), 0))
                }
            }
            accessoryView.setValue(offset, forKey: "offset")
        }

        // setTrackingAxis:
        if let aSelector = NSSelectorFromBase64EncodedString("c2V0VHJhY2tpbmdBeGlzOg=="),
            accessoryView.responds(to: aSelector)
        {
            let trackingAxis = layout?.trackingAxis ?? []
            var rawValue: Int = 0
            if trackingAxis.contains(.horizontal) {
                rawValue |= 1 << 0
            }
            if trackingAxis.contains(.vertical) {
                rawValue |= 1 << 1
            }
            accessoryView.setValue(rawValue, forKey: "trackingAxis")
        }


        let container = AccessoryViewContainer(
            contentView: contentView,
            fittingSize: fittingSize
        )
        accessoryView.addSubview(container)
        container.constrain(to: accessoryView)
        return accessoryView
    }
}

@available(iOS 14.0, *)
struct AccessoryView<Content: View>: View {

    var content: Content
    var presentationCoordinator: PresentationCoordinator

    var body: some View {
        content
            .environment(\.presentationCoordinator, presentationCoordinator)
    }
}

@available(iOS 14.0, *)
final class AccessoryHostingView<Content: View>: HostingView<AccessoryContentView<AccessoryView<Content>>> {

    init(content: AccessoryView<Content>) {
        super.init(content: AccessoryContentView(content: content))
        _rootView.content.sourceView = self
        disablesSafeArea = true
    }

    func update(content newValue: Content, transaction: Transaction) {
        var content = content
        content.content.content = newValue
        update(content: content, transaction: transaction)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setNeedsLayout() {
        super.setNeedsLayout()
        superview?.setNeedsLayout()
    }
}

struct AccessoryContentView<Content: View>: View {

    public var content: Content

    weak var sourceView: UIView?

    public var body: some View {
        content
            .modifier(IntrinsicContentSizeInvalidationModifier(sourceView: sourceView))
    }
}

private struct IntrinsicContentSizeInvalidationModifier: VersionedViewModifier {

    weak var sourceView: UIView?

    @available(iOS 16.0, *)
    func v4Body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { [weak sourceView] _ in
                sourceView?.setNeedsLayout()
            }
    }

    @available(iOS 14.0, *)
    func v2Body(content: Content) -> some View {
        content
            .background(
                GeometryReader { [weak sourceView] proxy in
                    Color.clear
                        .hidden()
                        .onChange(of: proxy.size) { [weak sourceView] _ in
                            sourceView?.setNeedsLayout()
                        }
                }
            )
    }
}

@available(iOS 14.0, *)
private class AccessoryViewContainer: UIView {
    let contentView: UIView
    let fittingSize: CGSize

    init(contentView: UIView, fittingSize: CGSize) {
        self.contentView = contentView
        self.fittingSize = fittingSize
        super.init(frame: contentView.frame)
        addSubview(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let sizeThatFits = contentView.sizeThatFits(fittingSize)
        let scale = traitCollection.displayScale
        let frame = CGRect(
            origin: CGPoint(
                x: ((bounds.width - sizeThatFits.width) / 2).rounded(scale: scale),
                y: ((bounds.height - sizeThatFits.height) / 2).rounded(scale: scale)
            ),
            size: sizeThatFits
        )
        if contentView.frame != frame {
            UIView.animate(withDuration: 0.35) { [contentView] in
                contentView.frame = frame
                contentView.layoutIfNeeded()
            }
        }
    }
}

struct ContextMenuAccessoryViewAnchor {
    var placement: UInt64
    var alignment: UInt64
    var placementOffset: Double
    var alignmentOffset: Double
    var gravity: Int64
}

extension UIContextMenuConfiguration {

    var previewViewController: UIViewController? {
        guard
            let value = value(forKey: "previewProvider") as? AnyObject,
            !(value is NSNull)
        else {
            return nil
        }
        typealias ProviderBlock = @convention(block) () -> UIViewController?
        let provider = unsafeBitCast(value, to: ProviderBlock.self)
        return provider()
    }
}

@available(iOS 14.0, *)
extension UIView {

    @objc
    var accessoryHostingView: UIView? {
        get {
            let aSel: Selector = #selector(getter:UIView.accessoryHostingView)
            let box = objc_getAssociatedObject(self, unsafeBitCast(aSel, to: UnsafeRawPointer.self)) as? ObjCWeakBox<UIView>
            return box?.value
        }
        set {
            let aSel: Selector = #selector(getter:UIView.accessoryHostingView)
            let box = newValue.map { ObjCWeakBox(value: $0) }
            objc_setAssociatedObject(self, unsafeBitCast(aSel, to: UnsafeRawPointer.self), box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct ContextMenuAccessoryView_Previews: PreviewProvider {

    struct PreviewMenu: MenuElement {
        var body: some MenuElement {
            MenuButton {

            } label: {
                Text("Action A")
            }

            MenuButton {

            } label: {
                Text("Action D")
            }

            MenuButton {

            } label: {
                Text("Action C")
            }
        }
    }

    struct Preview: View {
        var height: CGFloat

        var body: some View {
            ScrollView {
                VStack {
                    HStack {
                        ContextMenuSourceViewLink {
                            PreviewMenu()
                        } label: {
                            Color.blue
                        } accessoryViews: {
                            ContextMenuAccessoryView(
                                location: .preview,
                                alignment: .topLeading
                            ) {
                                Color.red
                                    .frame(height: 52)
                                    .withDebugOverlay(label: "AccessoryView", color: .yellow)
                            }
                        }

                        ContextMenuSourceViewLink {
                            PreviewMenu()
                        } label: {
                            Color.blue
                        } accessoryViews: {
                            ContextMenuAccessoryView(
                                location: .preview,
                                alignment: .topTrailing
                            ) {
                                Color.red
                                    .frame(height: 52)
                                    .withDebugOverlay(label: "AccessoryView", color: .yellow)
                            }
                        }
                    }
                    .frame(height: height)

                    Spacer(minLength: height)

                    HStack {
                        ContextMenuSourceViewLink {
                            PreviewMenu()
                        } label: {
                            Color.blue
                        } accessoryViews: {
                            ContextMenuAccessoryView(
                                location: .preview,
                                alignment: .bottomLeading
                            ) {
                                Color.red
                                    .frame(height: 52)
                                    .withDebugOverlay(label: "AccessoryView", color: .yellow)
                            }
                        }

                        ContextMenuSourceViewLink {
                            PreviewMenu()
                        } label: {
                            Color.blue
                        } accessoryViews: {
                            ContextMenuAccessoryView(
                                location: .preview,
                                alignment: .bottomTrailing
                            ) {
                                Color.red
                                    .frame(height: 52)
                                    .withDebugOverlay(label: "AccessoryView", color: .yellow)
                            }
                        }
                    }
                    .frame(height: height)
                }
            }
            .overlay {
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .padding(8)
            }
        }
    }

    static var previews: some View {
        Preview(height: 300)
        GeometryReader { proxy in
            Preview(height: proxy.size.height - 16)
        }
        GeometryReader { proxy in
            Preview(height: 2 * (proxy.size.height - 16))
        }
    }
}

#endif
