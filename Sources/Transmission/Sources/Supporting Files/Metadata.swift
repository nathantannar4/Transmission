//
// Copyright (c) Nathan Tannar
//

import Foundation

func isClassType(_ type: Any.Type) -> Bool {
    swift_isClassType(type)
}

func isClassType(_ value: Any) -> Bool {
    isClassType(type(of: value))
}

func size(of value: Any) -> Int {
    func project<T>(_ : T) -> Int {
        MemoryLayout<T>.size
    }
    return _openExistential(value, do: project)
}

@_silgen_name("swift_isClassType")
private func swift_isClassType(_: Any.Type) -> Bool
