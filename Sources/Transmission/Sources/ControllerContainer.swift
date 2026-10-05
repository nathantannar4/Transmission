//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Combine
import Engine

@available(iOS 14.0, *)
public protocol ControllerContainerRepresentable {

    associatedtype Body: View
    @ViewBuilder @MainActor @preconcurrency func makeBody(configuration: Configuration) -> Body

    typealias Configuration = ControllerContainerConfiguration
}

@available(iOS 14.0, *)
@frozen
public struct ControllerContainerConfiguration: Equatable {

    public var safeAreaInsets: EdgeInsets

    public init(safeAreaInsets: EdgeInsets) {
        self.safeAreaInsets = safeAreaInsets
    }
}

/// Use to wrap a ``UIViewControllerRepresentable``, allowing the SwiftUI safe area to be passed down to the
/// ``UIViewController`` as additional safe area insets
@available(iOS 14.0, *)
public struct ControllerContainer<Representable: ControllerContainerRepresentable>: View {

    var representable: Representable

    @State private var safeAreaInsets: EdgeInsets = .zero

    public init(_ representable: Representable) {
        self.representable = representable
    }

    public var body: some View {
        let configuration = ControllerContainerConfiguration(
            safeAreaInsets: safeAreaInsets
        )
        representable.makeBody(configuration: configuration)
            .ignoresSafeArea()
            .modifier(ControllerContainerModifier(safeAreaInsets: $safeAreaInsets))
    }
}

@available(iOS 14.0, *)
private struct ControllerContainerModifier: VersionedViewModifier {
    @Binding var safeAreaInsets: EdgeInsets

    @available(iOS 16.0, *)
    func v4Body(content: Content) -> some View {
        content
            .onGeometryChange(for: EdgeInsets.self) { proxy in
                proxy.safeAreaInsets
            } action: { newValue in
                safeAreaInsets = newValue
            }
    }

    func v1Body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { safeAreaInsets = proxy.safeAreaInsets }
                        .onChange(of: proxy.safeAreaInsets) { safeAreaInsets = $0 }
                }
                .hidden()
            )
    }
}


extension UIViewController {

    public func additionalSafeAreaInsets(
        safeAreaInsets: UIEdgeInsets?
    ) -> UIEdgeInsets {
        guard
            let safeAreaInsets,
            let base = (parent?.view.safeAreaInsets ?? view.window?.safeAreaInsets)
        else {
            return .zero
        }
        var insets = safeAreaInsets
        insets.top = max(0, insets.top - base.top)
        insets.left = max(0, insets.left - base.left)
        insets.bottom = max(0, insets.bottom - base.bottom)
        insets.right = max(0, insets.right - base.right)
        return insets
    }
}

#endif
