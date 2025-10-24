import Foundation

func NSStringFromBase64EncodedString(
    _ aStringBase64Encoded: String
) -> String? {
    guard
        let data = Data(base64Encoded: aStringBase64Encoded),
        let aSelectorName = String(data: data, encoding: .utf8)
    else {
        return nil
    }
    return aSelectorName
}

func NSSelectorFromBase64EncodedString(
    _ aSelectorNameBase64Encoded: String
) -> Selector? {
    guard
        let aSelectorName = NSStringFromBase64EncodedString(aSelectorNameBase64Encoded)
    else {
        return nil
    }
    return NSSelectorFromString(aSelectorName)
}


extension NSObject {

    var methods: [Selector] {
        var type: AnyClass? = object_getClass(self)
        var results = [Selector]()
        while let aClass = type, aClass != NSObject.self {
            results.append(contentsOf: methods(for: aClass))
            type = class_getSuperclass(aClass)
        }
        return results
    }

    private func methods(for aClass: AnyClass) -> [Selector] {
        var methodCount: UInt32 = 0
        guard
            let methodList = class_copyMethodList(aClass, &methodCount),
            methodCount != 0
        else { return [] }
        return (0 ..< Int(methodCount))
            .compactMap({ method_getName(methodList[$0]) })
    }
}
