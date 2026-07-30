//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
public enum SnapshotRendererColorSpace {
    // The extended linear sRGB working color space.
    case extendedLinear

    // The linear sRGB working color space.
    case linear

    // The non-linear sRGB working color space.
    case nonLinear

    func toCoreGraphics() -> CGColorSpace {
        switch self {
        case .extendedLinear:
            return CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
        case .linear:
            return CGColorSpace(name: CGColorSpace.linearSRGB)!
        case .nonLinear:
            return CGColorSpace(name: CGColorSpace.sRGB)!
        }
    }

    func toUIKit() -> UIGraphicsImageRendererFormat.Range {
        switch self {
        case .extendedLinear:
            return .extended
        case .linear, .nonLinear:
            return .standard
        }
    }
}

/// A backwards compatible port of `ImageRenderer`
///
/// See Also:
///  - ``SnapshotItemProvider``
///
@MainActor
@available(iOS 14.0, *)
public final class SnapshotRenderer<Content: View>: ObservableObject {

    public var content: Content {
        get { host.content.content }
        set {
            host.content.content = newValue
            objectWillChange.send()
        }
    }

    public var scale: CGFloat {
        get { host.content.modifier.scale }
        set {
            guard scale != newValue else { return }
            host.content.modifier.scale = newValue
            host.contentScaleFactor = newValue
            host.layer.contentsScale = newValue
            objectWillChange.send()
        }
    }

    public var isOpaque: Bool {
        get { host.layer.isOpaque }
        set {
            guard isOpaque != newValue else { return }
            host.layer.isOpaque = newValue
            objectWillChange.send()
        }
    }

    public var colorSpace: SnapshotRendererColorSpace = .nonLinear

    public var proposedSize: ProposedSize = .unspecified

    private let host: HostingView<ModifiedContent<Content, SnapshotRendererModifier>>
    private var window: UIWindow?

    public init(content: Content) {
        let host = HostingView(content: content.modifier(SnapshotRendererModifier(scale: 1)))
        host.disablesSafeArea = true
        host.contentScaleFactor = 1
        host.layer.contentsScale = 1
        host.layer.isOpaque = false
        self.host = host
    }

    public func render<Result>(
        renderer: (CGSize, (CGContext) -> Void) -> Result
    ) -> Result {
        let size: CGSize = {
            let intrinsicContentSize = host.intrinsicContentSize
            return CGSize(
                width: proposedSize.width ?? intrinsicContentSize.width,
                height: proposedSize.height ?? intrinsicContentSize.height
            )
        }()
        host.frame = CGRect(origin: .zero, size: size)
        if window == nil {
            window = UIWindow()
            window?.isHidden = true
            window?.addSubview(host)
        }
        host.render()
        return renderer(host.frame.size) { context in
            host.layer.render(in: context)
        }
    }

    public var cgImage: CGImage? {
        render { size, callback in
            let context = CGContext(
                data: nil,
                width: Int((size.width * scale).rounded()),
                height: Int((size.height * scale).rounded()),
                bitsPerComponent: 8,
                bytesPerRow: 0, // Calculated automatically
                space: colorSpace.toCoreGraphics(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            guard let context else {
                return nil
            }
            context.concatenate(
                CGAffineTransform(a: scale, b: 0, c: 0, d: -scale, tx: 0, ty: CGFloat(context.height))
            )
            callback(context)
            let image = context.makeImage()
            return image
        }
    }

    public var uiImage: UIImage? {
        render { size, callback in
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.opaque = isOpaque
            format.preferredRange = colorSpace.toUIKit()
            let renderer = UIGraphicsImageRenderer(
                size: size,
                format: format
            )
            return renderer.image { context in
                callback(context.cgContext)
            }
        }
    }
}

private struct SnapshotRendererModifier: ViewModifier {
    var scale: CGFloat

    func body(content: Content) -> some View {
        content.environment(\.displayScale, scale)
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct SnapshotRenderer_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var snapshotRenderer = {
            let renderer = SnapshotRenderer(content: Snapshot())
            renderer.scale = 3
            return renderer
        }()
        @StateObject var imageRenderer = {
            let renderer = ImageRenderer(content: Snapshot())
            renderer.scale = 3
            return renderer
        }()

        var body: some View {
            VStack {
                Snapshot()

                if let image = snapshotRenderer.uiImage {
                    Image(uiImage: image)
                }

                if let image = snapshotRenderer.cgImage {
                    Image(decorative: image, scale: snapshotRenderer.scale)
                }

                if let image = imageRenderer.uiImage {
                    Image(uiImage: image)
                }

                if let image = imageRenderer.cgImage {
                    Image(decorative: image, scale: imageRenderer.scale)
                }
            }
        }

        struct Snapshot: View {
            @Environment(\.displayScale) var displayScale
            var body: some View {
                Text("Hello, World \(displayScale)")
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
