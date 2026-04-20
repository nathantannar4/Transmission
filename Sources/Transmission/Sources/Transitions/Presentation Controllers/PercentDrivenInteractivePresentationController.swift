//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

public protocol PercentDrivenInteractivePresentationController: UIPresentationController {
    var transition: UIPercentDrivenInteractiveTransition? { get }

    func attach(to transition: UIPercentDrivenInteractiveTransition)
}

#endif
