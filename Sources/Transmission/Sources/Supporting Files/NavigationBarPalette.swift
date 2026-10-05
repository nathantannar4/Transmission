//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@objc
public protocol _UINavigationBarPalette: NSObjectProtocol where Self: UIView { }

extension UINavigationItem {

    public var topPalette: _UINavigationBarPalette? {
        get {
            guard
                // _topPalette
                let aSelector = NSStringFromBase64EncodedString("X3RvcFBhbGV0dGU="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? _UINavigationBarPalette
            else {
                return nil
            }
            return value
        }
        set {
            guard
                // _setTopPalette:
                let aSelector = NSSelectorFromBase64EncodedString("X3NldFRvcFBhbGV0dGU6"),
                responds(to: aSelector)
            else {
                return
            }
            perform(aSelector, with: newValue)
        }
    }

    public var bottomPalette: _UINavigationBarPalette? {
        get {
            guard
                // _bottomPalette
                let aSelector = NSStringFromBase64EncodedString("X2JvdHRvbVBhbGV0dGU="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? _UINavigationBarPalette
            else {
                return nil
            }
            return value
        }
        set {
            guard
                // _setBottomPalette:
                let aSelector = NSSelectorFromBase64EncodedString("X3NldEJvdHRvbVBhbGV0dGU6"),
                responds(to: aSelector)
            else {
                return
            }
            perform(aSelector, with: newValue)
        }
    }
}

extension _UINavigationBarPalette {

    public var preferredHeight: CGFloat {
        get {
            guard
                // preferredHeight
                let aSelector = NSStringFromBase64EncodedString("cHJlZmVycmVkSGVpZ2h0"),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? CGFloat
            else {
                return 0
            }
            return value
        }
        set {
            guard
                // setPreferredHeight:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0UHJlZmVycmVkSGVpZ2h0Og=="),
                responds(to: aSelector),
                // preferredHeight
                let key = NSStringFromBase64EncodedString("cHJlZmVycmVkSGVpZ2h0")
            else {
                return
            }
            setValue(newValue, forKey: key)
        }
    }

    public var minimumHeight: CGFloat {
        get {
            guard
                // minimumHeight
                let aSelector = NSStringFromBase64EncodedString("bWluaW11bUhlaWdodA=="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? CGFloat
            else {
                return 0
            }
            return value
        }
        set {
            guard
                // setMinimumHeight:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0TWluaW11bUhlaWdodDo="),
                responds(to: aSelector),
                // minimumHeight
                let key = NSStringFromBase64EncodedString("bWluaW11bUhlaWdodA==")
            else {
                return
            }
            setValue(newValue, forKey: key)
        }
    }

    public var displaysWhenSearchActive: Bool {
        get {
            guard
                // _displaysWhenSearchActive
                let aSelector = NSStringFromBase64EncodedString("X2Rpc3BsYXlzV2hlblNlYXJjaEFjdGl2ZQ=="),
                responds(to: NSSelectorFromString(aSelector)),
                let value = value(forKey: aSelector) as? Bool
            else {
                return false
            }
            return value
        }
        set {
            guard
                // _setDisplaysWhenSearchActive:
                let aSelector = NSSelectorFromBase64EncodedString("X3NldERpc3BsYXlzV2hlblNlYXJjaEFjdGl2ZTo="),
                responds(to: aSelector),
                // _displaysWhenSearchActive
                let key = NSStringFromBase64EncodedString("X2Rpc3BsYXlzV2hlblNlYXJjaEFjdGl2ZQ==")
            else {
                return
            }
            setValue(newValue, forKey: key)
        }
    }

    public var isTransitioning: Bool {
        get {
            guard
                // transitioning
                let selectorString = NSStringFromBase64EncodedString("dHJhbnNpdGlvbmluZw=="),
                responds(to: NSSelectorFromString(selectorString)),
                let value = value(forKey: selectorString) as? Bool
                    else {
                return false
            }
            return value
        }
        set {
            guard
                // _setTransitioning:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0VHJhbnNpdGlvbmluZzo="),
                responds(to: aSelector),
                // transitioning
                let key = NSStringFromBase64EncodedString("dHJhbnNpdGlvbmluZw==")
                    else {
                return
            }
            setValue(newValue, forKey: key)
        }
    }

    public var contentView: UIView? {
        guard
            // contentView
            let aSelector = NSStringFromBase64EncodedString("Y29udGVudFZpZXc="),
            responds(to: NSSelectorFromString(aSelector)),
            let contentView = value(forKey: aSelector) as? UIView
        else {
            return nil
        }
        return contentView
    }
}

@MainActor
public func UINavigationBarPalette(contentView: UIView) -> _UINavigationBarPalette? {
    guard
        // _UINavigationBarPalette
        let paletteViewClass = NSClassFromBase64EncodedString("X1VJTmF2aWdhdGlvbkJhclBhbGV0dGU=") as? UIView.Type,
        // initWithContentView:
        let initSelector = NSSelectorFromBase64EncodedString("aW5pdFdpdGhDb250ZW50Vmlldzo=")
    else {
        return nil
    }
    if !class_conformsToProtocol(paletteViewClass, _UINavigationBarPalette.self) {
        class_addProtocol(paletteViewClass, _UINavigationBarPalette.self)
    }
    let allocSelector = NSSelectorFromString("alloc")
    let instance = paletteViewClass.perform(allocSelector).takeUnretainedValue()
    guard
        instance.responds(to: initSelector),
        let paletteView = instance.perform(initSelector, with: contentView).takeUnretainedValue() as? _UINavigationBarPalette
    else {
        return nil
    }
    paletteView.clipsToBounds = false
    return paletteView
}

extension UIView {

    private static var didFixPaletteTransition = false
    @available(iOS 26.0, *)
    static func fixPaletteTransition() {
        guard !didFixPaletteTransition else { return }
        didFixPaletteTransition = true
        guard
            // _UINavigationBarPalette
            let paletteViewClass = NSClassFromBase64EncodedString("X1VJTmF2aWdhdGlvbkJhclBhbGV0dGU=") as? UIView.Type
                else {
            return
        }
        swizzle(
            target: paletteViewClass,
            source: paletteViewClass,
            aSelector: #selector(UIView.snapshotView(afterScreenUpdates:)),
            aSwizzledSelector: #selector(UIView._swizzled_snapshotView(afterScreenUpdates:))
        )
    }

    @objc
    func _swizzled_snapshotView(afterScreenUpdates: Bool) -> UIView? {
        // Force live render so custom transition animations can animate it
        return self
    }
}

#endif
