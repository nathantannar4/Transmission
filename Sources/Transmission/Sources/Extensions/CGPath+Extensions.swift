//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension CGPath {
    static func roundedRect(
        bounds: CGRect,
        topLeft: CGFloat = 0,
        topRight: CGFloat = 0,
        bottomLeft: CGFloat = 0,
        bottomRight: CGFloat = 0
    ) -> CGPath {

        let path = UIBezierPath()
        path.move(
            to: CGPoint(x: bounds.minX + topLeft, y: bounds.minY)
        )
        path.addLine(
            to: CGPoint(x: bounds.maxX - topRight, y: bounds.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX, y: bounds.minY + topRight),
            controlPoint: CGPoint(x: bounds.maxX, y: bounds.minY)
        )
        path.addLine(
            to: CGPoint(x: bounds.maxX, y: bounds.maxY - bottomRight)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX - bottomRight, y: bounds.maxY),
            controlPoint: CGPoint(x: bounds.maxX, y: bounds.maxY)
        )
        path.addLine(
            to: CGPoint(x: bounds.minX + bottomLeft, y: bounds.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX, y: bounds.maxY - bottomLeft),
            controlPoint: CGPoint(x: bounds.minX, y: bounds.maxY)
        )
        path.addLine(
            to: CGPoint(x: bounds.minX, y: bounds.minY + topLeft)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX + topLeft, y: bounds.minY),
            controlPoint: CGPoint(x: bounds.minX, y: bounds.minY)
        )
        path.close()

        return path.cgPath
    }
}

#endif
