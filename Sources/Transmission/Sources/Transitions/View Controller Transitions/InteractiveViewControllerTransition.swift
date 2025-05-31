//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class InteractiveViewControllerTransition: ViewControllerTransition {

    public override init(isPresenting: Bool, animation: Animation?) {
        super.init(isPresenting: isPresenting, animation: animation)
        wantsInteractiveStart = true
    }
}

#endif
