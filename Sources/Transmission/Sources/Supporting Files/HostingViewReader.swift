//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

final class HostingViewReader: UIView {
    let host: Binding<UIView?>?
    let presentingViewController: Binding<UIViewController?>

    init(host: Binding<UIView?>? = nil, presentingViewController: Binding<UIViewController?>) {
        self.host = host
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
            self?.presentingViewController.wrappedValue = self?.viewController
            self?.host?.wrappedValue = self?.hostingView
        }
    }
}

#endif
