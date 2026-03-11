//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
@frozen
public struct PresentationLinkPath<Value: Sendable>: Sendable, RandomAccessCollection {
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

    public mutating func append(_ values: Value...) {
        path.append(contentsOf: values)
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

@available(iOS 14.0, *)
extension PresentationLinkPath: Equatable where Value: Equatable { }

#endif
