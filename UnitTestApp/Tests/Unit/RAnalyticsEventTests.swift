import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - AnalyticsManager.Event

private func defaultEvent() -> AnalyticsManager.Event {
    AnalyticsManager.Event(name: RAnalyticsRATTracker.Constants.ratGenericEventName, parameters: [PayloadParameterKeys.etype: "value1"])
}

// MARK: - RAnalyticsEventTests

@Suite("AnalyticsManager.Event")
struct RAnalyticsEventTests {
    @Suite("init")
    struct InitTests {
        @Test("should have the correct default values")
        func testShouldHaveTheCorrectDefaultValues() {
            let event = defaultEvent()
            #expect(event.name == RAnalyticsRATTracker.Constants.ratGenericEventName)
            #expect(event.parameters[PayloadParameterKeys.etype] as? String == "value1")
        }
    }

    @Suite("copy")
    struct CopyTests {
        @Test("should have the expected values")
        func testShouldHaveTheExpectedValues() {
            let event = defaultEvent()
            guard let copiedEvent = event.copy() as? AnalyticsManager.Event else {
                assertionFailure("AnalyticsManager.Event copy fails")
                return
            }
            #expect(copiedEvent.name == event.name)
            #expect(copiedEvent.parameters == event.parameters)
            #expect(copiedEvent == event)
        }
    }

    @Suite("equal")
    struct EqualTests {
        @Test("should be true if it has the same properties")
        func testShouldBeTrueIfItHasTheSameProperties() {
            let event = defaultEvent()
            let otherEvent = defaultEvent()
            #expect(event.name == otherEvent.name)
            #expect(event.parameters == otherEvent.parameters)
            #expect(event == otherEvent)
        }
        
        @Test("should be false if it has not the same properties")
        func testShouldBeFalseIfItHasNotTheSameProperties() {
            let event = defaultEvent()
            let otherEvent = AnalyticsManager.Event(name: "otherName", parameters: [PayloadParameterKeys.etype: "value2"])
            #expect(event.name != otherEvent.name)
            #expect(!(event.parameters == otherEvent.parameters))
            #expect(event != otherEvent)
        }
        
        @MainActor
        @Test("should be false if it doesn't match the Event type")
        func testShouldBeFalseIfItDoesntMatchTheEventType() {
            let event = defaultEvent()
            let anObject = UIView()
            #expect(event != anObject)
        }
    }

    @Suite("hash")
    struct HashTests {
        @Test("should be equal if it is a copy of an other event")
        func testShouldBeEqualIfItIsACopyOfAnOtherEvent() {
            let event = defaultEvent()
            guard let copiedEvent = event.copy() as? AnalyticsManager.Event else {
                assertionFailure("AnalyticsManager.Event copy fails")
                return
            }
            #expect(event.hash == copiedEvent.hash)
        }
        
        @Test("should be equal if the properties are equal")
        func testShouldBeEqualIfThePropertiesAreEqual() {
            let event = defaultEvent()
            let otherEvent = defaultEvent()
            #expect(event.hash == otherEvent.hash)
        }
        
        @Test("should not be equal if the properties are not equal")
        func testShouldNotBeEqualIfThePropertiesAreNotEqual() {
            let event = defaultEvent()
            let otherEvent = AnalyticsManager.Event(name: "otherName", parameters: [PayloadParameterKeys.etype: "value2"])
            #expect(event.hash != otherEvent.hash)
        }
    }

    @Suite("secure coding")
    struct SecureCodingTests {
        @Test("should unarchive the same event with the same properties values")
        func testShouldUnarchiveTheSameEventWithTheSamePropertiesValues() throws {
            let event = defaultEvent()
            let data: Data! = try? NSKeyedArchiver.archivedData(withRootObject: event, requiringSecureCoding: true)
            let unarchivedEvent = try? NSKeyedUnarchiver.unarchivedObject(ofClass: AnalyticsManager.Event.self, from: data)
            #expect(event == unarchivedEvent)
            #expect(event.name == unarchivedEvent?.name)
            #expect(event.parameters == unarchivedEvent!.parameters)
        }
        
        @Test("should decode the same event with the same properties values")
        func testShouldDecodeTheSameEventWithTheSamePropertiesValues() throws {
            let event = defaultEvent()

            let secureEncoder = NSKeyedArchiver(requiringSecureCoding: true)

            let key = "event"
            secureEncoder.encode(event, forKey: key)
            secureEncoder.finishEncoding()

            let data = secureEncoder.encodedData
            let secureDecoder: NSKeyedUnarchiver! = try? NSKeyedUnarchiver(forReadingFrom: data as Data)
            secureDecoder.requiresSecureCoding = true

            let decodedEvent = secureDecoder.decodeObject(of: AnalyticsManager.Event.self, forKey: key)
            secureDecoder.finishDecoding()

            #expect(event == decodedEvent)
            #expect(event.name == decodedEvent?.name)
            #expect(event.parameters == decodedEvent!.parameters)
        }
    }

    @Suite("track")
    struct TrackTests {
        @Test("should return true when the event is processed")
        func testShouldReturnTrueWhenTheEventIsProcessed() {
            let event = defaultEvent()
            let result = MainDependenciesContainer.analyticsManager.process(event)
            #expect(result == true)
        }
    }

    @Suite("Event names")
    struct EventNamesTests {
        @Test("should have viewableImpression event name")
        func testShouldHaveViewableImpressionEventName() {
            #expect(RAnalyticsEvent.Name.viewableImpression == "viewable_impression")
        }
    }

    @Suite("Event parameters")
    struct EventParametersTests {
        @Test("should have viewable impression parameters")
        func testShouldHaveViewableImpressionParameters() {
            #expect(RAnalyticsEvent.Parameter.viewableData == "viewable_data")
            #expect(RAnalyticsEvent.Parameter.itemId == "item_id")
            #expect(RAnalyticsEvent.Parameter.itemTitle == "item_title")
            #expect(RAnalyticsEvent.Parameter.itemDescription == "item_description")
            #expect(RAnalyticsEvent.Parameter.itemCategory == "item_category")
            #expect(RAnalyticsEvent.Parameter.itemGenre == "item_genre")
            #expect(RAnalyticsEvent.Parameter.itemPrice == "item_price")
            #expect(RAnalyticsEvent.Parameter.itemPosition == "item_position")
            #expect(RAnalyticsEvent.Parameter.visibilityPercentage == "visibility_percentage")
            #expect(RAnalyticsEvent.Parameter.dwellTime == "dwell_time")
            #expect(RAnalyticsEvent.Parameter.viewableImpressionTimestamp == "viewable_impression_timestamp")
            #expect(RAnalyticsEvent.Parameter.viewportBounds == "viewport_bounds")
            #expect(RAnalyticsEvent.Parameter.screenName == "screen_name")
            #expect(RAnalyticsEvent.Parameter.triggerReason == "trigger_reason")
        }

        @Test("should create event with viewable impression parameters")
        func testShouldCreateEventWithViewableImpressionParameters() {
            let viewableData: [String: Any] = [
                "event_data": [["item_id": "item1"]]
            ]
            let parameters: [String: Any] = [
                "eventName": RAnalyticsEvent.Name.viewableImpression,
                RAnalyticsEvent.Parameter.topLevelObject: viewableData
            ]
            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom, parameters: parameters)
            #expect(event.name == RAnalyticsEvent.Name.custom)
            let viewableDataParam = event.parameters[RAnalyticsEvent.Parameter.topLevelObject] as? [String: Any]
            #expect(viewableDataParam != nil)
            #expect((viewableDataParam?["event_data"] as? [[String: Any]])?.count == 1)
        }
    }
}
