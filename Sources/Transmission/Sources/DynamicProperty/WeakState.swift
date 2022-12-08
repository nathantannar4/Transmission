//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
struct WeakState<Value: AnyObject>: DynamicProperty {

    @usableFromInline
    class Storage: ObservableObject {
        weak var value: Value? {
            didSet {
                if oldValue !== value {
                    objectWillChange.send()
                }
            }
        }
        @usableFromInline
        init(value: Value?) { self.value = value }
    }

    @usableFromInline
    var storage: StateObject<Storage>

    @inlinable
    init(wrappedValue thunk: @autoclosure @escaping () -> Value?) {
        storage = StateObject<Storage>(wrappedValue: { Storage(value: thunk()) }())
    }

    var wrappedValue: Value? {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    var projectedValue: Binding<Value?> {
        storage.projectedValue.value
    }
}
