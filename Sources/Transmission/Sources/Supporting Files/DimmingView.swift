//
// Copyright (c) Nathan Tannar
//

import UIKit

open class DimmingView: UIView {

    var shouldBlockTouches: Bool = false

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        backgroundColor = UIColor.black.withAlphaComponent(0.12)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return shouldBlockTouches ? self : super.hitTest(point, with: event)
    }
}
