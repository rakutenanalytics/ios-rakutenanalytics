import Testing
@testable import RakutenAnalytics
import Foundation
import UserNotifications
import UIKit

// MARK: - TestUNNotificationDelegate

private final class TestUNNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {}
}

private final class PushNotificationTriggerCoder: NSCoder {
    private enum FieldKey: String { case repeats }
    private let repeats: Bool
    override public var allowsKeyedCoding: Bool { true }
    
    public init(repeats: Bool) {
        self.repeats = repeats
    }
    
    override public func decodeBool(forKey key: String) -> Bool {
        FieldKey(rawValue: key) == .repeats ? repeats : false
    }
}

private final class NotificationCoder: NSCoder {
    private enum FieldKey: String {
        case request
    }
    private let request: UNNotificationRequest
    override var allowsKeyedCoding: Bool { true }
    
    init(with request: UNNotificationRequest) {
        self.request = request
    }
    
    override func decodeObject(forKey key: String) -> Any? {
        FieldKey(rawValue: key) == .request ? request : nil
    }
}

private final class NotificationResponseCoder: NSCoder {
    private enum FieldKey: String {
        case request, notification, userText, actionIdentifier
    }
    private let request: UNNotificationRequest
    private let notification: UNNotification
    override var allowsKeyedCoding: Bool { true }
    
    init(with request: UNNotificationRequest, notification: UNNotification) {
        self.request = request
        self.notification = notification
    }
    
    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .userText:
            return "Some user text"
        case .actionIdentifier:
            return UNNotificationDefaultActionIdentifier
        case .request:
            return request
        case .notification:
            return notification
        default:
            return nil
        }
    }
}

extension UNTextInputNotificationResponse {
    static func anotherResponse(rid: String) -> UNTextInputNotificationResponse? {
        let content = UNMutableNotificationContent()
        content.title = "UN notification"
        content.body = "body"
        content.userInfo = ["rid": rid,
                            "nid": "abcd1234",
                            "aps": ["alert": "a push alert"]]
        
        let trigger = UNPushNotificationTrigger(coder: PushNotificationTriggerCoder(repeats: false))
        let request = UNNotificationRequest(identifier: "id_notification", content: content, trigger: trigger)
        let notification: UNNotification! = UNNotification(coder: NotificationCoder(with: request))
        
        return UNTextInputNotificationResponse(coder: NotificationResponseCoder(with: request, notification: notification))
    }
}

// MARK: - UNUserNotificationCenterDelegateTests

@Suite("UNUserNotificationCenterDelegate")
struct UNUserNotificationCenterDelegateTests {
    static var applicationState: UIApplication.State = .active
    static var sendEvent: ((String, [String: Any]?) -> Void)?
    
#if SWIFT_PACKAGE
    
    // UNUserNotificationCenter.current().delegate's setter crashes in a Swift Package Tests Target
    
#else
    @Test("should respond to original and replaced delegate")
    func testShouldRespondToOriginalAndReplacedDelegate() {
        let testUNNotificationDelegate = TestUNNotificationDelegate()
        UNUserNotificationCenter.current().delegate = testUNNotificationDelegate
        #expect(UNUserNotificationCenter.current().responds(to: #selector(getter: UNUserNotificationCenter.delegate)) == true)
        
        let selector = #selector(UNUserNotificationCenter.rAutotrackSetUserNotificationCenterDelegate(_:))
        #expect(UNUserNotificationCenter.current().responds(to: selector) == true)
    }
    
    @Test("should respond to original and replaced userNotificationCenter(_:didReceive:withCompletionHandler:)")
    func testShouldRespondToOriginalAndReplacedUserNotificationCenter() {
        let testUNNotificationDelegate = TestUNNotificationDelegate()
        UNUserNotificationCenter.current().delegate = testUNNotificationDelegate
        
        let originalSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        #expect(UNUserNotificationCenter.current().delegate?.responds(to: originalSelector) == true)
        
        let swizzledSelector = #selector(UNUserNotificationCenter.rAutotrackUserNotificationCenter(_:didReceive:withCompletionHandler:))
        #expect(UNUserNotificationCenter.current().delegate?.responds(to: swizzledSelector) == true)
    }
#endif
}
