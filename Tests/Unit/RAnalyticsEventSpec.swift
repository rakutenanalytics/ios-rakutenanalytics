import Quick
import Nimble
import UIKit
@testable import RAnalytics

// MARK: - AnalyticsManager.Event

private func defaultEvent() -> AnalyticsManager.Event {
    AnalyticsManager.Event(name: RAnalyticsRATTracker.Constants.ratGenericEventName,
                           parameters: [PayloadParameterKeys.etype: "value1"])
}

// MARK: - RAnalyticsEventSpec

final class RAnalyticsEventSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsManager.Event") {
            describe("init") {
                it("should have the correct default values") {
                    let event = defaultEvent()
                    expect(event.name).to(equal(RAnalyticsRATTracker.Constants.ratGenericEventName))
                    expect(event.parameters[PayloadParameterKeys.etype] as? String).to(equal("value1"))
                }
            }
            describe("copy") {
                it("should have the expected values") {
                    let event = defaultEvent()
                    guard let copiedEvent = event.copy() as? AnalyticsManager.Event else {
                        assertionFailure("AnalyticsManager.Event copy fails")
                        return
                    }
                    expect(copiedEvent.name).to(equal(event.name))
                    expect(copiedEvent.parameters == event.parameters).to(beTrue())
                    expect(copiedEvent).to(equal(event))
                }
            }
            describe("equal") {
                it("should be true if it has the same properties") {
                    let event = defaultEvent()
                    let otherEvent = defaultEvent()
                    expect(event.name).to(equal(otherEvent.name))
                    expect(event.parameters == otherEvent.parameters).to(beTrue())
                    expect(event).to(equal(otherEvent))
                }
                it("should be false if it has not the same properties") {
                    let event = defaultEvent()
                    let otherEvent = AnalyticsManager.Event(name: "otherName",
                                                            parameters: [PayloadParameterKeys.etype: "value2"])
                    expect(event.name).toNot(equal(otherEvent.name))
                    expect(event.parameters == otherEvent.parameters).to(beFalse())
                    expect(event).toNot(equal(otherEvent))
                }
                it("should be false if it doesn't match the Event type") {
                    let event = defaultEvent()
                    let anObject = UIView()
                    expect(event).toNot(equal(anObject))
                }
            }
            describe("hash") {
                it("should be equal if it is a copy of an other event") {
                    let event = defaultEvent()
                    guard let copiedEvent = event.copy() as? AnalyticsManager.Event else {
                        assertionFailure("AnalyticsManager.Event copy fails")
                        return
                    }
                    expect(event.hash).to(equal(copiedEvent.hash))
                }
                it("should be equal if the properties are equal") {
                    let event = defaultEvent()
                    let otherEvent = defaultEvent()
                    expect(event.hash).to(equal(otherEvent.hash))
                }
                it("should not be equal if the properties are not equal") {
                    let event = defaultEvent()
                    let otherEvent = AnalyticsManager.Event(name: "otherName",
                                                            parameters: [PayloadParameterKeys.etype: "value2"])
                    expect(event.hash).toNot(equal(otherEvent.hash))
                }
            }
            describe("secure coding") {
                it("should unarchive the same event with the same properties values") {
                    let event = defaultEvent()
                    let data = NSKeyedArchiver.archivedData(withRootObject: event)
                    let unarchivedEvent = NSKeyedUnarchiver.unarchiveObject(with: data) as? AnalyticsManager.Event
                    expect(event).to(equal(unarchivedEvent))
                    expect(event.name).to(equal(unarchivedEvent?.name))
                    expect(event.parameters == unarchivedEvent!.parameters).to(beTrue())
                }
                it("should decode the same event with the same properties values") {
                    let event = defaultEvent()

                    let data = NSMutableData()
                    let secureEncoder = NSKeyedArchiver(forWritingWith: data)
                    secureEncoder.requiresSecureCoding = true

                    let key = "event"
                    secureEncoder.encode(event, forKey: key)
                    secureEncoder.finishEncoding()

                    let secureDecoder = NSKeyedUnarchiver(forReadingWith: data as Data)
                    secureDecoder.requiresSecureCoding = true

                    let decodedEvent = secureDecoder.decodeObject(of: AnalyticsManager.Event.self, forKey: key)
                    secureDecoder.finishDecoding()

                    expect(event).to(equal(decodedEvent))
                    expect(event.name).to(equal(decodedEvent?.name))
                    expect(event.parameters == decodedEvent!.parameters).to(beTrue())
                }
            }
            describe("track") {
                it("should return true when the event is processed") {
                    let event = defaultEvent()
                    expect(event.track()).to(beTrue())
                }
            }
        }
    }
}
