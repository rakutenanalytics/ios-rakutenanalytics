import XCTest
import RAnalytics
import RDeviceIdentifier

public class SwiftInterop: XCTestCase {
    @objc
    public class TrackerSwift: NSObject, Tracker {
        public var endpointURL: URL = URL(string: "https://endpoint.com")!

        public var lastEvent: AnalyticsManager.Event?
        public var lastState: AnalyticsManager.State?
        public func process(event: AnalyticsManager.Event, state: AnalyticsManager.State) -> Bool {

            // Testing NS_SWIFT_NAME conversion from Objective-C enum
            switch state.origin {
            case AnalyticsManager.State.Origin.internal,
                 AnalyticsManager.State.Origin.external,
                 AnalyticsManager.State.Origin.push: ()
            @unknown default: ()
            }

            switch state.loginMethod {
            case AnalyticsManager.State.LoginMethod.oneTapLogin,
                 AnalyticsManager.State.LoginMethod.passwordInput,
                 AnalyticsManager.State.LoginMethod.other: ()
            @unknown default:()
            }

            if event.parameters["boo"] is NSNumber {
                print("just testing parameter unwrapping")
            }

            if state.isLoggedIn {
                print("just checking the getter uses 'is'")
            }

            switch event.name {
            case AnalyticsManager.Event.Name.initialLaunch:
                lastEvent = (event.copy() as! AnalyticsManager.Event) // swiftlint:disable:this force_cast
                lastState = (state.copy() as! AnalyticsManager.State) // swiftlint:disable:this force_cast
                return true
            case AnalyticsManager.Event.Name.sessionStart,
                 AnalyticsManager.Event.Name.sessionEnd,
                 AnalyticsManager.Event.Name.install,
                 AnalyticsManager.Event.Name.applicationUpdate: ()
            case AnalyticsManager.Event.Name.login:
                print("User with tracking id '\(state.userIdentifier ?? "")' just logged in!")
            case AnalyticsManager.Event.Name.logout:
                if let logoutMethod = event.parameters[AnalyticsManager.Event.Parameter.logoutMethod] as? String {
                    switch logoutMethod {
                    case AnalyticsManager.Event.LogoutMethod.local,
                         AnalyticsManager.Event.LogoutMethod.global: ()
                    default: ()
                    }
                }
            default: ()
            }

            lastEvent = nil
            lastState = nil
            return false
        }
    }

    public func testSwiftInterop() {
        let rat: RAnalyticsRATTracker = RAnalyticsRATTracker.shared()
        XCTAssertNotNil(rat)

        var event: AnalyticsManager.Event = rat.event(withEventType: "foo", parameters: ["bar": "baz"])
        XCTAssertNotNil(event)

        let manager = AnalyticsManager.shared()!
        XCTAssertNotNil(manager)
        manager.shouldTrackLastKnownLocation = true
        manager.shouldTrackAdvertisingIdentifier = true
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

        let nCenter = NotificationCenter.default
        nCenter.post(name: NSNotification.Name.RAnalyticsWillUpload, object: nil)
        nCenter.post(name: NSNotification.Name.RAnalyticsUploadFailure, object: nil)
        nCenter.post(name: NSNotification.Name.RAnalyticsUploadSuccess, object: nil)
    }
}
