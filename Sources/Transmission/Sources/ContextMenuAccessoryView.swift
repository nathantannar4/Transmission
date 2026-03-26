//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public enum ContextMenuAccessoryLayoutLocation: Sendable {
    case background
    case preview
    case menu
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol ContextMenuAccessoryLayout {
    var location: ContextMenuAccessoryLayoutLocation { get }
    var alignment: Alignment { get }
    var anchor: UnitPoint { get }
    var offset: CGPoint { get }
    var trackingAxis: Axis.Set { get }
}

/// A view that can be presented alongside the preview of a context menu
@frozen
@available(iOS 14.0, *)
public struct ContextMenuAccessoryView<Content: View>: View, ContextMenuAccessoryLayout {

    public var location: ContextMenuAccessoryLayoutLocation
    public var alignment: Alignment
    public var anchor: UnitPoint
    public var offset: CGPoint
    public var trackingAxis: Axis.Set
    public var content: Content

    @inlinable
    public init(
        location: ContextMenuAccessoryLayoutLocation = .preview,
        alignment: Alignment,
        anchor: UnitPoint = .center,
        offset: CGPoint = .zero,
        trackingAxis: Axis.Set = [],
        @ViewBuilder content: () -> Content
    ) {
        self.location = location
        self.alignment = alignment
        self.anchor = anchor
        self.offset = offset
        self.trackingAxis = trackingAxis
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
                hostingView.content = AccessoryView(
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

    @MainActor
    func makeUIAccessoryView(
        interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration
    ) -> UIView? {
        let initSelector = NSSelectorFromString("initWithFrame:configuration:")
        typealias Init = @convention(c) (AnyObject, Selector, CGRect, AnyObject) -> Unmanaged<UIView>
        guard
            // _UIContextMenuAccessoryView
            let aClassName = NSStringFromBase64EncodedString("X1VJQ29udGV4dE1lbnVBY2Nlc3NvcnlWaWV3"),
            let aClass = NSClassFromString(aClassName) as? UIView.Type,
            aClass.instancesRespond(to: initSelector),
            let initMethod = class_getInstanceMethod(aClass, initSelector)
        else {
            return nil
        }

        let `init` = unsafeBitCast(method_getImplementation(initMethod), to: Init.self)
        let allocSelector = NSSelectorFromString("alloc")
        guard let instance = aClass.perform(allocSelector)?.takeUnretainedValue() else { return nil }

        let layout = self as? ContextMenuAccessoryLayout
        let location = layout?.location ?? .preview
        let alignment = layout?.alignment ?? {
            switch location {
            case .background: return .center
            case .preview: return .top
            case .menu: return .bottom
            }
        }()

        let hostingView = AccessoryHostingView(
            content: AccessoryView(
                content: self,
                transaction: Transaction(animation: .default)
            )
        )
        hostingView.disablesSafeArea = true

        let fittingSize: CGSize = {
            guard let view = interaction.view, let window = view.window else { return UIScreen.main.bounds.size }
            guard location != .background, alignment.horizontal == .leading || alignment.horizontal == .trailing else {
                return window.bounds.size
            }
            let frameInWindow = view.convert(view.bounds, to: view.window)
            if alignment.horizontal == .leading {
                return CGSize(
                    width: window.bounds.width - frameInWindow.minX,
                    height: window.bounds.height
                )
            } else {
                return CGSize(
                    width: window.bounds.width - frameInWindow.minX,
                    height: window.bounds.height
                )
            }
        }()
        hostingView.frame.size = hostingView.sizeThatFits(fittingSize)

        let uiView = `init`(instance, initSelector, hostingView.bounds, configuration).takeRetainedValue()

        let locationSelector = NSSelectorFromString("setLocation:")
        if uiView.responds(to: locationSelector) {
            let rawValue: Int = switch location {
            case .background: 0
            case .preview: 1
            case .menu: 2
            }
            uiView.setValue(rawValue, forKey: "location")
        }

        let anchorSelector = NSSelectorFromString("setAnchor:")
        if uiView.responds(to: anchorSelector),
            let method = class_getInstanceMethod(aClass, anchorSelector)
        {
            var anchor = ContextMenuAccessoryViewAnchor(
                placement: {
                    switch alignment.vertical {
                    case .top: return 1
                    case .center: return 3
                    case .bottom: return 4
                    default:
                        return 3
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
                setAnchor(uiView, anchorSelector, anchorPtr)
            }
        }

        let offsetSelector = NSSelectorFromString("setOffset:")
        if uiView.responds(to: offsetSelector) {
            var offset = layout?.offset ?? .zero
            if let anchor = layout?.anchor {
                offset.x += (anchor.x - 0.5) * hostingView.frame.size.width
                offset.y += (anchor.y - 0.5) * hostingView.frame.size.height
            }
            uiView.setValue(offset, forKey: "offset")
        }


        let trackingAxisSelector = NSSelectorFromString("setTrackingAxis:")
        if uiView.responds(to: trackingAxisSelector) {
            let trackingAxis = layout?.trackingAxis ?? []
            var rawValue: Int = 0
            if trackingAxis.contains(.horizontal) {
                rawValue |= 1 << 0
            }
            if trackingAxis.contains(.vertical) {
                rawValue |= 1 << 1
            }
            uiView.setValue(rawValue, forKey: "trackingAxis")
        }

        uiView.accessoryHostingView = hostingView
        let container = AccessoryHostingViewContainer(
            hostingView: hostingView,
            fittingSize: fittingSize
        )
        uiView.addSubview(container)
        container.constrain(to: uiView)
        return uiView
    }
}

@available(iOS 14.0, *)
struct AccessoryView<Content: View>: View {
    var content: Content
    var transaction: Transaction

    @UpdatePhase var updatePhase

    var body: some View {
        content
            .fixedSize()
            .transaction(transaction, value: updatePhase)
    }
}

@available(iOS 14.0, *)
final class AccessoryHostingView<Content: View>: HostingView<AccessoryView<Content>> {

    override func setNeedsLayout() {
        super.setNeedsLayout()
        superview?.setNeedsLayout()
    }
}

@available(iOS 14.0, *)
private class AccessoryHostingViewContainer: UIView {
    let hostingView: UIView
    let fittingSize: CGSize

    init(hostingView: UIView, fittingSize: CGSize) {
        self.hostingView = hostingView
        self.fittingSize = fittingSize
        super.init(frame: hostingView.frame)
        addSubview(hostingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let sizeThatFits = hostingView.sizeThatFits(fittingSize)
        let scale = window?.screen.scale ?? 1
        let frame = CGRect(
            origin: CGPoint(
                x: ((bounds.width - sizeThatFits.width) / 2).rounded(scale: scale),
                y: ((bounds.height - sizeThatFits.height) / 2).rounded(scale: scale)
            ),
            size: sizeThatFits
        )
        if hostingView.frame != frame {
            UIView.animate(withDuration: 0.35) { [hostingView] in
                hostingView.frame = frame
                hostingView.layoutIfNeeded()
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

#endif
