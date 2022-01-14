import Quick
import Nimble
@testable import RAnalytics

final class AnalyticsErrorSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsError") {
            describe("nsError()") {
                it("should return the expected embedded error") {
                    let error = AnalyticsError.embeddedError(ErrorConstants.statusCodeError(with: 400))

                    expect(error.nsError()).toNot(beNil())
                    expect(error.nsError().domain).to(equal(NSURLErrorDomain))
                    expect(error.nsError().code).to(equal(NSURLErrorUnknown))
                    expect(error.nsError().localizedDescription).to(equal(ErrorDescription.statusCodeError))
                    expect(error.nsError().localizedFailureReason).to(equal(ErrorReason.statusCodeError(400)))
                }

                it("should return the expected detailed error") {
                    let error = AnalyticsError.detailedError(domain: "domain", code: 123, description: "description", reason: "reason")

                    expect(error.nsError()).toNot(beNil())
                    expect(error.nsError().domain).to(equal("domain"))
                    expect(error.nsError().code).to(equal(123))
                    expect(error.nsError().localizedDescription).to(equal("description"))
                    expect(error.nsError().localizedFailureReason).to(equal("reason"))
                }
            }

            describe("log()") {
                it("should log the expected embedded error") {
                    let error = AnalyticsError.embeddedError(ErrorConstants.statusCodeError(with: 400))

                    expect(error.log()).to(equal(error.nsError().localizedDescription))
                }

                it("should log the expected detailed error") {
                    let error = AnalyticsError.detailedError(domain: "domain", code: 123, description: "description", reason: "reason")

                    expect(error.log()).to(equal("domain, 123, description, reason"))
                }
            }
        }
    }
}
