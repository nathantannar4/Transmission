//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The transition when committing the context menu preview
@available(iOS 14.0, *)
@frozen
public struct ContextMenuLinkPreviewTransition: Sendable {

    @usableFromInline
    enum Value: Sendable {
        case transient
        case presentation
        case destination
        case custom(_ action: @MainActor @Sendable () -> Void)
    }
    @usableFromInline
    var value: Value

    /// A transient transition
    public static let transient = ContextMenuLinkPreviewTransition(value: .transient)

    /// A presention transition
    public static let presentation = ContextMenuLinkPreviewTransition(value: .presentation)

    /// A push transition
    public static let destination = ContextMenuLinkPreviewTransition(value: .destination)

    /// A custom action performed while dismissing the preview
    public static func custom(_ action: @MainActor @Sendable @escaping () -> Void) -> ContextMenuLinkPreviewTransition {
        ContextMenuLinkPreviewTransition(value: .custom(action))
    }

    public static var `default`: ContextMenuLinkPreviewTransition { .transient }
}

#endif
