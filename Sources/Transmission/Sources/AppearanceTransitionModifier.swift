//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct AppearanceTransitionModifier: ViewModifier {
    var transition: AnyTransition
    var animation: Animation?
    @StateOrBinding var isPresented: Bool

    public init(transition: AnyTransition, animation: Animation?) {
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(false)
    }

    public init(transition: AnyTransition, animation: Animation?, isPresented: Binding<Bool>) {
        self.transition = transition
        self.animation = animation
        self._isPresented = .init(isPresented)
    }

    public func body(content: Content) -> some View {
        ViewAdapter {
            if isPresented {
                content.transition(transition)
            }
        }
        .animation(animation, value: isPresented)
        .onAppear { isPresented = true }
        .onDisappear { isPresented = false }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {
    public func appearanceTransition(
        _ transition: AnyTransition,
        animation: Animation? = .default
    ) -> some View {
        modifier(
            AppearanceTransitionModifier(
                transition: transition,
                animation: animation
            )
        )
    }

    public func appearanceTransition(
        _ transition: AnyTransition,
        animation: Animation? = .default,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            AppearanceTransitionModifier(
                transition: transition,
                animation: animation,
                isPresented: isPresented
            )
        )
    }
}
