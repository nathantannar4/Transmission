//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

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
