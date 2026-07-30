//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

protocol WindowReaderDelegate: AnyObject {

    @MainActor @preconcurrency func windowReaderDidMoveToWindow(_ view: UIView)
}

final class WindowReader: UIView {

    weak var delegate: WindowReaderDelegate?

    init() {
        super.init(frame: .zero)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        delegate?.windowReaderDidMoveToWindow(self)
    }
}

#endif
