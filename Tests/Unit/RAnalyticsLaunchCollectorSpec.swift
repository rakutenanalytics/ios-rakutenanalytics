import Quick
import Nimble
import UIKit

// MARK: - Keychain Handler

private final class KeychainHandlerMock: NSObject, KeychainHandleable {
    var status: OSStatus = errSecItemNotFound
    private var creationDate: Date?
    func item(for label: String) -> KeychainResult { KeychainResult(result: nil, status: status) }
    func set(creationDate: Date?, for label: String) { self.creationDate = creationDate }
    func creationDate(for reference: CFTypeRef?) -> Date? { creationDate }
}

// MARK: - User Defaults

private final class UserDefaultsMock: NSObject, UserStorageHandleable {
    var dictionary: [String: Any]?
    func object(forKey defaultName: String) -> Any? { dictionary?[defaultName] }
    func string(forKey defaultName: String) -> String? { dictionary?[defaultName] as? String }
    func set(value: Any?, forKey key: String) { dictionary?[key] = value }
}

// MARK: - Tracker

private struct TrackerResult {
    let tracked: Bool
    let parameters: [String: Any]?
}

private final class AnalyticsTrackerMock: NSObject, Trackable {
    var dictionary: [String: TrackerResult]?
    func trackEvent(name: String, parameters: [String: Any]?) {
        dictionary?[name] = TrackerResult(tracked: true, parameters: parameters)
    }
}

// MARK: - Notification

extension UNTextInputNotificationResponse {
    static func response(trigger: UNNotificationTrigger?) -> UNTextInputNotificationResponse? {
        let notificationRequest = UNNotificationResponse.notificationRequest(trigger: trigger)
        let notification = UNNotification(coder: NotificationCoder(with: notificationRequest))!
        let textInputNotificationResponse = UNTextInputNotificationResponse(
            coder: NotificationResponseCoder(with: notificationRequest, notification: notification))!
        return textInputNotificationResponse
    }
}

extension UNNotificationResponse {
    static func notificationRequest(trigger: UNNotificationTrigger?) -> UNNotificationRequest {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "UN notification"
        notificationContent.body = "body"
        notificationContent.userInfo = ["rid": "1234abcd", "nid": "abcd1234", "aps": ["alert": "a push alert"]]
        return UNNotificationRequest(identifier: "id_notification", content: notificationContent, trigger: trigger)
    }
}

private class PushNotificationTriggerCoder: NSCoder {
    private enum FieldKey: String { case repeats }
    private let repeats: Bool
    override var allowsKeyedCoding: Bool { true }
    init(repeats: Bool) {
        self.repeats = repeats
    }
    override func decodeBool(forKey key: String) -> Bool {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .repeats:
            return repeats
        default:
            return false
        }
    }
}

private class LocationNotificationTriggerCoder: NSCoder {
    private enum FieldKey: String { case repeats, region }
    private let repeats: Bool
    private let region: CLRegion
    override var allowsKeyedCoding: Bool { true }
    init(repeats: Bool, region: CLRegion) {
        self.repeats = repeats
        self.region = region
    }
    override func decodeBool(forKey key: String) -> Bool {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .repeats:
            return repeats
        default:
            return false
        }
    }
    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .repeats:
            return region
        default:
            return nil
        }
    }
}

private class NotificationResponseCoder: NSCoder {
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

private class NotificationCoder: NSCoder {
    private enum FieldKey: String {
        case request
    }
    private let request: UNNotificationRequest
    override var allowsKeyedCoding: Bool { true }

    init(with request: UNNotificationRequest) {
        self.request = request
    }

    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .request:
            return request
        default:
            return nil
        }
    }
}

// MARK: - RAnalyticsLaunchCollectorSpec

final class RAnalyticsLaunchCollectorSpec: QuickSpec {
    private enum Constants {
        static let initialLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate"
        static let installLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"
        static let lastUpdateDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"
        static let lastLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"
        static let lastVersionKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"
        static let lastVersionLaunchesKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"
    }

    override func spec() {
        describe("RAnalyticsLaunchCollector") {
            let dependenciesFactory: AnyDependenciesContainer = {
                let dependenciesFactory = AnyDependenciesContainer()
                dependenciesFactory.registerObject(NotificationCenter.default)
                dependenciesFactory.registerObject(UserDefaultsMock())
                dependenciesFactory.registerObject(KeychainHandlerMock())
                dependenciesFactory.registerObject(AnalyticsTrackerMock())
                return dependenciesFactory
            }()
            afterEach {
                // Reset with default values
                let keychainHandler = dependenciesFactory.resolveObject(KeychainHandlerMock.self) as? KeychainHandlerMock
                keychainHandler?.status = errSecItemNotFound
                keychainHandler?.set(creationDate: nil, for: Constants.initialLaunchDateKey)
            }
            it("should track the initial launch event when the app is launched For the first time") {
                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(launchCollector?.isInitialLaunch).to(beTrue())
                NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
                expect(launchCollector?.isInitialLaunch).toEventually(beFalse())
            }
            it("should track the install event when the app is launched after install") {
                let keychainHandler = dependenciesFactory.resolveObject(KeychainHandlerMock.self) as? KeychainHandlerMock
                keychainHandler?.status = errSecSuccess
                keychainHandler?.set(creationDate: Date(), for: Constants.initialLaunchDateKey)

                (dependenciesFactory.resolveObject(UserDefaultsMock.self) as? UserDefaultsMock)?.dictionary = nil

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(launchCollector?.isInstallLaunch).to(beTrue())
                NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
                expect(launchCollector?.isInstallLaunch).toEventually(beFalse())
            }
            it("should track the update event when the app is launched after update") {
                let keychainHandler = dependenciesFactory.resolveObject(KeychainHandlerMock.self) as? KeychainHandlerMock
                keychainHandler?.status = errSecSuccess
                keychainHandler?.set(creationDate: Date(), for: Constants.initialLaunchDateKey)

                let userDefaultsMock = dependenciesFactory.resolveObject(UserDefaultsMock.self) as? UserDefaultsMock
                userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: Date()]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(launchCollector?.isUpdateLaunch).to(beTrue())
                NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
                expect(launchCollector?.isUpdateLaunch).toEventually(beFalse())
            }
            it("should track the session start event when the app is resumed") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked).to(beFalse())
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked).toEventually(beTrue())
            }
            it("should track the session end event when the app is suspended") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.sessionEnd: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.sessionEnd]?.tracked).to(beFalse())
                NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.sessionEnd]?.tracked).toEventually(beTrue())
            }
            it("should track the visit event when a presented view controller is UIViewController") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pageVisit: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).to(beFalse())
                launchCollector?.didPresentViewController(UIViewController())
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).toEventually(beTrue())
                expect(launchCollector?.origin).toEventually(equal(.internal))
            }
            it("should not track the visit event when a presented view controller is UINavigationController") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pageVisit: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let origin = launchCollector?.origin
                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).to(beFalse())
                launchCollector?.didPresentViewController(UINavigationController())
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).toEventually(beFalse())
                expect(launchCollector?.origin).toEventually(equal(origin))
            }
            it("should track the push notify event when a push notification is processed with report id") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let payload: [String: Any] = ["rid": "1234abcd", "nid": "abcd1234", "aps": ["alert": "a push alert"]]

                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                launchCollector?.processPushNotificationPayload(userInfo: payload, userAction: nil, userText: nil)

                let event = analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]
                expect(event?.tracked).toEventually(beTrue())
                expect((event?.parameters?[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String)?
                        .hasPrefix("rid:1234abcd")).toEventually(beTrue())
                expect(launchCollector?.pushTrackingIdentifier?.hasPrefix("rid:1234abcd")).toEventually(beTrue())
            }
            it("should track the push notify event when a push notification is processed with notification id") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let payload: [String: Any] = ["notification_id": "abcd1234", "aps": ["alert": "a push alert"]]

                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                launchCollector?.processPushNotificationPayload(userInfo: payload, userAction: nil, userText: nil)

                let event = analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]
                expect(event?.tracked).toEventually(beTrue())
                expect((event?.parameters?[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String)?
                        .hasPrefix("nid:abcd1234")).toEventually(beTrue())
                expect(launchCollector?.pushTrackingIdentifier?.hasPrefix("nid:abcd1234")).toEventually(beTrue())
            }
            it("should track the push notify event when a push notification is processed with string alert") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let payload: [String: Any] = ["aps": ["alert": "a push alert"]]

                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                launchCollector?.processPushNotificationPayload(userInfo: payload, userAction: nil, userText: nil)

                let event = analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]
                expect(event?.tracked).toEventually(beTrue())
                expect((event?.parameters?[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String)?
                        .hasPrefix("msg:")).toEventually(beTrue())
                expect(launchCollector?.pushTrackingIdentifier?.hasPrefix("msg:")).toEventually(beTrue())
            }
            it("should track the push notify event when a push notification is processed with alert that only contains a title") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let payload: [String: Any] = ["aps": ["alert": ["title": "a push alert title"]]]

                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                launchCollector?.processPushNotificationPayload(userInfo: payload, userAction: nil, userText: nil)

                let event = analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]
                expect(event?.tracked).toEventually(beTrue())
                expect((event?.parameters?[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String)?
                        .hasPrefix("msg:")).toEventually(beTrue())
                expect(launchCollector?.pushTrackingIdentifier?.hasPrefix("msg:")).toEventually(beTrue())
            }
            it("should track the push notify event when a push notification is processed with alert that contains a title and a body") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let payload: [String: Any] = ["aps": ["alert": ["title": "a push alert title", "body": "a push alert body"]]]

                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                launchCollector?.processPushNotificationPayload(userInfo: payload, userAction: nil, userText: nil)

                let event = analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]
                expect(event?.tracked).toEventually(beTrue())
                expect((event?.parameters?[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String)?
                        .hasPrefix("msg:")).toEventually(beTrue())
                expect(launchCollector?.pushTrackingIdentifier?.hasPrefix("msg:")).toEventually(beTrue())
            }
            it("should not track the push notify event when a push notification is processed with an unexpected alert") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let payload: [String: Any] = ["foo": "bar"]

                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                launchCollector?.processPushNotificationPayload(userInfo: payload, userAction: nil, userText: nil)
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).toEventually(beFalse())
                expect(launchCollector?.pushTrackingIdentifier).toEventually(beNil())
            }
            it("should process UNNotificationResponse when the trigger is UNPushNotificationTrigger") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let trigger = UNPushNotificationTrigger(coder: PushNotificationTriggerCoder(repeats: false))
                let textInputNotificationResponse = UNTextInputNotificationResponse.response(trigger: trigger)!

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                let result = launchCollector?.processPushNotificationResponse(textInputNotificationResponse)
                var processedTrigger: UNNotificationTrigger?
                if case .success(let aTrigger) = result { processedTrigger = aTrigger }

                let event = analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]
                expect(processedTrigger).to(equal(trigger))
                expect(event?.tracked).to(beTrue())
                expect((event?.parameters?[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] as? String)?
                        .hasPrefix("rid:1234abcd")).to(beTrue())
                expect(launchCollector?.pushTrackingIdentifier?.hasPrefix("rid:1234abcd")).to(beTrue())
            }
            it("should not process UNNotificationResponse when the trigger is UNLocationNotificationTrigger") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let trigger = UNLocationNotificationTrigger(coder: LocationNotificationTriggerCoder(repeats: false, region: CLRegion()))
                let textInputNotificationResponse = UNTextInputNotificationResponse.response(trigger: trigger)!

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(analyticsTrackerMock?.dictionary?[AnalyticsManager.Event.Name.pushNotification]?.tracked).to(beFalse())
                let result = launchCollector?.processPushNotificationResponse(textInputNotificationResponse)
                var error: RAnalyticsLaunchCollectorError?
                if case .failure(let anError) = result { error = anError }
                expect(error).to(equal(RAnalyticsLaunchCollectorError.triggerTypeIsIncorrect))
                expect(launchCollector?.pushTrackingIdentifier).to(beNil())
            }
            it("should not process UNNotificationResponse when the trigger is nil") {
                let analyticsTrackerMock = dependenciesFactory.resolveObject(AnalyticsTrackerMock.self) as? AnalyticsTrackerMock
                analyticsTrackerMock?.dictionary = [AnalyticsManager.Event.Name.pushNotification: TrackerResult(tracked: false, parameters: nil)]

                let textInputNotificationResponse = UNTextInputNotificationResponse.response(trigger: nil)!

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                let result = launchCollector?.processPushNotificationResponse(textInputNotificationResponse)
                var error: RAnalyticsLaunchCollectorError?
                if case .failure(let anError) = result { error = anError }
                expect(error).to(equal(RAnalyticsLaunchCollectorError.triggerTypeIsIncorrect))
                expect(launchCollector?.pushTrackingIdentifier).to(beNil())
            }
            it("should reset to defaults") {
                let userDefaultsMock = dependenciesFactory.resolveObject(UserDefaultsMock.self) as? UserDefaultsMock

                let date = Date()
                userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: date,
                                                Constants.lastUpdateDateKey: date,
                                                Constants.lastLaunchDateKey: date,
                                                Constants.lastVersionKey: "v1.0",
                                                Constants.lastVersionLaunchesKey: 10]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesFactory: dependenciesFactory)
                expect(launchCollector?.installLaunchDate).to(equal(date))
                expect(launchCollector?.lastUpdateDate).to(equal(date))
                expect(launchCollector?.lastLaunchDate).to(equal(date))
                expect(launchCollector?.lastVersion).to(equal("v1.0"))
                expect(launchCollector?.lastVersionLaunches).to(equal(10))

                let distantDate = Date.distantPast
                userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: distantDate,
                                                Constants.lastUpdateDateKey: distantDate,
                                                Constants.lastLaunchDateKey: distantDate,
                                                Constants.lastVersionKey: "v100",
                                                Constants.lastVersionLaunchesKey: 100]

                launchCollector?.resetToDefaults()
                expect(launchCollector?.installLaunchDate).to(equal(distantDate))
                expect(launchCollector?.lastUpdateDate).to(equal(distantDate))
                expect(launchCollector?.lastLaunchDate).to(equal(distantDate))
                expect(launchCollector?.lastVersion).to(equal("v100"))
                expect(launchCollector?.lastVersionLaunches).to(equal(100))
            }
        }
    }
}
