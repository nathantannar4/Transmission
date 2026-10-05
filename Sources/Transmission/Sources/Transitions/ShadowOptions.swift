//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

@frozen
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

    public static let feather = ShadowOptions(
        shadowOpacity: 0.05,
        shadowRadius: 12
    )

    public static let clear = ShadowOptions(
        shadowOpacity: 0,
        shadowRadius: 0,
        shadowColor: .clear
    )
}

@frozen
public struct ShadowOptionsModifier: ViewModifier {

    public var options: ShadowOptions

    @inlinable
    public init(options: ShadowOptions) {
        self.options = options
    }

    public func body(content: Content) -> some View {
        content
            .shadow(
                color: options.shadowColor.opacity(Double(options.shadowOpacity)),
                radius: options.shadowRadius,
                x: options.shadowOffset.width,
                y: options.shadowOffset.height
            )
    }
}

extension View {

    @inlinable
    public func shadow(_ options: ShadowOptions) -> some View {
        modifier(ShadowOptionsModifier(options: options))
    }
}

extension UIView {

    public func setShadow(_ options: ShadowOptions) {
        layer.setShadow(options)
    }
}

extension CALayer {

    public func setShadow(_ options: ShadowOptions) {
        shadowOpacity = options.shadowOpacity
        shadowRadius = options.shadowRadius
        shadowOffset = options.shadowOffset
        shadowColor = options.shadowColor.toCGColor()
    }
}

#endif
