//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 14.0, *)
final class UIGestureRecognizerDelegateProxy: NSObject, UIGestureRecognizerDelegate {

    nonisolated(unsafe) weak var override: UIGestureRecognizerDelegate?
    nonisolated(unsafe) weak var original: UIGestureRecognizerDelegate?

    init(override: UIGestureRecognizerDelegate, original: UIGestureRecognizerDelegate) {
        self.override = override
        self.original = original
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if original != nil, super.responds(to: aSelector) {
            return true
        }
        if let override, override.responds(to: aSelector) {
            return true
        }
        if let original, original.responds(to: aSelector) {
            return true
        }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if original != nil, super.responds(to: aSelector) {
            return nil
        }
        if let override, override.responds(to: aSelector) {
            return override
        }
        if let original, original.responds(to: aSelector) {
            return original
        }
        return nil
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let shouldBegin = override?.gestureRecognizerShouldBegin?(gestureRecognizer) {
            return shouldBegin
        }
        if let shouldBegin = original?.gestureRecognizerShouldBegin?(gestureRecognizer) {
            return shouldBegin
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) {
            return result
        }
        if let result = original?.gestureRecognizer?( gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) {
            return result
        }
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) {
            return result
        }
        if let result = original?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) {
            return result
        }
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) {
            return result
        }
        if let result = original?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) {
            return result
        }
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) {
            return result
        }
        if let result = original?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) {
            return result
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive press: UIPress
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldReceive: press) {
            return result
        }
        if let result = original?.gestureRecognizer?(gestureRecognizer, shouldReceive: press) {
            return result
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive event: UIEvent
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldReceive: event) {
            return result
        }
        if let result = original?.gestureRecognizer?(gestureRecognizer, shouldReceive: event) {
            return result
        }
        return true
    }

    // MARK: - UIGestureRecognizerDelegatePrivate

    @objc(_gestureRecognizerShouldBegin:)
    func private_gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBegin = override?.gestureRecognizerShouldBegin?(gestureRecognizer) {
            return shouldBegin
        }
        return true
    }

    @objc(_gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)
    func private_gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) {
            return result
        }
        return false
    }

    @objc(_gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)
    func private_gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) {
            return result
        }
        return false
    }

    @objc(_gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)
    func private_gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) {
            return result
        }
        return false
    }

    @objc(_gestureRecognizer:shouldReceiveTouch:)
    func private_gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) {
            return result
        }
        return true
    }

    @objc(_gestureRecognizer:shouldReceivePress:)
    func private_gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive press: UIPress
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldReceive: press) {
            return result
        }
        return true
    }

    @objc(_gestureRecognizer:shouldReceiveEvent:)
    func private_gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive event: UIEvent
    ) -> Bool {
        if let result = override?.gestureRecognizer?(gestureRecognizer, shouldReceive: event) {
            return result
        }
        return true
    }
}

#endif
