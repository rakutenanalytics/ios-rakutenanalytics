import Quick
import Nimble

final class EventCheckerSpec: QuickSpec {
    override func spec() {
        describe("EventCheckerSpec") {
            describe("shouldProcess") {
                context("shouldTrackEventHandler is nil") {
                    context("disabledEventsAtBuildTime is nil") {
                        it("should return true if disabledEventsAtBuildTime is nil") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: nil)
                            expect(eventChecker.shouldTrackEventHandler).to(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beTrue())
                        }
                    }
                    context("disabledEventsAtBuildTime is empty") {
                        it("should return true if disabledEventsAtBuildTime is empty") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: [])
                            expect(eventChecker.shouldTrackEventHandler).to(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beTrue())
                        }
                    }
                    context("disabledEventsAtBuildTime is not nil and not empty") {
                        it("should return false if the event exists in disabledEventsAtBuildTime") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: ["foo"])
                            expect(eventChecker.shouldProcess("foo")).to(beFalse())
                        }
                    }
                }
                context("shouldTrackEventHandler is not nil") {
                    context("disabledEventsAtBuildTime is nil") {
                        it("should return false if the event is not auhorized by shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime:nil)
                            eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beFalse())
                        }
                        it("should return true if the event is auhorized by shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime:nil)
                            eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beTrue())
                        }
                    }
                    context("disabledEventsAtBuildTime is empty") {
                        it("should return false if the event is not auhorized by shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: [])
                            eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beFalse())
                        }
                        it("should return true if the event is auhorized by shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: [])
                            eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beTrue())
                        }
                    }
                    context("disabledEventsAtBuildTime is not nil and not empty") {
                        it("should return false if the event exists in disabledEventsAtBuildTime but not authorized in shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: ["foo"])
                            eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beFalse())
                        }
                        it("should return false if the event does not exist in disabledEventsAtBuildTime but not authorized in shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: ["hello"])
                            eventChecker.shouldTrackEventHandler = { $0 != "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beFalse())
                        }
                        it("should return true if the event exists in disabledEventsAtBuildTime but authorized in shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: ["foo"])
                            eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beTrue())
                        }
                        it("should return true if the event does not exist in disabledEventsAtBuildTime but authorized in shouldTrackEventHandler") {
                            let eventChecker = EventChecker(disabledEventsAtBuildTime: ["hello"])
                            eventChecker.shouldTrackEventHandler = { $0 == "foo" }
                            expect(eventChecker.shouldTrackEventHandler).toNot(beNil())
                            expect(eventChecker.shouldProcess("foo")).to(beTrue())
                        }
                    }
                }
            }
        }
    }
}
