import XCTest
import RSDKAnalytics
import RSDKDeviceInformation

public class SwiftInterop : XCTestCase {
    #if swift(>=3.0)
    @objc
    public class Tracker3 : NSObject, Tracker {
        public var lastEvent : AnalyticsManager.Event?
        public var lastState : AnalyticsManager.State?
        public func process(event: AnalyticsManager.Event, state: AnalyticsManager.State) -> Bool {
            switch state.origin {
            case AnalyticsManager.State.Origin.internal: break
            case AnalyticsManager.State.Origin.external: break
            case AnalyticsManager.State.Origin.push:     break
            case AnalyticsManager.State.Origin.other:    break
            }

            switch state.loginMethod {
            case AnalyticsManager.State.LoginMethod.oneTapLogin:   break
            case AnalyticsManager.State.LoginMethod.passwordInput: break
            case AnalyticsManager.State.LoginMethod.other:         break
            }

            if let _ = event.parameters["boo"] as? NSNumber {
                print("just testing parameter unwrapping")
            }

            if state.isLoggedIn {
                print("just checking the getter uses 'is'")
            }

            switch event.name {
            case AnalyticsManager.Event.Name.initialLaunch:
                lastEvent = (event.copy() as! AnalyticsManager.Event)
                lastState = (state.copy() as! AnalyticsManager.State)
                return true
            case AnalyticsManager.Event.Name.sessionStart: break
            case AnalyticsManager.Event.Name.sessionEnd: break
            case AnalyticsManager.Event.Name.applicationUpdate: break
            case AnalyticsManager.Event.Name.login:
                print("User with tracking id '\(state.userid)' just logged in!")
                break
            case AnalyticsManager.Event.Name.logout:
                if let logoutMethod = event.parameters[AnalyticsManager.Event.Parameter.logoutMethod] as? String {
                    switch logoutMethod {
                    case AnalyticsManager.Event.LogoutMethod.local: break;
                    case AnalyticsManager.Event.LogoutMethod.global: break;
                    default: break;
                    }
                }
                break
            case AnalyticsManager.Event.Name.install: break
            default: break
            }

            lastEvent = nil
            lastState = nil
            return false
        }
    }

    func assignMockDeviceIdentifier(_ deviceIdentifier : String?) {
        // Ignore warning about unknown selector
        AnalyticsManager.shared().perform(Selector("setDeviceIdentifier:"), with: deviceIdentifier)
    }
    public override func setUp() {
        assignMockDeviceIdentifier("Test")
    }

    public override func tearDown() {
        assignMockDeviceIdentifier(nil)
    }

    public func testSwift3Interop() {
        let rat : RATTracker = RATTracker.shared()
        XCTAssertNotNil(rat)
        rat.configure(withAccountId: 477)
        rat.configure(withApplicationId: 999)

        var event : AnalyticsManager.Event = rat.event(withEventType: "foo", parameters: ["bar" : "baz"])
        XCTAssertNotNil(event)

        let manager = AnalyticsManager.shared()
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.shouldUseStagingEnvironment)
        XCTAssert(manager.shouldTrackLastKnownLocation)
        XCTAssert(manager.shouldTrackAdvertisingIdentifier)
        manager.shouldUseStagingEnvironment = false
        manager.shouldTrackLastKnownLocation = true
        manager.shouldTrackAdvertisingIdentifier = true

        AnalyticsManager.spoolRecord(RSDKAnalyticsRecord(accountId: 477, serviceId: 999))

        let tracker = Tracker3()
        manager.add(tracker)
        manager.process(event)
        XCTAssertNil(tracker.lastEvent)
        XCTAssertNil(tracker.lastState)

        event = AnalyticsManager.Event(name: AnalyticsManager.Event.Name.initialLaunch, parameters: nil)
        manager.process(event)
        XCTAssertNotNil(tracker.lastEvent)
        XCTAssertNotNil(tracker.lastState)

        let nc = NotificationCenter.default
        nc.post(name:Notification.Name.RATWillUpload, object:nil)
        nc.post(name:Notification.Name.RATUploadFailure, object:nil)
        nc.post(name:Notification.Name.RATUploadSuccess, object:nil)
    }

    #else
    public class Tracker2 : NSObject, RSDKAnalyticsTracker {
        public var lastEvent : RSDKAnalyticsEvent?
        public var lastState : RSDKAnalyticsState?
        public func processEvent(event: RSDKAnalyticsEvent, state: RSDKAnalyticsState) -> Bool {
            switch state.origin {
            case RSDKAnalyticsOrigin.InternalOrigin: break
            case RSDKAnalyticsOrigin.ExternalOrigin: break
            case RSDKAnalyticsOrigin.PushOrigin: break
            case RSDKAnalyticsOrigin.OtherOrigin: break
            }

            switch state.loginMethod {
            case RSDKAnalyticsLoginMethod.OneTapLoginLoginMethod:   break
            case RSDKAnalyticsLoginMethod.PasswordInputLoginMethod: break
            case RSDKAnalyticsLoginMethod.OtherLoginMethod:         break
            }

            if let _ = event.parameters["boo"] as? NSNumber {
                print("just testing parameter unwrapping")
            }

            if state.isLoggedIn {
                print("just checking the getter uses 'is'")
            }

            switch event.name {
            case RSDKAnalyticsInitialLaunchEventName:
                lastEvent = (event.copy() as! RSDKAnalyticsEvent)
                lastState = (state.copy() as! RSDKAnalyticsState)
                return true
            case RSDKAnalyticsSessionStartEventName: break
            case RSDKAnalyticsSessionEndEventName: break
            case RSDKAnalyticsApplicationUpdateEventName: break
            case RSDKAnalyticsLoginEventName: break
            case RSDKAnalyticsLogoutEventName:
                if let logoutMethod = event.parameters[RSDKAnalyticsLogoutMethodEventParameter] as? String {
                    switch logoutMethod {
                    case RSDKAnalyticsLocalLogoutMethod: break;
                    case RSDKAnalyticsGlobalLogoutMethod: break;
                    default: break;
                    }
                }
                break
            case RSDKAnalyticsInstallEventName: break
            default: break
            }

            lastEvent = nil
            lastState = nil
            return false
        }
    }

    func assignMockDeviceIdentifier(deviceIdentifier : String?) {
        // Ignore warning about unknown selector
        RSDKAnalyticsManager.sharedInstance().performSelector(Selector("setDeviceIdentifier:"), withObject:deviceIdentifier)
    }
    public override func setUp() {
        assignMockDeviceIdentifier("Test")
    }

    public override func tearDown() {
        assignMockDeviceIdentifier(nil)
    }

    public func testSwift2Interop() {
        let rat : RATTracker = RATTracker.sharedInstance()
        XCTAssertNotNil(rat)
        rat.configureWithAccountId(477)
        rat.configureWithApplicationId(999)

        var event : RSDKAnalyticsEvent = rat.eventWithEventType("foo", parameters: ["bar" : "baz"])
        XCTAssertNotNil(event)

        let manager = RSDKAnalyticsManager.sharedInstance()
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.shouldUseStagingEnvironment)
        XCTAssert(manager.shouldTrackLastKnownLocation)
        XCTAssert(manager.shouldTrackAdvertisingIdentifier)
        manager.shouldUseStagingEnvironment = false
        manager.shouldTrackLastKnownLocation = true
        manager.shouldTrackAdvertisingIdentifier = true

        RSDKAnalyticsManager.spoolRecord(RSDKAnalyticsRecord(accountId: 477, serviceId: 999))

        let tracker = Tracker2()
        manager.addTracker(tracker)
        manager.process(event)
        XCTAssertNil(tracker.lastEvent)
        XCTAssertNil(tracker.lastState)

        event = RSDKAnalyticsEvent(name: RSDKAnalyticsInitialLaunchEventName, parameters: nil)
        manager.process(event)
        XCTAssertNotNil(tracker.lastEvent)
        XCTAssertNotNil(tracker.lastState)

        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(RATWillUploadNotification, object:nil)
        nc.postNotificationName(RATUploadFailureNotification, object:nil)
        nc.postNotificationName(RATUploadSuccessNotification, object:nil)
    }
    #endif
}
