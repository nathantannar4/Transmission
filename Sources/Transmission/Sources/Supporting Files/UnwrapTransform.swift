//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding {
    @inlinable
    public func unwrap<Wrapped>() -> Binding<Wrapped>? where Optional<Wrapped> == Value {
        guard let value = self.wrappedValue else { return nil }
        return Binding<Wrapped>(
            get: { return value },
            set: { value in
                self.wrappedValue = value
            }
        )
    }
}
