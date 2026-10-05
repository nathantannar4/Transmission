//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

extension UIResponder {

    func becomeFirstResponder(alongsideTransition transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        var didRegister = false
        if let transitionCoordinator {
            if transitionCoordinator.isInteractive {
                transitionCoordinator.notifyWhenInteractionChanges { [weak self] ctx in
                    if !ctx.isInteractive {
                        UIView.performWithoutAnimation {
                            self?.becomeFirstResponder()
                        }
                    }
                }
            }
            didRegister = transitionCoordinator.animate { [weak self] ctx in
                if !ctx.isInteractive {
                    UIView.performWithoutAnimation {
                        self?.becomeFirstResponder()
                    }
                }
            } completion: { [weak self] ctx in
                if !ctx.isCancelled {
                    self?.becomeFirstResponder()
                }
            }
        }
        if !didRegister {
            withCATransaction { [weak self] in
                self?.becomeFirstResponder()
            }
        }
    }
}

#endif
