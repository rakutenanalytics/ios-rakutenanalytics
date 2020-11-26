import Foundation
import UIKit

@objc public extension UIApplication {
    static var RAnalyticsSharedApplication: UIApplication? {
        UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }
}

@objc public extension NSObject {
    static func isAppleClass(_ cls: AnyClass?) -> Bool {
        guard let appleClass = cls,
              let bundleIdentifier = Bundle(for: appleClass.self).bundleIdentifier else {
            return false
        }
        return bundleIdentifier.hasPrefix("com.apple.")
    }

    static func isApplePrivateClass(_ cls: AnyClass?) -> Bool {
        guard let cls = cls else {
            return false
        }
        return NSStringFromClass(cls).hasPrefix("_") && NSObject.isAppleClass(cls)
    }

    static func isNullableObjectEqual(_ objA: NSObject?, to objB: NSObject?) -> Bool {
        guard let objectA = objA, let objectB = objB else {
            return objA == nil && objB == nil
        }
        return objectA.isEqual(objectB)
    }
}

@objc public extension Bundle {
    static var useDefaultSharedCookieStorage: Bool {
        guard let result = Bundle.main.object(forInfoDictionaryKey: "RATDisableSharedCookieStorage") as? NSNumber else {
            return true
        }
        return !result.boolValue
    }

    static var endpointAddress: URL? {
        guard let plistObj = Bundle.main.object(forInfoDictionaryKey: "RATEndpoint") as? String,
              !plistObj.isEmpty,
              let userDefinedURL = URL(string: plistObj) else {
            #if PUBLIC_ANALYTICS_IOS_SDK
                #if DEBUG
                assertionFailure("Your application's Info.plist must contain a key 'RATEndpoint' set to your endpoint URL")
                #endif
                return nil
            #else
                let prodURL = URL(string: "https://rat.rakuten.co.jp/")
                return prodURL
            #endif
        }
        return userDefinedURL
    }

    static let assetsBundle: Bundle? = {
        guard let RAnalyticsManagerClass = NSClassFromString("RAnalyticsManager") else {
            return nil
        }
        /// Can't use [NSBundle mainBundle] here, because it returns the path to XCTest.framework
        /// when running unit tests. Also, if the SDK is being bundled as a dynamic framework,
        /// then it comes in its own bundle.
        let classBundle = Bundle(for: RAnalyticsManagerClass.self)
        guard var assetsPath = classBundle.resourcePath else {
            return nil
        }
        /// If RAnalyticsAssets.bundle cannot be found, we revert to using the class bundle
        assetsPath = assetsPath.appendingPathComponent("RAnalyticsAssets.bundle")
        guard let bundle = Bundle(path: assetsPath) else {
            return classBundle
        }
        return bundle
    }()

    static let sdkComponentMap: NSDictionary? = {
        guard let bundle = assetsBundle,
              let filePath = bundle.path(forResource: "REMModulesMap", ofType: "plist") else {
            return nil
        }
        return NSDictionary(contentsOfFile: filePath)
    }()
}

private extension String {
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
}
