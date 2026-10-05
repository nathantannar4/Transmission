//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

open class UIVisualEffectViewContainer: UIVisualEffectView {

    private var wrappedView: UIView {
        willSet {
            guard newValue !== wrappedView else { return }
            wrappedView.removeFromSuperview()
        }
        didSet {
            guard oldValue !== wrappedView else { return }
            contentView.addSubview(wrappedView)
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public init(wrappedView: UIView, effect: UIVisualEffect?) {
        self.wrappedView = wrappedView
        super.init(effect: effect)
        contentView.addSubview(wrappedView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        wrappedView.frame = contentView.bounds
    }

    open override var intrinsicContentSize: CGSize {
        return wrappedView.intrinsicContentSize
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return wrappedView.sizeThatFits(size)
    }

    open override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return wrappedView.systemLayoutSizeFitting(targetSize)
    }

    open override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        wrappedView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }
}

#endif
