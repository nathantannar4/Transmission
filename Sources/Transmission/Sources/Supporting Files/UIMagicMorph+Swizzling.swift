//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 26.0, *)
extension UIView {

    public static func disableMagicMorphViewBounce() {
        let aClass: NSObject.Type? = {
            if #available(iOS 27.0, *) {
                // UIKit.MagicMorphView
                return NSClassFromBase64EncodedString("VUlLaXQuTWFnaWNNb3JwaFZpZXc=")
            }
            // _UIMagicMorphView
            return NSClassFromBase64EncodedString("X1VJTWFnaWNNb3JwaFZpZXc=")
        }()
        guard let aClass else { return }
        swizzle(
            target: aClass,
            source: UIView.self,
            aSelector: #selector(setter: UIView.center),
            aSwizzledSelector: #selector(UIView.swizzled_magicMorph_setCenter(_:))
        )
    }

    private class CachedScrollView: NSObject {
        weak var scrollView: UIScrollView?
        var initialContentOffset: CGPoint?

        init(scrollView: UIScrollView?, initialContentOffset: CGPoint? = nil) {
            self.scrollView = scrollView
            self.initialContentOffset = initialContentOffset
        }
    }
    private static var cachedContainingScrollViewsKey: UInt = 0
    private var cachedContainingScrollViews: [CachedScrollView]? {
        get {
            let value = objc_getAssociatedObject(self, &Self.cachedContainingScrollViewsKey) as? [CachedScrollView]
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.cachedContainingScrollViewsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private static var hasRemovedRetargetableAnimationsKey: UInt = 0
    private var hasRemovedRetargetableAnimations: Bool {
        get {
            let value = objc_getAssociatedObject(self, &Self.hasRemovedRetargetableAnimationsKey) as? Bool
            return value ?? false
        }
        set {
            objc_setAssociatedObject(self, &Self.hasRemovedRetargetableAnimationsKey, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }

    @objc
    func swizzled_magicMorph_setCenter(_ center: CGPoint) {
        if UIView.isInRetargetableAnimationBlock {
            var shouldPerformWithoutRetargetingAnimations = false
            var sourceViews: [UIView] = []
            if !hasRemovedRetargetableAnimations,
                // sourceLayer
                let aSelector = NSStringFromBase64EncodedString("c291cmNlTGF5ZXI=")
            {
                let portalLayers = layer
                    .descendentSublayers { $0.responds(to: NSSelectorFromString(aSelector)) }
                let sourceLayers = portalLayers
                    .compactMap { $0.value(forKey: aSelector) as? CALayer }
                sourceViews = sourceLayers
                    .compactMap { $0.delegate as? UIView }
            }
            let sourceView = sourceViews
                .first(where: { !$0.isRootViewControllerView })
            let sourceViewContainingScrollViews = cachedContainingScrollViews ?? {
                var scrollViews = [UIScrollView]()
                var fromView = sourceView
                while let view = fromView {
                    if // _containingScrollView
                       let aSelector = NSStringFromBase64EncodedString("X2NvbnRhaW5pbmdTY3JvbGxWaWV3"),
                       view.responds(to: NSSelectorFromString(aSelector)),
                       let scrollView = view.value(forKey: aSelector) as? UIScrollView
                    {
                        scrollViews.append(scrollView)
                        fromView = scrollView
                    } else {
                        break
                    }
                }
                let containingScrollViews = scrollViews.map { CachedScrollView(scrollView: $0) }
                cachedContainingScrollViews = containingScrollViews
                return containingScrollViews
            }()
            let isScrolling = sourceViewContainingScrollViews.contains(where: {
                guard let scrollView = $0.scrollView else { return false }
                return scrollView.isTracking || scrollView.isDecelerating
            })
            if isScrolling {
                shouldPerformWithoutRetargetingAnimations = true
                if !hasRemovedRetargetableAnimations {
                    var transfrom = CGAffineTransform.identity
                    for cached in sourceViewContainingScrollViews {
                        guard let scrollView = cached.scrollView else { continue }
                        if let initialContentOffset = cached.initialContentOffset {
                            if scrollView.isTracking || scrollView.isDecelerating {
                                let dx = initialContentOffset.x - scrollView.contentOffset.x
                                let dy = initialContentOffset.y - scrollView.contentOffset.y
                                transfrom = transfrom.translatedBy(x: dx, y: dy)
                            }
                        } else {
                            cached.initialContentOffset = scrollView.contentOffset
                        }
                    }
                    layer.sublayerTransform = CATransform3DMakeAffineTransform(transfrom)
                }
            }

            let hasMinimized = sourceView.map {
                abs($0.frame.size.width - frame.size.width) < 1 && abs($0.frame.size.height - frame.size.height) < 1
            } ?? false
            if hasMinimized,
                shouldPerformWithoutRetargetingAnimations,
                !hasRemovedRetargetableAnimations,
                // _removeAllRetargetableAnimations:
                let aSelector = NSSelectorFromBase64EncodedString("X3JlbW92ZUFsbFJldGFyZ2V0YWJsZUFuaW1hdGlvbnM6"),
                responds(to: aSelector)
            {
                perform(aSelector, with: true)
                layer.sublayerTransform = CATransform3DIdentity
                hasRemovedRetargetableAnimations = true
            }
            if shouldPerformWithoutRetargetingAnimations {
                UIView.performWithoutRetargetingAnimations {
                    UIView.performWithoutAnimation {
                        self.swizzled_magicMorph_setCenter(center)
                    }
                }
            } else {
                swizzled_magicMorph_setCenter(center)
            }
        } else {
            hasRemovedRetargetableAnimations = false
            swizzled_magicMorph_setCenter(center)
        }
    }

    var isRootViewControllerView: Bool {
        var responder: UIResponder? = next
        while responder != nil, !(responder is UIViewController) {
            responder = responder?.next
        }
        return (responder as? UIViewController)?.view == self
    }
}

extension CALayer {

    func descendentSublayers(matching predicate: (CALayer) -> Bool) -> [CALayer] {
        var result: [CALayer] = []
        if predicate(self) {
            result.append(self)
        }
        for sublayer in sublayers ?? [] {
            result.append(contentsOf: sublayer.descendentSublayers(matching: predicate))
        }
        return result
    }
}

@available(iOS 26.0, *)
extension UIView {

    // _performWithoutRetargetingAnimations
    private static let retargetingAnimationsSelector = NSSelectorFromBase64EncodedString("X3BlcmZvcm1XaXRob3V0UmV0YXJnZXRpbmdBbmltYXRpb25zOg==")

    private typealias RetargetingAnimationsIMP = @convention(c) (AnyClass, Selector, @convention(block) () -> Void) -> Void

    private static let performWithoutRetargetingAnimations: RetargetingAnimationsIMP? = {
        guard
            let aSelector = retargetingAnimationsSelector,
            let method = class_getClassMethod(UIView.self, aSelector)
        else {
            return nil
        }
        return unsafeBitCast(method_getImplementation(method), to: RetargetingAnimationsIMP.self)
    }()

    static func performWithoutRetargetingAnimations(_ block: () -> Void) {
        if let imp = performWithoutRetargetingAnimations, let aSelector = Self.retargetingAnimationsSelector {
            imp(Self.self, aSelector, block)
        } else {
            block()
        }
    }

    static var isInRetargetableAnimationBlock: Bool {
        guard
            // _isInRetargetableAnimationBlock
            let aSelector = NSStringFromBase64EncodedString("X2lzSW5SZXRhcmdldGFibGVBbmltYXRpb25CbG9jaw=="),
            let value = value(forKey: aSelector) as? Bool
        else {
            return false
        }
        return value
    }
}

#endif
