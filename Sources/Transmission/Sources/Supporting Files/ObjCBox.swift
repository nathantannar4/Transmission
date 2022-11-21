//
// Copyright (c) Nathan Tannar
//

import Foundation

final class ObjCBox<Value>: NSObject {
    var value: Value
    init(value: Value) { self.value = value }
}

final class ObjCWeakBox<Value: AnyObject>: NSObject {
    weak var value: Value?
    init(value: Value?) { self.value = value }
}
