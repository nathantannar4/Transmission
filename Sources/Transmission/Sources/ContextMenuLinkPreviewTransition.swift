//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The transition when committing the context menu preview
@available(iOS 14.0, *)
@frozen
public struct ContextMenuLinkPreviewTransition {

    @usableFromInline
    enum Value {
        case transient
        case presentation
        case destination
        case custom(_ action: @MainActor @Sendable () -> Void)
    }
    @usableFromInline
    var value: Value

    /// A transient transition
    public static var transient: ContextMenuLinkPreviewTransition {
        ContextMenuLinkPreviewTransition(value: .transient)
    }

    /// A presention transition
    public static var presentation: ContextMenuLinkPreviewTransition {
        ContextMenuLinkPreviewTransition(value: .presentation)
    }

    /// A push transition
    public static var destination: ContextMenuLinkPreviewTransition {
        ContextMenuLinkPreviewTransition(value: .destination)
    }

    /// A custom action performed while dismissing the preview
    public static func custom(_ action: @MainActor @Sendable @escaping () -> Void) -> ContextMenuLinkPreviewTransition {
        ContextMenuLinkPreviewTransition(value: .custom(action))
    }

    public static var `default`: ContextMenuLinkPreviewTransition { .transient }
}

#endif
