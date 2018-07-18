import XCTest
import RAnalytics
import RDeviceIdentifier

public class SwiftInterop : XCTestCase {
    @objc
    public class TrackerSwift : NSObject, Tracker {
        public var lastEvent : AnalyticsManager.Event?
        public var lastState : AnalyticsManager.State?
        public func process(event: AnalyticsManager.Event, state: AnalyticsManager.State) -> Bool {
            switch state.origin {
            case AnalyticsManager.State.Origin.internal: break
            case AnalyticsManager.State.Origin.external: break
            case AnalyticsManager.State.Origin.push:     break
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
                print("User with tracking id '\(state.userIdentifier ?? "")' just logged in!")
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

    public func testSwiftInterop() {
        let rat : RAnalyticsRATTracker = RAnalyticsRATTracker.shared()
        XCTAssertNotNil(rat)

        var event : AnalyticsManager.Event = rat.event(withEventType: "foo", parameters: ["bar" : "baz"])
        XCTAssertNotNil(event)

        let manager = AnalyticsManager.shared()
        XCTAssertNotNil(manager)
        manager.shouldUseStagingEnvironment = false
        manager.shouldTrackLastKnownLocation = true
        manager.shouldTrackAdvertisingIdentifier = true
        XCTAssertFalse(manager.shouldUseStagingEnvironment)
        XCTAssert(manager.shouldTrackLastKnownLocation)
        XCTAssert(manager.shouldTrackAdvertisingIdentifier)

        let tracker = TrackerSwift()
        manager.add(tracker)
        manager.process(event)
        XCTAssertNil(tracker.lastEvent)
        XCTAssertNil(tracker.lastState)

        event = AnalyticsManager.Event(name: AnalyticsManager.Event.Name.initialLaunch, parameters: nil)
        manager.process(event)
        XCTAssertNotNil(tracker.lastEvent)
        XCTAssertNotNil(tracker.lastState)

        let nc = NotificationCenter.default
        nc.post(name:NSNotification.Name.RAnalyticsWillUpload, object:nil)
        nc.post(name:NSNotification.Name.RAnalyticsUploadFailure, object:nil)
        nc.post(name:NSNotification.Name.RAnalyticsUploadSuccess, object:nil)
    }
}
