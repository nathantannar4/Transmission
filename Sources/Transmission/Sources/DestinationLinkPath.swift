//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@frozen
public struct IndexedDestinationLinkPath<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private var paths: [Key: DestinationLinkPath<Value>]

    public init() {
        self.paths = [:]
    }

    public subscript(key: Key) -> DestinationLinkPath<Value> {
        get { paths[key, default: .init()] }
        set { paths[key] = newValue }
    }
}

@frozen
public struct DestinationLinkPath<Value: Sendable>: Sendable, RandomAccessCollection {
    private var path: [Value]

    public init() {
        self.path = []
    }

    public init<Values: Collection>(path: Values) where Values.Element == Value {
        self.path = Array(path)
    }

    public mutating func append(_ value: Value) {
        path.append(value)
    }

    public mutating func pop(count: Int = 1) {
        path.removeLast(Swift.min(path.count, count))
    }

    // MARK: RandomAccessCollection

    public typealias Element = Value?
    public typealias Index = Int

    public nonisolated var startIndex: Index {
        path.startIndex
    }

    public nonisolated var endIndex: Index {
        path.endIndex
    }

    public nonisolated subscript(position: Int) -> Value? {
        get {
            guard path.indices.contains(position) else { return nil }
            return path[position]
        }
        set {
            if let newValue {
                if path.indices.contains(position) {
                    path[position] = newValue
                } else {
                    path.insert(newValue, at: position)
                }
            } else if path.indices.contains(position) {
                path.remove(at: position)
            }
        }
    }

    public nonisolated func index(after index: Index) -> Index {
        path.index(after: index)
    }
}

/// A modifier that manages the push of multiple destination views from a ``DestinationLinkPath``
///
/// > Tip: You can support deep linking to multiple views with this modifier
///
@available(iOS 14.0, *)
public struct DestinationLinkPathAdapterModifier<Value: Sendable, Destination: View>: ViewModifier {

    @Binding var path: DestinationLinkPath<Value>
    var transition: (Value) -> DestinationLinkTransition
    var destination: (Value) -> Destination
    var index: Int

    public init(
        path: Binding<DestinationLinkPath<Value>>,
        transition: @escaping (Value) -> DestinationLinkTransition,
        destination: @escaping (Value) -> Destination
    ) {
        self._path = path
        self.transition = transition
        self.destination = destination
        self.index = 0
    }

    init(
        path: Binding<DestinationLinkPath<Value>>,
        transition: @escaping (Value) -> DestinationLinkTransition,
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
            .destination(
                $path[index],
                transition: path[index].map { transition($0) } ?? .default
            ) { $value in
                destination(value)
                    .modifier(
                        DestinationLinkPathAdapterModifier(
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

    public func destination<Value, Destination: View>(
        path: Binding<DestinationLinkPath<Value>>,
        transition: @escaping (Value) -> DestinationLinkTransition,
        destination: @escaping (Value) -> Destination
    ) -> some View {
        modifier(
            DestinationLinkPathAdapterModifier(
                path: path,
                transition: transition,
                destination: destination
            )
        )
    }
}

#endif
