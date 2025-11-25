import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAdvertisingIdentifierHandlerSpec

final class RAdvertisingIdentifierHandlerSpec: QuickSpec {
    override class func spec() {
        describe("RAdvertisingIdentifierHandler") {
            describe("idfa") {
                let dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.adIdentifierManager = ASIdentifierManagerMock()

                let mock = (dependenciesContainer.adIdentifierManager as? ASIdentifierManagerMock)

                it("should return nil when idfa UUID is empty") {
                    mock?.advertisingIdentifierUUIDString = ""

                    let advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
                    expect(advertisingIdentifierHandler.idfa).to(beNil())
                }

                it("should return nil when idfa UUID equals 00000000-0000-0000-0000-000000000000") {
                    mock?.advertisingIdentifierUUIDString = "00000000-0000-0000-0000-000000000000"

                    let advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
                    expect(advertisingIdentifierHandler.idfa).to(beNil())
                }

                it("should return E621E1F8-A36C-495B-93FC-0C247A3E6E5Q when idfa UUID equals E621E1F8-A36C-495B-93FC-0C247A3E6E5Q") {
                    mock?.advertisingIdentifierUUIDString = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"

                    let advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
                    expect(advertisingIdentifierHandler.idfa).to(equal("E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"))
                }
            }
        }
    }
}
