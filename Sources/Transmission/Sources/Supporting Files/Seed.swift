//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

enum Seed {
    private nonisolated(unsafe) static let lock: os_unfair_lock_t = {
        let lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock_s())
        return lock
    }()
    private nonisolated(unsafe) static var seed: UInt = 0

    static func generate() -> UInt {
        defer {
            os_unfair_lock_lock(lock); defer { os_unfair_lock_unlock(Self.lock) }
            seed = seed &+ 1
        }
        return seed
    }
}

#endif
