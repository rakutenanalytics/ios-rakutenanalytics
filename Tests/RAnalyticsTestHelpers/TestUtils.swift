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

    public static var ratJsonUrl: URL? {
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: "rat", withExtension: "json")
        #else
        return Bundle(for: Self.self).url(forResource: "rat", withExtension: "json")
        #endif
    }
}
