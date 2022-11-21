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

@_silgen_name("swift_isClassType")
private func swift_isClassType(_: Any.Type) -> Bool
