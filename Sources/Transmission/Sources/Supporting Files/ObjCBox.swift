//
// Copyright (c) Nathan Tannar
//

import Foundation

final class ObjCBox<Value>: NSObject {
    var value: Value
    init(value: Value) { self.value = value }
}

class ObjCRefBox<Value: AnyObject>: NSObject {
    var value: Value?
    init(value: Value?) { self.value = value }
}

final class ObjCWeakBox<Value: AnyObject>: ObjCRefBox<Value> {

    override var value: Value? {
        get { weakValue }
        set { weakValue = newValue }
    }

    private weak var weakValue: Value?

    override init(value: Value?) {
        super.init(value: nil)
        self.weakValue = value
    }
}
