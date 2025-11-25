import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics

final class AnalyticsErrorSpec: QuickSpec {
    override class func spec() {
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
            
            describe("ErrorConstants") {
                it("should return the expected pushConversionError") {
                    let error = ErrorConstants.pushConversionError
                    
                    expect(error).toNot(beNil())
                    expect(error.domain).to(equal(ErrorDomain.pushConversionTrackingErrorDomain))
                    expect(error.code).to(equal(ErrorCode.pushConversionTrackingFailure.rawValue))
                    expect(error.localizedDescription).to(equal(ErrorDescription.pushConversionTrackingFailed))
                    expect(error.localizedFailureReason).to(equal(ErrorReason.emptyParameters))
                }
            }
        }
    }
}
