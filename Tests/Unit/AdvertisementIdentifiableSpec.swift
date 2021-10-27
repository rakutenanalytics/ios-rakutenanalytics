import Quick
import Nimble
import AdSupport.ASIdentifierManager
@testable import RAnalytics

final class AdvertisementIdentifiableSpec: QuickSpec {
    override func spec() {
        describe("advertisingIdentifierUUIDString") {
            it("should return a non-empty value") {
                let result = ASIdentifierManager.shared().advertisingIdentifierUUIDString
                expect(result).toNot(beEmpty())
            }

            it("should return 00000000-0000-0000-0000-000000000000 when App Tracking Transparency is not asked.") {
                let result = ASIdentifierManager.shared().advertisingIdentifierUUIDString
                expect(result).to(equal("00000000-0000-0000-0000-000000000000"))
            }

            it("should never crash") {
                (0..<10000).forEach { _ in
                    let result = ASIdentifierManager.shared().advertisingIdentifierUUIDString
                    expect(result).toNot(beEmpty())
                }
            }
        }
    }
}
