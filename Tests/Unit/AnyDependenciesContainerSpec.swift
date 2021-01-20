import Quick
import Nimble
import AdSupport
import WebKit

private final class RAnalyticsHandler1: NSObject {}
private final class RAnalyticsHandler2: NSObject {}
private final class RAnalyticsHandler3: NSObject {}

final class AnyDependenciesContainerSpec: QuickSpec {
    override func spec() {
        describe("AnyDependenciesContainer") {
            describe("register") {
                it("should not register an object that is already registered") {
                    let dependenciesContainer = AnyDependenciesContainer()
                    let handler = RAnalyticsHandler1()
                    expect(dependenciesContainer.registerObject(handler)).to(beTrue())
                    expect(dependenciesContainer.registerObject(handler)).to(beFalse())
                }
                it("should not register an object that has the same type") {
                    let dependenciesContainer = AnyDependenciesContainer()
                    let handlerA = RAnalyticsHandler1()
                    let handlerB = RAnalyticsHandler1()
                    expect(dependenciesContainer.registerObject(handlerA)).to(beTrue())
                    expect(dependenciesContainer.registerObject(handlerB)).to(beFalse())
                }
            }
        }

        describe("resolve") {
            it("should return nil when there are not registered dependencies") {
                let dependenciesContainer = AnyDependenciesContainer()
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler1.self)).to(beNil())
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler2.self)).to(beNil())
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler3.self)).to(beNil())
            }
            it("should return nil when the type is not found") {
                let dependenciesContainer = AnyDependenciesContainer()
                dependenciesContainer.registerObject(RAnalyticsHandler2())
                dependenciesContainer.registerObject(RAnalyticsHandler3())
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler1.self)).to(beNil())
            }
            it("should return the correct object when the type is found") {
                let dependenciesContainer = AnyDependenciesContainer()
                let handler1 = RAnalyticsHandler1()
                let handler2 = RAnalyticsHandler2()
                let handler3 = RAnalyticsHandler3()
                expect(dependenciesContainer.registerObject(handler1)).to(beTrue())
                expect(dependenciesContainer.registerObject(handler2)).to(beTrue())
                expect(dependenciesContainer.registerObject(handler3)).to(beTrue())
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler1.self)).to(equal(handler1))
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler2.self)).to(equal(handler2))
                expect(dependenciesContainer.resolveObject(RAnalyticsHandler3.self)).to(equal(handler3))
            }
        }
    }
}
