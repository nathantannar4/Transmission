//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A view that passes through touches of self or a `_UIHostingView`
open class PassthroughView: UIView {

    struct HitTestEvent {
        var point: CGPoint
        var timestamp: TimeInterval
    }
    private var lastHitTestEvent: HitTestEvent?
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if #available(iOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            guard let result else { return nil }
            // Hit testing on iOS 26 always seems to return self
            if result is AnyHostingView {
                // Hit test the layers
                for sublayer in result.layer.sublayers ?? [] {
                    if !sublayer.isHidden, sublayer.frame.contains(point) {
                        return result
                    }
                }

                // Check the raw pixels to support passthrough
                let size = CGSize(width: 10, height: 10)
                UIGraphicsBeginImageContextWithOptions(size, false, window?.screen.scale ?? 1)
                defer { UIGraphicsEndImageContext() }
                guard let context = UIGraphicsGetCurrentContext() else {
                    return result
                }

                context.translateBy(x: -point.x + size.width / 2, y: -point.y + size.height / 2)
                result.layer.render(in: context)

                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                guard
                    let cgImage = image?.cgImage,
                    let data = cgImage.dataProvider?.data,
                    let ptr = CFDataGetBytePtr(data)
                else {
                    return result
                }

                let bytesPerPixel = 4
                let width = cgImage.width
                let height = cgImage.height

                for y in 0..<height {
                    for x in 0..<width {
                        let offset = (y * width + x) * bytesPerPixel
                        let alpha = ptr[offset + 3]
                        if alpha > 0 {
                            return result
                        }
                    }
                }
                return nil
            }
        } else if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            defer {
                lastHitTestEvent = event.map {
                    HitTestEvent(
                        point: point,
                        timestamp: $0.timestamp
                    )
                }
            }
            if result is AnyHostingView,
                lastHitTestEvent?.timestamp != event?.timestamp || lastHitTestEvent?.point != point
            {
                return nil
            }
        } else if result is AnyHostingView {
            return nil
        }
        return result == self ? nil : result
    }
}

#endif
