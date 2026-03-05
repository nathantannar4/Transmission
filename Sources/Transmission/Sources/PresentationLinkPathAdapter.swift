//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A modifier that manages the presentation of destination views from a ``PresentationLinkPath``
///
/// > Tip: You can support deep linking to multiple views with this modifier
///
@available(iOS 14.0, *)
public struct PresentationLinkPathAdapterModifier<Value: Sendable, Destination: View>: ViewModifier {

    @Binding var path: PresentationLinkPath<Value>
    var transition: (Value) -> PresentationLinkTransition
    var destination: (Value) -> Destination
    var index: Int

    public init(
        path: Binding<PresentationLinkPath<Value>>,
        transition: @escaping (Value) -> PresentationLinkTransition,
        destination: @escaping (Value) -> Destination
    ) {
        self._path = path
        self.transition = transition
        self.destination = destination
        self.index = 0
    }

    init(
        path: Binding<PresentationLinkPath<Value>>,
        transition: @escaping (Value) -> PresentationLinkTransition,
        destination: @escaping (Value) -> Destination,
        index: Int
    ) {
        self._path = path
        self.transition = transition
        self.destination = destination
        self.index = index
    }

    public func body(content: Content) -> some View {
        content
            .presentation(
                $path[index],
                transition: path[index].map { transition($0) } ?? .default
            ) { $value in
                destination(value)
                    .modifier(
                        PresentationLinkPathAdapterModifier(
                            path: $path,
                            transition: transition,
                            destination: destination,
                            index: index + 1,
                        )
                    )
            }
    }
}

@available(iOS 14.0, *)
extension View {

    public func presentation<Value, Destination: View>(
        path: Binding<PresentationLinkPath<Value>>,
        transition: @escaping (Value) -> PresentationLinkTransition = { _ in .default },
        destination: @escaping (Value) -> Destination
    ) -> some View {
        modifier(
            PresentationLinkPathAdapterModifier(
                path: path,
                transition: transition,
                destination: destination
            )
        )
    }
}

#endif
