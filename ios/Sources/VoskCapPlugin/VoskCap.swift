import Foundation

@objc public class VoskCap: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
