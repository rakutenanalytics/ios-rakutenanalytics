import Quick
import Nimble
@testable import RAnalytics

final class GeoActionParametersSpec: QuickSpec {

    override func spec() {
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
            }
        }
    }
}
