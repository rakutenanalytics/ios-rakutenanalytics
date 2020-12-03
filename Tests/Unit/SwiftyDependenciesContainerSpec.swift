import Quick
import Nimble

private class Dependency {
    let name: String
    init(name: String) {
        self.name = name
    }
}
extension Dependency: Equatable {
    static func == (lhs: Dependency, rhs: Dependency) -> Bool {
        lhs.name == rhs.name
    }
}

private class AnalyticsHandler: Dependency {
    var advertisingIdentifierUUIDString: String {
        "mock"
    }
}

private class AdvertisingHandler: Dependency, AdvertisementIdentifiable {
    var advertisingIdentifierUUIDString: String {
        "mock"
    }
}

private class CookieInjector: Dependency {}

final class SwiftyDependenciesContainerSpec: QuickSpec {
    override func spec() {
        describe("SwiftyContainer") {
            describe("register") {
                it("should not register a reference that is already registered") {
                    let a = AnalyticsHandler(name: "a")
                    var swiftyContainer = SwiftyDependenciesContainer<Dependency>()
                    expect(swiftyContainer.register(a)).to(beTrue())
                    expect(swiftyContainer.register(a)).to(beFalse())
                }
                it("should not register the same type") {
                    let a = AnalyticsHandler(name: "a")
                    let b = AnalyticsHandler(name: "b")
                    var swiftyContainer = SwiftyDependenciesContainer<Dependency>()
                    expect(swiftyContainer.register(a)).to(beTrue())
                    expect(swiftyContainer.register(b)).to(beFalse())
                }
            }
            describe("resolve") {
                it("should return nil when there are not registered dependencies") {
                    let swiftyContainer = SwiftyDependenciesContainer<Dependency>()
                    expect(swiftyContainer.resolve(AnalyticsHandler.self)).to(beNil())
                }
                it("should return nil when the type is not found") {
                    var swiftyContainer = SwiftyDependenciesContainer<Dependency>()
                    swiftyContainer.register(AnalyticsHandler(name: "a"))
                    swiftyContainer.register(AdvertisingHandler(name: "b"))
                    expect(swiftyContainer.resolve(CookieInjector.self)).to(beNil())
                }
                it("should return the correct reference") {
                    let a: AdvertisingHandler = AdvertisingHandler(name: "a")
                    var swiftyContainer = SwiftyDependenciesContainer<Dependency>()
                    swiftyContainer.register(a)
                    expect(swiftyContainer.resolve(AdvertisingHandler.self)).to(equal(a))
                    expect(swiftyContainer.resolve(AdvertisementIdentifiable.self) as? AdvertisingHandler).to(equal(a))
                }
            }
        }
    }
}
