import UIKit
import XCTest
@testable import RAnalytics

class PushNotificationAppDelegateTests: XCTestCase {

    static var applicationState: UIApplication.State = .active
    static var processEvent: ((AnalyticsManager.Event) -> Void)?

    class TestUNNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) { }
    }

    // swiftlint:disable:next weak_delegate
    let testUNNotificationDelegate = TestUNNotificationDelegate()
    let testRID = "38493839"
    var testResult: String { "rid:\(testRID)" }
    let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: Bundle.main.appGroupId),
                                            appGroupId: Bundle.main.appGroupId,
                                            fileManager: FileManager.default,
                                            serializerType: JSONSerialization.self)

    override func setUp() {
        UIApplication.swizzleToggle()
        AnalyticsManager.swizzleToggle()

        UNUserNotificationCenter.current().delegate = nil

        AnalyticsManager.shared().launchCollector.resetToDefaults()
        AnalyticsManager.shared().launchCollector.resetPushTrackingIdentifier()
    }

    override func tearDown() {
        UIApplication.swizzleToggle()
        AnalyticsManager.swizzleToggle()

        UNUserNotificationCenter.current().delegate = nil

        pushEventHandler.clearCache()
    }

    // MARK: - Test didReceiveRemoteNotification

    func test_swizzle_didReceiveRemoteNotification_inactive() throws {

        type(of: self).applicationState = .inactive

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func test_swizzle_didReceiveRemoteNotification_active() throws {

        type(of: self).applicationState = .active

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func test_swizzle_didReceiveRemoteNotification_background() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func test_didReceiveRemoteNotification_background_processEvent() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should receive open count event")
        var processEvent = ""
        var eventParams = [String: Any]()

        type(of: self).processEvent = { (event) in
            processEvent = event.name
            eventParams = event.parameters
            expecation.fulfill()
        }

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        wait(for: [expecation], timeout: 3)

        let trackId = (eventParams[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""

        XCTAssert(processEvent == AnalyticsManager.Event.Name.pushNotification)
        XCTAssert(trackId == testResult)
    }

    func test_didReceiveRemoteNotification_background_processEvent_notTwice() throws {

        type(of: self).applicationState = .background
        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should receive open count event once")
        expecation.expectedFulfillmentCount = 1
        expecation.assertForOverFulfill = true
        var processEvent = ""
        var eventParams = [String: Any]()

        type(of: self).processEvent = { (event) in
            processEvent = event.name
            eventParams = event.parameters
            expecation.fulfill()
        }

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        wait(for: [expecation], timeout: 3)

        let trackId = (eventParams[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""

        XCTAssert(processEvent == AnalyticsManager.Event.Name.pushNotification)
        XCTAssert(trackId == testResult)
    }

    func test_didReceiveRemoteNotification_background_notProcessEvent_after800ms() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should not send if greater than 0.7 seconds")
        expecation.isInverted = true

        type(of: self).processEvent = { (event) in
            let processEvent = event.name
            let eventParams = event.parameters
            let trackId = (eventParams[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""
            if processEvent == AnalyticsManager.Event.Name.pushNotification &&
                trackId == self.testResult {
                expecation.fulfill()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4.0) {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        wait(for: [expecation], timeout: 8)
    }

    func test_didReceiveRemoteNotification_shouldNotProccessEvent_whenAppGroupContainsTrackingId() {
        pushEventHandler.cacheEvent(for: "rid:\(testRID)")

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should not send because utility says it's in app group")
        expecation.isInverted = true

        type(of: self).processEvent = { (event) in
            let trackId = (event.parameters[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""
            guard event.name == AnalyticsManager.Event.Name.pushNotification &&
                    trackId == self.testResult else { return }
            expecation.fulfill()
        }

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        wait(for: [expecation], timeout: 8)
    }

    func test_didReceiveRemoteNotification_background_notProcessEvent_ifSilentPush() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID,
                                                        "aps": [ "content-available": 1 ]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func test_didReceiveRemoteNotification_background_processEvent_ifBackgroundPush() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID,
                                                        "aps": [ "content-available": 1,
                                                                 "alert": "meesage"]])

        XCTAssertNotNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func test_didReceiveRemoteNotification_background_shouldNotProcessEvent_ifUNUserNotificationCenterDelegateImplemented() throws {

        type(of: self).applicationState = .background
        UNUserNotificationCenter.current().delegate = testUNNotificationDelegate

        _triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID,
                                                        "aps": [ "content-available": 1,
                                                                 "alert": "meesage"]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    // MARK: - Test didReceiveRemoteNotificationWithCompletionHandler

    func test_swizzle_didReceiveRemoteNotificationWithCompletionHandler_inactive() throws {

        type(of: self).applicationState = .inactive

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func test_swizzle_didReceiveRemoteNotificationWithCompletionHandler_active() throws {

        type(of: self).applicationState = .active

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func test_swizzle_didReceiveRemoteNotificationWithCompletionHandler_background() throws {

        type(of: self).applicationState = .background
        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_background_processEvent() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should receive open count event")
        var processEvent = ""
        var eventParams = [String: Any]()

        type(of: self).processEvent = { (event) in
            processEvent = event.name
            eventParams = event.parameters
            expecation.fulfill()
        }

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        wait(for: [expecation], timeout: 3)

        let trackId = (eventParams[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""

        XCTAssert(processEvent == AnalyticsManager.Event.Name.pushNotification)
        XCTAssert(trackId == testResult)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_background_processEvent_notTwice() throws {

        type(of: self).applicationState = .background
        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should receive open count event once")
        expecation.expectedFulfillmentCount = 1
        expecation.assertForOverFulfill = true
        var processEvent = ""
        var eventParams = [String: Any]()

        type(of: self).processEvent = { (event) in
            processEvent = event.name
            eventParams = event.parameters
            expecation.fulfill()
        }

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        wait(for: [expecation], timeout: 3)

        let trackId = (eventParams[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""

        XCTAssert(processEvent == AnalyticsManager.Event.Name.pushNotification)
        XCTAssert(trackId == testResult)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_background_notProcessEvent_after800ms() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should not send if greater than 0.7 seconds")
        expecation.isInverted = true

        type(of: self).processEvent = { (event) in
            let processEvent = event.name
            let eventParams = event.parameters
            let trackId = (eventParams[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""
            if processEvent == AnalyticsManager.Event.Name.pushNotification &&
                trackId == self.testResult {
                expecation.fulfill()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4.0) {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        wait(for: [expecation], timeout: 8)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_shouldNotProccessEvent_whenAppGroupContainsTrackingId() {
        pushEventHandler.cacheEvent(for: "rid:\(testRID)")

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let expecation = XCTestExpectation(description: "should not send because utility says it's in app group")
        expecation.isInverted = true

        type(of: self).processEvent = { (event) in
            let trackId = (event.parameters[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String) ?? ""
            guard event.name == AnalyticsManager.Event.Name.pushNotification &&
                    trackId == self.testResult else { return }
            expecation.fulfill()
        }

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        wait(for: [expecation], timeout: 8)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_background_notProcessEvent_ifSilentPush() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID,
                                                                             "aps": [ "content-available": 1 ]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_background_processEvent_ifBackgroundPush() throws {

        type(of: self).applicationState = .background

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID,
                                                                             "aps": [ "content-available": 1,
                                                                                      "alert": "meesage"]])

        XCTAssertNotNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func test_didReceiveRemoteNotificationWithCompletionHandler_background_shouldNotProcessEvent_ifUNUserNotificationCenterDelegateImplemented() throws {

        type(of: self).applicationState = .background
        UNUserNotificationCenter.current().delegate = testUNNotificationDelegate

        _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID,
                                                                             "aps": [ "content-available": 1,
                                                                                      "alert": "meesage"]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    // MARK: - Helper

    private func _triggerDidReceiveRemoteNotification(userInfo: [AnyHashable: Any]) {
        UIApplication.shared.delegate?.application?(UIApplication.shared,
                                                    didReceiveRemoteNotification: userInfo)
    }

    private func _triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: [AnyHashable: Any]) {
        UIApplication.shared.delegate?.application?(UIApplication.shared,
                                                    didReceiveRemoteNotification: userInfo,
                                                    fetchCompletionHandler: { (_) in })
    }
}

internal extension AnalyticsManager {
    @objc func swizzleProcessEvent(event: AnalyticsManager.Event) {
        PushNotificationAppDelegateTests.processEvent?(event)
    }

    static func swizzleToggle() {
        guard let originalMethod = class_getInstanceMethod(AnalyticsManager.self,
                                                           #selector(process(_:))),
              let swizzledMethod = class_getInstanceMethod(AnalyticsManager.self,
                                                           #selector(swizzleProcessEvent(event:))) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

internal extension UIApplication {
    @objc func swizzleAppState() -> UIApplication.State {
        return PushNotificationAppDelegateTests.applicationState
    }

    static func swizzleToggle() {
        guard let originalMethod = class_getInstanceMethod(UIApplication.self,
                                                           #selector(getter: applicationState)),
              let swizzledMethod = class_getInstanceMethod(UIApplication.self,
                                                           #selector(swizzleAppState)) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
