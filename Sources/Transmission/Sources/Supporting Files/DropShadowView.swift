//
// Copyright (c) Nathan Tannar
//

import UIKit

@available(iOS 14.0, *)
open class DropShadowView: UIView {

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        ShadowOptions.feather.apply(to: self)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = CGPath(rect: bounds, transform: nil)
    }
}
