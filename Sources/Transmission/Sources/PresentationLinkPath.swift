//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@frozen
public struct PresentationLinkPath<Value: Sendable>: Sendable {
    private var path: [Value]

    public init() {
        self.path = []
    }

    public init<Values: Collection>(path: Values) where Values.Element == Value {
        self.path = Array(path)
    }

    public subscript(index: Int) -> Value? {
        get {
            guard path.indices.contains(index) else { return nil }
            return path[index]
        }
        set {
            if let newValue {
                if path.indices.contains(index) {
                    path[index] = newValue
                } else {
                    path.insert(newValue, at: index)
                }
            } else if path.indices.contains(index) {
                path.remove(at: index)
            }
        }
    }

    public var count: Int {
        path.count
    }

    public var isEmpty: Bool {
        path.isEmpty
    }

    public mutating func append(_ value: Value) {
        path.append(value)
    }

    public mutating func pop(count: Int = 1) {
        path.removeLast(min(path.count, count))
    }
}

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
        transition: @escaping (Value) -> PresentationLinkTransition,
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
