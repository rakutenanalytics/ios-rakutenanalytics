import Testing
import Foundation
@testable import RakutenAnalytics

@Suite("EventCheckerTests")
struct EventCheckerTests {
    @Suite("shouldProcess")
    struct ShouldProcessTests {
        @Suite("shouldTrackEventHandler is nil")
        struct ShouldTrackEventHandlerIsNilTests {
            @Suite("disabledEventsAtBuildTime is nil")
            struct DisabledEventsAtBuildTimeIsNilTests {
                @Test("should return true if disabledEventsAtBuildTime is nil")
                func testReturnsTrueWhenDisabledEventsAtBuildTimeIsNil() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: nil)
                    #expect(eventChecker.shouldTrackEventHandler == nil)
                    #expect(eventChecker.shouldProcess("foo") == true)
                }
            }
            
            @Suite("disabledEventsAtBuildTime is empty")
            struct DisabledEventsAtBuildTimeIsEmptyTests {
                @Test("should return true if disabledEventsAtBuildTime is empty")
                func testReturnsTrueWhenDisabledEventsAtBuildTimeIsEmpty() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: [])
                    #expect(eventChecker.shouldTrackEventHandler == nil)
                    #expect(eventChecker.shouldProcess("foo") == true)
                }
            }
            
            @Suite("disabledEventsAtBuildTime is not nil and not empty")
            struct DisabledEventsAtBuildTimeIsNotNilAndNotEmptyTests {
                @Test("should return false if the event exists in disabledEventsAtBuildTime")
                func testReturnsFalseWhenEventExistsInDisabledEventsAtBuildTime() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: ["foo"])
                    #expect(eventChecker.shouldProcess("foo") == false)
                }
            }
        }
        
        @Suite("shouldTrackEventHandler is not nil")
        struct ShouldTrackEventHandlerIsNotNilTests {
            @Suite("disabledEventsAtBuildTime is nil")
            struct DisabledEventsAtBuildTimeIsNilTests {
                @Test("should return false if the event is not auhorized by shouldTrackEventHandler")
                func testReturnsFalseWhenEventNotAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: nil)
                    eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == false)
                }
                
                @Test("should return true if the event is auhorized by shouldTrackEventHandler")
                func testReturnsTrueWhenEventAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: nil)
                    eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == true)
                }
            }
            
            @Suite("disabledEventsAtBuildTime is empty")
            struct DisabledEventsAtBuildTimeIsEmptyTests {
                @Test("should return false if the event is not auhorized by shouldTrackEventHandler")
                func testReturnsFalseWhenEventNotAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: [])
                    eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == false)
                }
                
                @Test("should return true if the event is auhorized by shouldTrackEventHandler")
                func testReturnsTrueWhenEventAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: [])
                    eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == true)
                }
            }
            
            @Suite("disabledEventsAtBuildTime is not nil and not empty")
            struct DisabledEventsAtBuildTimeIsNotNilAndNotEmptyTests {
                @Test("should return false if the event exists in disabledEventsAtBuildTime but not authorized in shouldTrackEventHandler")
                func testReturnsFalseWhenEventExistsButNotAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: ["foo"])
                    eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == false)
                }
                
                // swiftlint:disable:next line_length
                @Test("should return false if the event does not exist in disabledEventsAtBuildTime but not authorized in shouldTrackEventHandler")
                func testReturnsFalseWhenEventDoesNotExistButNotAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: ["hello"])
                    eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == false)
                }
                
                @Test("should return true if the event exists in disabledEventsAtBuildTime but authorized in shouldTrackEventHandler")
                func testReturnsTrueWhenEventExistsAndAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: ["foo"])
                    eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == true)
                }
                
                @Test("should return true if the event does not exist in disabledEventsAtBuildTime but authorized in shouldTrackEventHandler")
                func testReturnsTrueWhenEventDoesNotExistButAuthorized() {
                    let eventChecker = EventChecker(disabledEventsAtBuildTime: ["hello"])
                    eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                    #expect(eventChecker.shouldTrackEventHandler != nil)
                    #expect(eventChecker.shouldProcess("foo") == true)
                }
            }
        }
    }
}
