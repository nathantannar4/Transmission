//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import Foundation

/// The primary action of the ``MenuLink``/``MenuSourceViewLink``
@frozen
@available(iOS 14.0, *)
public enum MenuLinkPrimaryAction {

    /// The primary action is disabled, and the menu will pass through touches to the label
    case disabled

    /// Show the menu on tap
    case showMenu

    /// A custom handler on tap
    case custom(@MainActor () -> Void)
}

#endif
