//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
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

@available(iOS 14.0, *)
@frozen
public struct DestinationLinkPath<Value: Sendable>: Sendable, RandomAccessCollection {

    @available(iOS 14.0, *)
    @frozen
    public struct ID: Hashable, Sendable {
        var seed: Seed
    }

    @usableFromInline
    struct Storage: Sendable {
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

    public mutating func append(_ values: Value...) {
        path.append(contentsOf: values.map({ Storage(value: $0) }))
    }

    public mutating func pop(count: Int = 1) {
        path.removeLast(Swift.min(path.count, count))
    }

    public func id(for index: Index) -> ID {
        path[index].id
    }

    public var ids: Set<ID> {
        Set(indices.map({ id(for: $0) }))
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
extension IndexedDestinationLinkPath: Equatable where Value: Equatable { }

@available(iOS 14.0, *)
extension DestinationLinkPath: Equatable where Value: Equatable { }

@available(iOS 14.0, *)
extension DestinationLinkPath.Storage: Equatable where Value: Equatable { }

#endif
