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

    func testSwizzleDidReceiveRemoteNotificationInactive() throws {

        type(of: self).applicationState = .inactive

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func testSwizzleDidReceiveRemoteNotificationActive() throws {

        type(of: self).applicationState = .active

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func testSwizzleDidReceiveRemoteNotificationBackground() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func testDidReceiveRemoteNotificationBackgroundProcessEvent() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationBackgroundProcessEventNotTwice() throws {

        type(of: self).applicationState = .background
        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationBackgroundNotProcessEventAfter800ms() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationShouldNotProccessEventWhenAppGroupContainsTrackingID() {
        pushEventHandler.cacheEvent(for: "rid:\(testRID)")

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationBackgroundNotProcessEventIfSilentPush() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID,
                                                       "aps": [ "content-available": 1 ]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func testDidReceiveRemoteNotificationBackgroundProcessEventIfBackgroundPush() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID,
                                                       "aps": [ "content-available": 1,
                                                                "alert": "meesage"]])

        XCTAssertNotNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func testDidReceiveRemoteNotificationBackgroundShouldNotProcessEventIfUNUserNotificationCenterDelegateImplemented() throws {

        type(of: self).applicationState = .background
        UNUserNotificationCenter.current().delegate = testUNNotificationDelegate

        triggerDidReceiveRemoteNotification(userInfo: ["rid": testRID,
                                                       "aps": [ "content-available": 1,
                                                                "alert": "meesage"]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    // MARK: - Test didReceiveRemoteNotificationWithCompletionHandler

    func testSwizzleDidReceiveRemoteNotificationWithCompletionHandlerInactive() throws {

        type(of: self).applicationState = .inactive

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func testSwizzleDidReceiveRemoteNotificationWithCompletionHandlerActive() throws {

        type(of: self).applicationState = .active

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func testSwizzleDidReceiveRemoteNotificationWithCompletionHandlerBackground() throws {

        type(of: self).applicationState = .background
        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

        let trackId = AnalyticsManager.shared().launchCollector.pushTrackingIdentifier ?? ""

        XCTAssert(trackId == testResult)
    }

    func testDidReceiveRemoteNotificationWithCompletionHandlerBackgroundProcessEvent() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationWithCompletionHandlerBackgroundProcessEventNotTwice() throws {

        type(of: self).applicationState = .background
        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationWithCompletionHandlerBackgroundNotProcessEventAfter800ms() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationWithCompletionHandlerShouldNotProccessEventWhenAppGroupContainsTrackingID() {
        pushEventHandler.cacheEvent(for: "rid:\(testRID)")

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID])

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

    func testDidReceiveRemoteNotificationWithCompletionHandlerBackgroundNotProcessEventIfSilentPush() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID,
                                                                            "aps": [ "content-available": 1 ]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func testDidReceiveRemoteNotificationWithCompletionHandlerBackgroundProcessEventIfBackgroundPush() throws {

        type(of: self).applicationState = .background

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID,
                                                                            "aps": [ "content-available": 1,
                                                                                     "alert": "meesage"]])

        XCTAssertNotNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    func testDidReceiveRemoteNotificationWithCompletionHandlerBackgroundShouldNotProcessEventIfUNUserNotificationCenterDelegateImplemented() throws {

        type(of: self).applicationState = .background
        UNUserNotificationCenter.current().delegate = testUNNotificationDelegate

        triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: ["rid": testRID,
                                                                            "aps": [ "content-available": 1,
                                                                                     "alert": "meesage"]])

        XCTAssertNil(AnalyticsManager.shared().launchCollector.pushTrackingIdentifier)
    }

    // MARK: - Helper

    private func triggerDidReceiveRemoteNotification(userInfo: [AnyHashable: Any]) {
        UIApplication.shared.delegate?.application?(UIApplication.shared,
                                                    didReceiveRemoteNotification: userInfo)
    }

    private func triggerDidReceiveRemoteNotificationWithCompletionHandler(userInfo: [AnyHashable: Any]) {
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
