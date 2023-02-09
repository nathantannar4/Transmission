//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A backwards compatible port of `ImageRenderer`
///
/// See Also:
///  - ``SnapshotItemProvider``
public final class SnapshotRenderer<Content: View> {

    public var content: Content {
        get { host.content.content }
        set { host.content.content = newValue }
    }

    public var scale: CGFloat {
        get { format.scale }
        set { format.scale = newValue }
    }

    public var isOpaque: Bool {
        get { format.opaque }
        set { format.opaque = newValue }
    }

    public var proposedSize: CGSize = .zero

    private let format: UIGraphicsImageRendererFormat
    private let host: HostingView<ModifiedContent<Content, SnapshotModifier>>

    public init(content: Content) {
        let format = UIGraphicsImageRendererFormat()
        self.format = format
        let host = HostingView(content: content.modifier(SnapshotModifier(scale: format.scale)))
        host.disablesSafeArea = true
        self.host = host
    }

    public func snapshot() -> UIImage {
        let size: CGSize = {
            let intrinsicContentSize = host.intrinsicContentSize
            return CGSize(
                width: proposedSize.width > 0 ? proposedSize.width : intrinsicContentSize.width,
                height: proposedSize.height > 0 ? proposedSize.height : intrinsicContentSize.height
            )
        }()
        host.frame = CGRect(origin: .zero, size: size)
        host.content.modifier.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            host.drawHierarchy(in: host.bounds, afterScreenUpdates: true)
        }
    }
}

private struct SnapshotModifier: ViewModifier {
    var scale: CGFloat

    func body(content: Content) -> some View {
        content.environment(\.displayScale, scale)
    }
}

#endif
