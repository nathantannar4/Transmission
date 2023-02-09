//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that presents a destination view in a new `UIWindow`.
///
/// The destination view is presented with the provided `transition`
/// and `level`. By default, the ``WindowLinkTransition/opacity``
/// transition and ``WindowLinkLevel/default`` are used.
///
/// See Also:
///  - ``WindowLinkTransition``
///  - ``WindowLinkLevel``
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct WindowLink<
    Label: View,
    Destination: View
>: View {

    var level: WindowLinkLevel
    var transition: WindowLinkTransition
    var label: Label
    var destination: Destination

    @StateOrBinding var isPresented: Bool

    public init(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.level = level
        self.transition = transition
        self.label = label()
        self.destination = destination()
        self._isPresented = .init(false)
    }

    public init(
        level: WindowLinkLevel = .default,
        transition: WindowLinkTransition = .opacity,
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.level = level
        self.transition = transition
        self.label = label()
        self.destination = destination()
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        Button {
            withAnimation {
                isPresented = true
            }
        } label: {
            label
        }
        .modifier(
            WindowLinkModifier(
                level: level,
                transition: transition,
                isPresented: $isPresented,
                destination: destination
            )
        )
    }
}

#endif
