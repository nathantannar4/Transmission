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
@MainActor
public final class SnapshotRenderer<Content: View>: ObservableObject {

    public var content: Content {
        get { host.content.content }
        set {
            host.content.content = newValue
            objectWillChange.send()
        }
    }

    public var scale: CGFloat {
        get { host.contentScaleFactor }
        set {
            host.contentScaleFactor = newValue
            host.layer.contentsScale = newValue
            host.content.modifier.scale = newValue
        }
    }

    public var isOpaque: Bool {
        get { host.layer.isOpaque }
        set {
            host.layer.isOpaque = newValue
            objectWillChange.send()
        }
    }

    public var colorSpace: SnapshotRendererColorSpace = .nonLinear

    public var proposedSize: ProposedSize = .unspecified

    private let host: HostingView<ModifiedContent<Content, SnapshotRendererModifier>>

    public init(content: Content) {
        let host = HostingView(
            content: content.modifier(SnapshotRendererModifier(scale: 1))
        )
        host.disablesSafeArea = true
        host.layer.shouldRasterize = true
        self.host = host
        isOpaque = false
        scale = 1
    }

    public func render<Result>(
        rasterizationScale: CGFloat = 1,
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
        host.layer.rasterizationScale = rasterizationScale
        host.render()
        return renderer(host.frame.size, { context in
            host.layer.render(in: context)
        })
    }

    public var cgImage: CGImage? {
        render { size, callback in
            let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: 0, // Calculated automatically
                space: colorSpace.toCoreGraphics(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            guard let context else {
                return nil
            }
            context.concatenate(
                CGAffineTransformMake(1, 0, 0, -1, 0, CGFloat(context.height))
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
        @StateObject var rendererA = SnapshotRenderer(content: Snapshot())
        @StateObject var rendererC = ImageRenderer(content: Snapshot())

        var body: some View {
            VStack {
                VStack {
                    Snapshot()

                    if let contentA = rendererA.uiImage {
                        Image(uiImage: contentA)
                    }


                    if let contentC = rendererC.uiImage {
                        Image(uiImage: contentC)
                    }
                }
            }
        }

        struct Snapshot: View {
            @Environment(\.displayScale) var displayScale
            var body: some View {
                Text("Hello, World")
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
