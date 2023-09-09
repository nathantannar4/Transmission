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
            if responds(to: NSSelectorFromString("_identifier")),
               let identifier = value(forKey: "_identifier") as? String
            {
                return identifier
            } else {
                return nil
            }
        }
    }

    var isDynamic: Bool {
        guard let id = id else {
            return false
        }
        switch id {
        case UISheetPresentationController.Detent.Identifier.large.rawValue,
            UISheetPresentationController.Detent.Identifier.medium.rawValue:
            return false
        case PresentationLinkTransition.SheetTransitionOptions.Detent.ideal.identifier.rawValue:
            return true
        default:
            if #available(iOS 16.0, *) {
                if responds(to: NSSelectorFromString("_type")),
                    let type = value(forKey: "_type") as? Int
                {
                    return type == 0
                }
            }
            return resolution != nil
        }
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
        if responds(to: NSSelectorFromString("_constant")),
            let constant = value(forKey: "_constant") as? CGFloat,
            constant > 0
        {
            return constant
        }
        return nil
    }

    func resolvedValue(containerTraitCollection: UITraitCollection, maximumDetentValue: CGFloat) -> CGFloat? {
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



#endif
