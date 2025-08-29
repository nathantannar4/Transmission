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
