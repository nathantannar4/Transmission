//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

final class WindowReader: UIView {
    let presentingWindow: Binding<UIWindow?>

    init(presentingWindow: Binding<UIWindow?>) {
        self.presentingWindow = presentingWindow
        super.init(frame: .zero)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        withCATransaction { [weak self] in
            guard let self = self else {
                return
            }
            self.presentingWindow.wrappedValue = self.window
        }
    }
}

#endif
