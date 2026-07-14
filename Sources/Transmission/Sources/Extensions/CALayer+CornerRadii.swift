//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import QuartzCore
import ObjectiveC

/// The layout of CoreAnimation's `CACornerRadii`.
///
/// Four `CGSize`, since a corner may be elliptical, ordered bottom left, bottom right,
/// top right, top left. The order is not top left first; transposing it silently rotates
/// the corners.
private struct CACornerRadii {
    var minXMaxY: CGSize // Bottom left
    var maxXMaxY: CGSize // Bottom right
    var maxXMinY: CGSize // Top right
    var minXMinY: CGSize // Top left
}

extension CALayer {

    /// Whether CoreAnimation supports a radius per corner. `true` on iOS 16 and later.
    ///
    /// Detected from the ObjC property rather than a key value round trip, since on iOS 15
    /// and earlier `CALayer`'s key value store accepts and returns the value with no effect
    /// on rendering, making a round trip report a false positive.
    static let supportsCornerRadii: Bool = {
        guard let key = cornerRadiiKey else { return false }
        return class_getProperty(CALayer.self, key) != nil
    }()

    /// Whether a radius per corner has been set on this layer.
    ///
    /// Once one has, CoreAnimation ignores `cornerRadius` on the layer permanently, so every
    /// subsequent update, including a uniform radius or `identity`, needs to keep driving all
    /// four corners. A layer cannot be returned to `cornerRadius`.
    var usesCornerRadii: Bool {
        get {
            objc_getAssociatedObject(self, CALayer.usesCornerRadiiKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                CALayer.usesCornerRadiiKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    func setCornerRadii(_ cornerRadii: CornerRadiusOptions.CornerRadii) {
        guard
            CALayer.supportsCornerRadii,
            let key = CALayer.cornerRadiiKey,
            let objCType = CALayer.cornerRadiiObjCType
        else {
            return
        }
        let value = CACornerRadii(
            minXMaxY: CGSize(width: cornerRadii.bottomLeft, height: cornerRadii.bottomLeft),
            maxXMaxY: CGSize(width: cornerRadii.bottomRight, height: cornerRadii.bottomRight),
            maxXMinY: CGSize(width: cornerRadii.topRight, height: cornerRadii.topRight),
            minXMinY: CGSize(width: cornerRadii.topLeft, height: cornerRadii.topLeft)
        )
        let box = withUnsafeBytes(of: value) { bytes in
            objCType.withCString { objCType in
                NSValue(bytes: bytes.baseAddress!, objCType: objCType)
            }
        }
        setValue(box, forKey: key)
        if cornerRadii != .zero {
            usesCornerRadii = true
        }
    }

    func cornerRadii() -> CornerRadiusOptions.CornerRadii? {
        guard
            CALayer.supportsCornerRadii,
            let key = CALayer.cornerRadiiKey,
            let box = value(forKey: key) as? NSValue
        else {
            return nil
        }
        var value = CACornerRadii(
            minXMaxY: .zero,
            maxXMaxY: .zero,
            maxXMinY: .zero,
            minXMinY: .zero
        )
        withUnsafeMutableBytes(of: &value) { bytes in
            box.getValue(bytes.baseAddress!, size: MemoryLayout<CACornerRadii>.size)
        }
        return CornerRadiusOptions.CornerRadii(
            topLeft: value.minXMinY.width,
            topRight: value.maxXMinY.width,
            bottomLeft: value.minXMaxY.width,
            bottomRight: value.maxXMaxY.width
        )
    }

    private static let cornerRadiiKey: String? = NSStringFromBase64EncodedString(
        "Y29ybmVyUmFkaWk="
    )

    private static let cornerRadiiObjCType: String? = NSStringFromBase64EncodedString(
        "e0NBQ29ybmVyUmFkaWk9e0NHU2l6ZT1kZH17Q0dTaXplPWRkfXtDR1NpemU9ZGR9e0NHU2l6ZT1kZH19"
    )

    // A unique address, used only as an associated object key.
    private nonisolated(unsafe) static let usesCornerRadiiKey = UnsafeRawPointer(
        UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    )
}

#endif
