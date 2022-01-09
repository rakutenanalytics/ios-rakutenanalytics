import Quick
import Nimble
@testable import RAnalytics

final class PushEventErrorSpec: QuickSpec {

    override func spec() {
        describe("PushEventError") {
            context("fileUrlIsNil") {
                it("should not be equal") {
                    let error1: PushEventError = .fileUrlIsNil
                    let error2: PushEventError = .nativeError(error: NSError(domain: "domain2", code: 0, userInfo: nil))

                    expect(error1).toNot(equal(error2))
                }

                it("should be equal") {
                    let error1: PushEventError = .fileUrlIsNil
                    let error2: PushEventError = .fileUrlIsNil

                    expect(error1).to(equal(error2))
                }
            }

            context("fileDoesNotExist") {
                it("should not be equal") {
                    let error1: PushEventError = .fileDoesNotExist
                    let error2: PushEventError = .nativeError(error: NSError(domain: "domain2", code: 0, userInfo: nil))

                    expect(error1).toNot(equal(error2))
                }

                it("should be equal") {
                    let error1: PushEventError = .fileDoesNotExist
                    let error2: PushEventError = .fileDoesNotExist

                    expect(error1).to(equal(error2))
                }
            }

            context("nativeError") {
                it("should not be equal") {
                    let error1: PushEventError = .nativeError(error: NSError(domain: "domain1", code: 0, userInfo: nil))
                    let error2: PushEventError = .nativeError(error: NSError(domain: "domain2", code: 0, userInfo: nil))

                    expect(error1).toNot(equal(error2))
                }

                it("should be equal") {
                    let nsError = NSError(domain: "domain", code: 0, userInfo: nil)
                    let error1: PushEventError = .nativeError(error: nsError)
                    let error2: PushEventError = .nativeError(error: nsError)

                    expect(error1).to(equal(error2))
                }
            }
        }
    }
}
