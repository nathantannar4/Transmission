//
// Copyright (c) Nathan Tannar
//

import UIKit

open class DimmingView: UIView {

    static let backgroundColor = UIColor.black.withAlphaComponent(0.12)

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        backgroundColor = DimmingView.backgroundColor
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
