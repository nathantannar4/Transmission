//
// Copyright (c) Nathan Tannar
//

import Foundation

protocol UnsafeReflectable {
    mutating func unsafeGetValue<T>(_ type: T.Type, forKey key: String) throws -> T
    mutating func unsafeSetValue<T>(_ value: T, forKey key: String) throws
}

struct ReflectableKeyNotFound: Error, CustomStringConvertible {
    var type: Any.Type
    var key: String

    var description: String {
        "\(key) was not found on type \(String(describing: type))"
    }
}

extension NSObject: UnsafeReflectable { }

extension UnsafeReflectable where Self: AnyObject {
    @discardableResult
    func unsafeGetValue<T>(_ : T.Type, forKey key: String) throws -> T {
        var this = self
        return try this._unsafeGetValue(T.self, forKey: key)
    }

    func unsafeSetValue<T>(_ value: T, forKey key: String) throws {
        var this = self
        return try this._unsafeSetValue(value, forKey: key)
    }
}

extension UnsafeReflectable {
    @discardableResult
    mutating func unsafeGetValue<T>(_ : T.Type, forKey key: String) throws -> T {
        try _unsafeGetValue(T.self, forKey: key)
    }

    mutating func unsafeSetValue<T>(_ value: T, forKey key: String) throws {
        try _unsafeSetValue(value, forKey: key)
    }

    func unsafeKeys() -> [(key: String, value: Any)] {
        let m = Mirror(reflecting: self)
        return m.children.compactMap({
            guard let key = $0.label else {
                return nil
            }
            return (key, $0.value)
        })
    }

    private mutating func _unsafeGetValue<T>(_ : T.Type, forKey key: String) throws -> T {
        if let field = field(forKey: key) {
            return try withUnsafePointer { pointer in
                func project<S>(_ type: S.Type) -> T {
                    let buffer = pointer.advanced(by: field.offset).assumingMemoryBound(to: S.self)
                    return buffer.pointee as! T
                }
                return _openExistential(field.type, do: project)
            }
        }
        throw ReflectableKeyNotFound(type: T.self, key: key)
    }

    private mutating func _unsafeSetValue<T>(_ value: T, forKey key: String) throws {
        if let field = field(forKey: key) {
            try withUnsafePointer { pointer in
                func project<S>(_ type: S.Type) {
                    let buffer = pointer.advanced(by: field.offset).assumingMemoryBound(to: S.self)
                    Swift.withUnsafePointer(to: value) { ptr in
                        ptr.withMemoryRebound(to: S.self, capacity: 1) { ptr in
                            buffer.pointee = ptr.pointee
                        }
                    }
                }
                _openExistential(field.type, do: project)
            }
        } else {
            throw ReflectableKeyNotFound(type: T.self, key: key)
        }
    }

    private func field(forKey key: String) -> (type: Any.Type, offset: Int)? {
        let type = type(of: self)
        let count = swift_reflectionMirror_recursiveCount(type)
        for i in 0..<count {
            var field = FieldReflectionMetadata()
            let fieldType = swift_reflectionMirror_recursiveChildMetadata(type, index: i, fieldMetadata: &field)
            defer { field.dealloc?(field.name) }
            guard
                let name = field.name.map({ String(utf8String: $0) }),
                name == key
            else {
                continue
            }

            let offset = swift_reflectionMirror_recursiveChildOffset(type, index: i)
            return (fieldType, offset)
        }
        return nil
    }

    private mutating func withUnsafePointer<Result>(
        _ body: (UnsafeMutableRawPointer) throws -> Result
    ) throws -> Result {
        if swift_isClassType(Self.self) {
            return try Swift.withUnsafePointer(to: &self) {
                try $0.withMemoryRebound(to: UnsafeMutableRawPointer.self, capacity: 1) {
                    try body($0.pointee)
                }
            }
        } else {
            return try Swift.withUnsafePointer(to: &self) {
                let pointer = UnsafeMutableRawPointer(mutating: $0)
                return try body(pointer)
            }
        }
    }
}

private typealias Dealloc = @convention(c) (UnsafePointer<CChar>?) -> Void

private struct FieldReflectionMetadata {
    let name: UnsafePointer<CChar>? = nil
    let dealloc: Dealloc? = nil
    let isStrong: Bool = false
    let isVar: Bool = false
}

@_silgen_name("swift_isClassType")
private func swift_isClassType(_: Any.Type) -> Bool

@_silgen_name("swift_reflectionMirror_recursiveCount")
private func swift_reflectionMirror_recursiveCount(_: Any.Type) -> Int

@_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
private func swift_reflectionMirror_recursiveChildMetadata(
    _: Any.Type
    , index: Int
    , fieldMetadata: UnsafeMutablePointer<FieldReflectionMetadata>
) -> Any.Type

@_silgen_name("swift_reflectionMirror_recursiveChildOffset")
private func swift_reflectionMirror_recursiveChildOffset(_: Any.Type, index: Int) -> Int
