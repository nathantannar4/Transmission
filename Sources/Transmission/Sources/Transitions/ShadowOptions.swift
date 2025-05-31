//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public struct ShadowOptions: Equatable, Sendable {
    public var shadowOpacity: Float
    public var shadowRadius: CGFloat
    public var shadowOffset: CGSize
    public var shadowColor: Color

    public init(
        shadowOpacity: Float,
        shadowRadius: CGFloat,
        shadowOffset: CGSize = CGSize(width: 0, height: -3),
        shadowColor: Color = Color.black
    ) {
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.shadowColor = shadowColor
    }

    public static let prominent = ShadowOptions(
        shadowOpacity: 0.4,
        shadowRadius: 40
    )

    public static let minimal = ShadowOptions(
        shadowOpacity: 0.15,
        shadowRadius: 24
    )

    public static let clear = ShadowOptions(
        shadowOpacity: 0,
        shadowRadius: 0,
        shadowColor: .clear
    )

    public func apply(to layer: CALayer, progress: Double = 1) {
        layer.shadowOpacity = shadowOpacity * Float(progress)
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        layer.shadowColor = shadowColor.toCGColor()
    }
}

#endif
