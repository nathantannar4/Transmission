//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import QuartzCore
import ObjectiveC

extension CACornerMask {

    static let all: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMinXMinYCorner
    ]

    static let topLeft: CACornerMask = .layerMinXMinYCorner

    static let topRight: CACornerMask = .layerMaxXMinYCorner

    static let bottomLeft: CACornerMask = .layerMinXMaxYCorner

    static let bottomRight: CACornerMask = .layerMaxXMaxYCorner
}

extension CALayer {

    struct CACornerRadiiLayout {
        var bottomLeft: CGSize
        var bottomRight: CGSize
        var topRight: CGSize
        var topLeft: CGSize
    }

    /// Whether a radius per corner has been set on this layer.
    ///
    /// Once one has, CoreAnimation ignores `cornerRadius` on the layer permanently, so every
    /// subsequent update, including a uniform radius or `identity`, needs to keep driving all
    /// four corners. A layer cannot be returned to `cornerRadius`.
    ///
    /// UIKit will set the `cornerRadii` automatically when a `UICornerConfiguration` is applied to the view
    ///
    var hasCornerRadii: Bool {
        guard
            // _usesCornerRadii
            let aSelector = NSStringFromBase64EncodedString("X3VzZXNDb3JuZXJSYWRpaQ=="),
            responds(to: NSSelectorFromString(aSelector)),
            let value = value(forKey: aSelector) as? Bool
        else {
            return false
        }
        return value
    }

    @MainActor
    @available(iOS 16.0, *)
    func fixCornerRadiiAnimation() {
        if UIView.inheritedAnimationDuration > 0, !hasCornerRadii {
            // Fix animation when transitioning to using a `cornerRadii`
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cornerRadii = CornerRadiusOptions.CornerRadii(cornerRadius: cornerRadius)
            CATransaction.commit()
        }
    }

    @available(iOS 16.0, *)
    var cornerRadii: CornerRadiusOptions.CornerRadii? {
        get {
            guard
                hasCornerRadii,
                let key = CALayer.cornerRadiiKey,
                class_getProperty(CALayer.self, key) != nil,
                let box = value(forKey: key) as? NSValue
            else {
                return nil
            }
            var value = CACornerRadiiLayout(
                bottomLeft: .zero,
                bottomRight: .zero,
                topRight: .zero,
                topLeft: .zero
            )
            withUnsafeMutableBytes(of: &value) { bytes in
                box.getValue(bytes.baseAddress!, size: MemoryLayout<CACornerRadiiLayout>.size)
            }
            return CornerRadiusOptions.CornerRadii(
                topLeading: value.topLeft.width,
                bottomLeading: value.bottomLeft.width,
                bottomTrailing: value.bottomRight.width,
                topTrailing: value.topRight.width,
            )
        }
        set {
            guard
                let key = CALayer.cornerRadiiKey,
                class_getProperty(CALayer.self, key) != nil,
                let CACornerRadiiType = CALayer.cornerRadiiObjCType,
                newValue != nil || hasCornerRadii
            else {
                return
            }
            if let newValue {
                let value = CACornerRadiiLayout(
                    bottomLeft: CGSize(width: newValue.bottomLeading, height: newValue.bottomLeading),
                    bottomRight: CGSize(width: newValue.bottomTrailing, height: newValue.bottomTrailing),
                    topRight: CGSize(width: newValue.topTrailing, height: newValue.topTrailing),
                    topLeft: CGSize(width: newValue.topLeading, height: newValue.topLeading)
                )
                let box = withUnsafeBytes(of: value) { bytes in
                    CACornerRadiiType.withCString { objCType in
                        NSValue(bytes: bytes.baseAddress!, objCType: objCType)
                    }
                }
                setValue(box, forKey: key)
            } else {
                setValue(nil, forKey: key)
            }
        }
    }

    // cornerRadii
    private static let cornerRadiiKey: String? = NSStringFromBase64EncodedString(
        "Y29ybmVyUmFkaWk="
    )

    // {CACornerRadii={CGSize=dd}{CGSize=dd}{CGSize=dd}{CGSize=dd}}
    private static let cornerRadiiObjCType: String? = NSStringFromBase64EncodedString(
        "e0NBQ29ybmVyUmFkaWk9e0NHU2l6ZT1kZH17Q0dTaXplPWRkfXtDR1NpemU9ZGR9e0NHU2l6ZT1kZH19"
    )

    nonisolated(unsafe) private static var hasCornerRadiiKey: UInt = 0
}

#endif
