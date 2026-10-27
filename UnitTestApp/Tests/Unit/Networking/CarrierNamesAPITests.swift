import Testing
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("Carrier Names API")
struct CarrierNamesAPITests {
    let analyticsManager = AnalyticsManager.shared()

    mutating func tearDown() {
        analyticsManager.clearCarrierNames()
    }

    @Suite("setCarrierNames and getCarrierNames")
    struct SetCarrierNamesAndGetCarrierNamesTests {
        let analyticsManager = AnalyticsManager.shared()

        mutating func tearDown() {
            analyticsManager.clearCarrierNames()
        }

        @Test("should set and get primary carrier name only")
        mutating func testSetsAndGetsPrimaryCarrierNameOnly() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Rakuten Mobile")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "Rakuten Mobile")
            #expect(carrierNames.secondary == nil)
        }

        @Test("should set and get secondary carrier name only")
        mutating func testSetsAndGetsSecondaryCarrierNameOnly() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: nil, secondary: "NTT Docomo")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == "NTT Docomo")
        }

        @Test("should set and get both carrier names")
        mutating func testSetsAndGetsBothCarrierNames() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "SoftBank", secondary: "au")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "SoftBank")
            #expect(carrierNames.secondary == "au")
        }

        @Test("should handle empty strings")
        mutating func testHandlesEmptyStrings() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "", secondary: "")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "")
            #expect(carrierNames.secondary == "")
        }

        @Test("should update existing carrier names")
        mutating func testUpdatesExistingCarrierNames() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Initial Primary", secondary: "Initial Secondary")
            analyticsManager.setCarrierNames(primary: "Updated Primary", secondary: "Updated Secondary")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "Updated Primary")
            #expect(carrierNames.secondary == "Updated Secondary")
        }
    }

    @Suite("clearCarrierNames")
    struct ClearCarrierNamesTests {
        let analyticsManager = AnalyticsManager.shared()

        mutating func tearDown() {
            analyticsManager.clearCarrierNames()
        }

        @Test("should clear both carrier names when both were set")
        mutating func testClearsBothCarrierNamesWhenBothWereSet() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Test Primary", secondary: "Test Secondary")

            var carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "Test Primary")
            #expect(carrierNames.secondary == "Test Secondary")

            analyticsManager.clearCarrierNames()

            carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == nil)
        }

        @Test("should clear carrier names when only primary was set")
        mutating func testClearsCarrierNamesWhenOnlyPrimaryWasSet() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Only Primary")

            analyticsManager.clearCarrierNames()

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == nil)
        }

        @Test("should clear carrier names when only secondary was set")
        mutating func testClearsCarrierNamesWhenOnlySecondaryWasSet() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: nil, secondary: "Only Secondary")

            analyticsManager.clearCarrierNames()

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == nil)
        }

        @Test("should be safe to call when no carrier names are set")
        mutating func testIsSafeToCallWhenNoCarrierNamesAreSet() {
            defer { tearDown() }
            let initialCarrierNames = analyticsManager.getCarrierNames()
            #expect(initialCarrierNames.primary == nil)
            #expect(initialCarrierNames.secondary == nil)

            analyticsManager.clearCarrierNames()

            let finalCarrierNames = analyticsManager.getCarrierNames()
            #expect(finalCarrierNames.primary == nil)
            #expect(finalCarrierNames.secondary == nil)
        }
    }

    @Suite("API integration")
    struct APIIntegrationTests {
        let analyticsManager = AnalyticsManager.shared()

        mutating func tearDown() {
            analyticsManager.clearCarrierNames()
        }

        @Test("should work with method chaining pattern")
        mutating func testWorksWithMethodChainingPattern() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Chain Primary", secondary: "Chain Secondary")
            let carrierNames1 = analyticsManager.getCarrierNames()

            analyticsManager.clearCarrierNames()
            let carrierNames2 = analyticsManager.getCarrierNames()

            analyticsManager.setCarrierNames(primary: "New Primary")
            let carrierNames3 = analyticsManager.getCarrierNames()

            #expect(carrierNames1.primary == "Chain Primary")
            #expect(carrierNames1.secondary == "Chain Secondary")

            #expect(carrierNames2.primary == nil)
            #expect(carrierNames2.secondary == nil)

            #expect(carrierNames3.primary == "New Primary")
            #expect(carrierNames3.secondary == nil)
        }
    }

    @Suite("data collection API")
    struct DataCollectionAPITests {
        @Test("isDataCollectionEnabled matches DataCollectionConsentStore.shared")
        func testIsDataCollectionEnabledMatchesSharedStore() {
            for type in DataCollectionType.allCases {
                #expect(AnalyticsManager.shared().isDataCollectionEnabled(dataCollection: type) ==
                            DataCollectionConsentStore.shared.isEnabled(type))
            }
        }
    }
}
