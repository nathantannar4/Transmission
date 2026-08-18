//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
@frozen
public struct PresentationLinkPath<Value>: RandomAccessCollection {

    @frozen
    public struct ID: Hashable {
        var seed: Seed
    }

    @usableFromInline
    struct Storage {
        var id: ID = .init(seed: Seed.generate())
        var value: Value
    }
    private var path: [Storage]

    public init() {
        self.path = []
    }

    public init<Values: Collection>(path: Values) where Values.Element == Value {
        self.path = path.map({ Storage(value: $0) })
    }

    public mutating func append(_ value: Value) {
        path.append(Storage(value: value))
    }

    public mutating func append(_ values: [Value]) {
        path.append(contentsOf: values.map({ Storage(value: $0) }))
    }

    public mutating func append(_ values: Value...) {
        path.append(contentsOf: values.map({ Storage(value: $0) }))
    }

    public mutating func pop(count: Int = 1) {
        path.removeLast(Swift.min(path.count, count))
    }

    public func id(for index: Index) -> ID {
        path[index].id
    }

    public var ids: [ID] {
        indices.map({ id(for: $0) })
    }

    public nonisolated subscript(id: ID) -> Value? {
        get { path.first(where: { $0.id == id })?.value }
        set {
            if let newValue {
                if let index = path.firstIndex(where: { $0.id == id }) {
                    path[index].value = newValue
                } else {
                    append(newValue)
                }
            } else if let index = path.firstIndex(where: { $0.id == id }) {
                path.remove(at: index)
            }
        }
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
            return path[position].value
        }
        set {
            if let newValue {
                if path.indices.contains(position) {
                    path[position].value = newValue
                } else {
                    path.insert(Storage(value: newValue), at: position)
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


@available(iOS 14.0, *)
extension PresentationLinkPath.Storage: Equatable where Value: Equatable { }

#endif
