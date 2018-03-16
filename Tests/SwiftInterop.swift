import XCTest
import RAnalytics
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

        AnalyticsManager.spoolRecord(RAnalyticsRecord(accountId: 477, serviceId: 999))

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
    public class Tracker2 : NSObject, RAnalyticsTracker {
        public var lastEvent : RAnalyticsEvent?
        public var lastState : RAnalyticsState?
        public func processEvent(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
            switch state.origin {
            case RAnalyticsOrigin.InternalOrigin: break
            case RAnalyticsOrigin.ExternalOrigin: break
            case RAnalyticsOrigin.PushOrigin: break
            case RAnalyticsOrigin.OtherOrigin: break
            }

            switch state.loginMethod {
            case RAnalyticsLoginMethod.OneTapLoginLoginMethod:   break
            case RAnalyticsLoginMethod.PasswordInputLoginMethod: break
            case RAnalyticsLoginMethod.OtherLoginMethod:         break
            }

            if let _ = event.parameters["boo"] as? NSNumber {
                print("just testing parameter unwrapping")
            }

            if state.isLoggedIn {
                print("just checking the getter uses 'is'")
            }

            switch event.name {
            case RAnalyticsInitialLaunchEventName:
                lastEvent = (event.copy() as! RAnalyticsEvent)
                lastState = (state.copy() as! RAnalyticsState)
                return true
            case RAnalyticsSessionStartEventName: break
            case RAnalyticsSessionEndEventName: break
            case RAnalyticsApplicationUpdateEventName: break
            case RAnalyticsLoginEventName: break
            case RAnalyticsLogoutEventName:
                if let logoutMethod = event.parameters[RAnalyticsLogoutMethodEventParameter] as? String {
                    switch logoutMethod {
                    case RAnalyticsLocalLogoutMethod: break;
                    case RAnalyticsGlobalLogoutMethod: break;
                    default: break;
                    }
                }
                break
            case RAnalyticsInstallEventName: break
            default: break
            }

            lastEvent = nil
            lastState = nil
            return false
        }
    }

    func assignMockDeviceIdentifier(deviceIdentifier : String?) {
        // Ignore warning about unknown selector
        RAnalyticsManager.sharedInstance().performSelector(Selector("setDeviceIdentifier:"), withObject:deviceIdentifier)
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

        var event : RAnalyticsEvent = rat.eventWithEventType("foo", parameters: ["bar" : "baz"])
        XCTAssertNotNil(event)

        let manager = RAnalyticsManager.sharedInstance()
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.shouldUseStagingEnvironment)
        XCTAssert(manager.shouldTrackLastKnownLocation)
        XCTAssert(manager.shouldTrackAdvertisingIdentifier)
        manager.shouldUseStagingEnvironment = false
        manager.shouldTrackLastKnownLocation = true
        manager.shouldTrackAdvertisingIdentifier = true

        RAnalyticsManager.spoolRecord(RAnalyticsRecord(accountId: 477, serviceId: 999))

        let tracker = Tracker2()
        manager.addTracker(tracker)
        manager.process(event)
        XCTAssertNil(tracker.lastEvent)
        XCTAssertNil(tracker.lastState)

        event = RAnalyticsEvent(name: RAnalyticsInitialLaunchEventName, parameters: nil)
        manager.process(event)
        XCTAssertNotNil(tracker.lastEvent)
        XCTAssertNotNil(tracker.lastState)

        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(RAnalyticsWillUploadNotification, object:nil)
        nc.postNotificationName(RAnalyticsUploadFailureNotification, object:nil)
        nc.postNotificationName(RAnalyticsUploadSuccessNotification, object:nil)
    }
    #endif
}
