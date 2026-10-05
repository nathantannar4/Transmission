//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@MainActor @preconcurrency
@propertyWrapper
@frozen
@available(iOS 14.0, *)
public struct FirstResponderState<Value: Hashable>: DynamicProperty {

    @usableFromInline
    var storage: State<Value>

    public init() where Value == Bool {
        self.storage = State(wrappedValue: false)
    }

    public init(wrappedValue: Value) where Value == Bool {
        self.storage = State(wrappedValue: wrappedValue)
    }

    public init<V: Hashable>() where Value == V? {
        self.storage = State(wrappedValue: nil)
    }

    public init<V: Hashable>(wrappedValue: Value) where Value == V? {
        self.storage = State(wrappedValue: wrappedValue)
    }

    public var wrappedValue: Value {
        get { storage.wrappedValue }
        nonmutating set { storage.projectedValue.transaction(.keyboard).wrappedValue = newValue }
    }

    public var projectedValue: Binding {
        Binding(storage: .projectedValue(storage.projectedValue.transaction(.keyboard)))
    }

    @MainActor @preconcurrency
    @propertyWrapper
    @frozen
    public struct Binding {
        @usableFromInline
        enum Storage {
            case projectedValue(SwiftUI.Binding<Value>)
            case automatic(Value)
        }
        @usableFromInline
        var storage: Storage

        public var wrappedValue: Value {
            get {
                switch storage {
                case .projectedValue(let binding):
                    return binding.wrappedValue
                case .automatic(let value):
                    return value
                }
            }
            nonmutating set {
                switch storage {
                case .projectedValue(let binding):
                    binding.wrappedValue = newValue
                case .automatic:
                    break
                }
            }
        }

        public var projectedValue: SwiftUI.Binding<Value> {
            switch storage {
            case .projectedValue(let binding):
                return binding
            case .automatic(let value):
                return .constant(value)
            }
        }

        public func updateUIResponder(
            _ responder: UIResponder,
            transitionCoordinator: @autoclosure () -> UIViewControllerTransitionCoordinator?,
            isAttaching: Bool
        ) where Value == Bool {
            let value: Bool = {
                if wrappedValue {
                    return true
                }
                if isAttaching, case .automatic = storage {
                    return true
                }
                return false
            }()
            if responder.isFirstResponder {
                if case .projectedValue(let binding) = storage {
                    if isAttaching {
                        withCATransaction {
                            binding.wrappedValue = true
                        }
                    } else if !value {
                        withCATransaction {
                            if responder.resignFirstResponder() {
                                didResignFirstResponder(responder)
                            }
                       }
                    }
                }
            } else if value {
                responder.becomeFirstResponder(
                    alongsideTransition: isAttaching ? transitionCoordinator() : nil
                )
            }
        }

        public func didResignFirstResponder(
            _ responder: UIResponder
        ) where Value == Bool {
            guard wrappedValue, !responder.isFirstResponder else { return }
            if case .projectedValue(let binding) = storage {
                binding.wrappedValue = false
            }
        }

        public func didBecomeFirstResponder(
            _ responder: UIResponder
        ) where Value == Bool {
            guard !wrappedValue, responder.isFirstResponder else { return }
            if case .projectedValue(let binding) = storage {
                binding.wrappedValue = true
            }
        }

        /// Should become first responder automatically, such as when the view appears
        public static var automatic: FirstResponderState<Bool>.Binding {
            FirstResponderState<Bool>.Binding(storage: .automatic(false))
        }

        /// Transforms the binding to a `Bool`
        public func isEqual<V>(to other: V) -> FirstResponderState<Bool>.Binding where Value == V? {
            switch storage {
            case .projectedValue(let binding):
                return FirstResponderState<Bool>.Binding(storage: .projectedValue(binding.isEqual(to: other, defaultValue: nil)))
            case .automatic(let value):
                if value == other {
                    return .automatic
                }
                return FirstResponderState<Bool>.Binding(storage: .projectedValue(.constant(false)))
            }
        }
    }
}

@available(iOS 14.0, *)
extension FirstResponderState: Sendable where Value: Sendable { }

@available(iOS 14.0, *)
extension FirstResponderState.Binding: Sendable where Value: Sendable { }

extension Animation {

    public static var keyboard: Animation {
        .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.25)
    }
}

extension Transaction {

    public static var keyboard: Transaction {
        Transaction(animation: .keyboard).disablesAnimations(true)
    }
}

#endif
