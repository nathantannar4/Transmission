//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
@usableFromInline
enum Seed: Hashable, Sendable {
    case updatePhase(UpdatePhase.Value)
    case constant(ObjectIdentifier)

    private nonisolated(unsafe) static let lock: os_unfair_lock_t = {
        let lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock_s())
        return lock
    }()
    private nonisolated(unsafe) static var updatePhase = UpdatePhase.Value()

    static func generate() -> Seed {
        os_unfair_lock_lock(lock); defer { os_unfair_lock_unlock(Self.lock) }
        let phase = Seed.updatePhase(updatePhase)
        updatePhase.update()
        return phase
    }

    static func constant<Object: AnyObject>(_ object: Object) -> Seed {
        .constant(ObjectIdentifier(object))
    }
}

#endif
