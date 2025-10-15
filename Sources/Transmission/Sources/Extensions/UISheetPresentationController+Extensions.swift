//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@available(iOS 16.0, *)
private class _UISheetPresentationControllerDetentResolutionContext: NSObject, UISheetPresentationControllerDetentResolutionContext {
    var containerTraitCollection: UITraitCollection
    var maximumDetentValue: CGFloat

    init(containerTraitCollection: UITraitCollection, maximumDetentValue: CGFloat) {
        self.containerTraitCollection = containerTraitCollection
        self.maximumDetentValue = maximumDetentValue
    }
}

private class _UISheetPresentationControllerDetentResolver: NSObject {
    var resolution: (UITraitCollection, CGFloat) -> CGFloat?

    init(resolution: @escaping (UITraitCollection, CGFloat) -> CGFloat?) {
        self.resolution = resolution
    }
}

@available(iOS 15.0, *)
extension UISheetPresentationController.Detent {

    var id: String? {
        if #available(iOS 16.0, *) {
            return identifier.rawValue
        } else {
            // _identifier
            guard
                let aSelector = NSStringFromBase64EncodedString("X2lkZW50aWZpZXI="),
                responds(to: NSSelectorFromString(aSelector))
            else {
                return nil
            }
            return value(forKey: aSelector) as? String
        }
    }

    var isDynamic: Bool {
        guard let id else { return false }
        switch id {
        case UISheetPresentationController.Detent.Identifier.large.rawValue,
            UISheetPresentationController.Detent.Identifier.medium.rawValue:
            return false
        case PresentationLinkTransition.SheetTransitionOptions.Detent.ideal.identifier.rawValue:
            return true
        default:
            if #available(iOS 16.0, *) {
                // _type
                if let aSelector = NSStringFromBase64EncodedString("X3R5cGU="),
                   responds(to: NSSelectorFromString(aSelector)),
                   let type = value(forKey: aSelector) as? Int
                {
                    return type == 0
                }
            }
            return resolution != nil
        }
    }

    @available(iOS 18.0, *)
    static func fullScreen() -> UISheetPresentationController.Detent? {
        // _fullDetent
        let aSelector = NSSelectorFromBase64EncodedString("X2Z1bGxEZXRlbnQ=")
        guard responds(to: aSelector) else { return nil }
        return perform(aSelector).takeUnretainedValue() as? UISheetPresentationController.Detent
    }

    static var legacyResolutionKey: UInt = 0
    var resolution: ((UITraitCollection, CGFloat) -> CGFloat?)? {
        get {
            if #available(iOS 16.0, *) {
                return nil
            } else {
                let object = objc_getAssociatedObject(self, &Self.legacyResolutionKey) as? _UISheetPresentationControllerDetentResolver
                return object?.resolution
            }
        }
        set {
            if #available(iOS 16.0, *) { } else {
                let object = newValue.map { _UISheetPresentationControllerDetentResolver(resolution: $0) }
                objc_setAssociatedObject(self, &Self.legacyResolutionKey, object, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    var constant: CGFloat? {
        if let aSelector = NSStringFromBase64EncodedString("X2NvbnN0YW50"),
           responds(to: NSSelectorFromString(aSelector)),
           let constant = value(forKey: aSelector) as? CGFloat,
           constant > 0
        {
            return constant
        }
        return nil
    }

    func resolvedValue(
        containerTraitCollection: UITraitCollection,
        maximumDetentValue: CGFloat
    ) -> CGFloat? {
        if #available(iOS 16.0, *) {
            let context = _UISheetPresentationControllerDetentResolutionContext(
                containerTraitCollection: containerTraitCollection,
                maximumDetentValue: maximumDetentValue
            )
            return resolvedValue(in: context)
        } else if let resolution {
            return resolution(containerTraitCollection, maximumDetentValue)
        }
        return nil
    }
}

@available(iOS 15.0, *)
extension UISheetPresentationController {

    var maximumDetentValue: CGFloat? {
        guard let containerView else { return nil }
        let maximumDetentValue = containerView.frame.height - containerView.safeAreaInsets.top - containerView.safeAreaInsets.bottom
        if #available(iOS 26.0, *) {
            return maximumDetentValue
        } else {
            // This seems to match the `maximumDetentValue` computed by UIKit
            return maximumDetentValue - 10
        }
    }
}



#endif
