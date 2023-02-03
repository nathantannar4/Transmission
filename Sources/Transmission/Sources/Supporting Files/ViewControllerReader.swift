//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

final class ViewControllerReader: UIView {
    let presentingViewController: Binding<UIViewController?>

    init(presentingViewController: Binding<UIViewController?>) {
        self.presentingViewController = presentingViewController
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
            self.presentingViewController.wrappedValue = self.viewController
        }
    }
}

#endif
