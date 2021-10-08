import Foundation
@testable import RAnalytics

// MARK: - Encryption

extension NSString {
    @objc func nsratEncrypt() -> NSString? {
        (self as String).ratEncrypt as NSString?
    }
}

// MARK: - Bundle Helper

@objc public final class BundleHelper: NSObject {
    @objc public static func endpointAddress() -> URL? {
        Bundle.main.endpointAddress
    }
}
