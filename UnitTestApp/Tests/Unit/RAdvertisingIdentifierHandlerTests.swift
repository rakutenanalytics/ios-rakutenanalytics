import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAdvertisingIdentifierHandlerTests

@Suite("RAdvertisingIdentifierHandler")
struct RAdvertisingIdentifierHandlerTests {
    @Suite("idfa")
    struct IdfaTests {
        @MainActor
        @Test("should return nil when idfa UUID is empty")
        func testReturnsNilWhenIdfaUUIDIsEmpty() {
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.adIdentifierManager = ASIdentifierManagerMock()
            let mock = (dependenciesContainer.adIdentifierManager as? ASIdentifierManagerMock)
            mock?.advertisingIdentifierUUIDString = ""

            let advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
            #expect(advertisingIdentifierHandler.idfa == nil)
        }

        @MainActor
        @Test("should return nil when idfa UUID equals 00000000-0000-0000-0000-000000000000")
        func testReturnsNilWhenIdfaUUIDEqualsZeroUUID() {
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.adIdentifierManager = ASIdentifierManagerMock()
            let mock = (dependenciesContainer.adIdentifierManager as? ASIdentifierManagerMock)
            mock?.advertisingIdentifierUUIDString = "00000000-0000-0000-0000-000000000000"

            let advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
            #expect(advertisingIdentifierHandler.idfa == nil)
        }

        @MainActor
        @Test("should return E621E1F8-A36C-495B-93FC-0C247A3E6E5Q when idfa UUID equals E621E1F8-A36C-495B-93FC-0C247A3E6E5Q")
        func testReturnsExpectedIdfaWhenIdfaUUIDEqualsExpectedValue() {
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.adIdentifierManager = ASIdentifierManagerMock()
            let mock = (dependenciesContainer.adIdentifierManager as? ASIdentifierManagerMock)
            mock?.advertisingIdentifierUUIDString = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"

            let advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
            #expect(advertisingIdentifierHandler.idfa == "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q")
        }
    }
}
