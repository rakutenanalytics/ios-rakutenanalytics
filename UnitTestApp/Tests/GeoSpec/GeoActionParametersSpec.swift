import Quick
import Nimble
@testable import RakutenAnalytics

final class GeoActionParametersSpec: QuickSpec {

    override class func spec() {
        describe("GeoActionParameters") {
            context("instance when its stored properties are non-nil") {
                let actionParameters = GeoActionParameters(actionType: "test-actionType",
                                                           actionLog: "test-actionLog",
                                                           actionId: "test-actionId",
                                                           actionDuration: "test-actionDuration",
                                                           additionalLog: "test-additionalLog")

                it("should contain non-nil values in its stored properties") {
                    expect(actionParameters.actionType).toNot(beNil())
                    expect(actionParameters.actionLog).toNot(beNil())
                    expect(actionParameters.actionId).toNot(beNil())
                    expect(actionParameters.actionDuration).toNot(beNil())
                    expect(actionParameters.additionalLog).toNot(beNil())

                    expect(actionParameters.actionType).to(equal("test-actionType"))
                    expect(actionParameters.actionLog).to(equal("test-actionLog"))
                    expect(actionParameters.actionId).to(equal("test-actionId"))
                    expect(actionParameters.actionDuration).to(equal("test-actionDuration"))
                    expect(actionParameters.additionalLog).to(equal("test-additionalLog"))
                }
            }

            context("instance when its stored properties are nil") {
                let actionParameters = GeoActionParameters(actionType: nil,
                                                           actionLog: nil,
                                                           actionId: nil,
                                                           actionDuration: nil,
                                                           additionalLog: nil)

                it("should contain nil values in its stored properties") {
                    expect(actionParameters.actionType).to(beNil())
                    expect(actionParameters.actionLog).to(beNil())
                    expect(actionParameters.actionId).to(beNil())
                    expect(actionParameters.actionDuration).to(beNil())
                    expect(actionParameters.additionalLog).to(beNil())
                }

                it("should contain nil when stored properties are not set on GeoActionParameters") {
                    let geoActionParameters = GeoActionParameters()
                    expect(geoActionParameters.actionType).to(beNil())
                    expect(geoActionParameters.actionLog).to(beNil())
                    expect(geoActionParameters.actionId).to(beNil())
                    expect(geoActionParameters.actionDuration).to(beNil())
                    expect(geoActionParameters.additionalLog).to(beNil())
                }
            }

            context("instance when its stored properties contais both non-nil and nil") {
                let actionParameters = GeoActionParameters(actionLog: "actionLog",
                                                           actionId: "123")
                it("should contain nil when values are not passed in its stored properties") {
                    expect(actionParameters.actionType).to(beNil())
                    expect(actionParameters.actionDuration).to(beNil())
                }
                
                it("should contain non-nil values when its stored properties contains values") {
                    expect(actionParameters.actionLog).to(equal("actionLog"))
                    expect(actionParameters.actionId).to(equal("123"))
                }
            }
        }
    }
}
