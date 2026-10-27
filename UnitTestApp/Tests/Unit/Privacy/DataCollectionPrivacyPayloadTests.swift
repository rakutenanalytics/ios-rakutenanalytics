import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("DataCollectionConsent payload gating")
struct DataCollectionPrivacyPayloadTests {

    @Suite("when deviceInformation is disabled")
    struct WhenDeviceInformationDisabledTests {
        var helper = PayloadTestHelper.TestHelper()

        mutating func setUpWithDeviceInfoDisabled() {
            helper.setUp()
            let consentMock = DataCollectionConsentStoreMock()
            consentMock.isPrivacyControlEnabled = true
            consentMock.enabledTypes = [.location, .mobileNetwork]
            helper.dependenciesContainer.dataCollectionConsent = consentMock
            helper.dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
                bundle: PayloadTestHelper.bundle,
                deviceCapability: helper.dependenciesContainer.deviceCapability,
                screenHandler: helper.dependenciesContainer.screenHandler,
                telephonyNetworkInfoHandler: helper.dependenciesContainer.telephonyNetworkInfoHandler,
                notificationHandler: helper.dependenciesContainer.notificationHandler,
                analyticsStatusBarOrientationGetter: helper.dependenciesContainer.analyticsStatusBarOrientationGetter,
                reachability: ReachabilityMock(),
                userStorageHandler: helper.dependenciesContainer.userStorageHandler,
                consentStore: consentMock)
            (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = true
            helper.ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
            helper.ratTracker.set(batchingDelay: 0)
            helper.expecter.dependenciesContainer = helper.dependenciesContainer
            helper.expecter.endpointURL = PayloadTestHelper.bundle.endpointAddress
            helper.expecter.databaseTableName = helper.dependenciesContainer.databaseConfiguration?.tableName
            helper.expecter.ratTracker = helper.ratTracker
        }

        @Test("should exclude model from payload")
        mutating func testExcludesModelFromPayload() async throws {
            setUpWithDeviceInfoDisabled()
            defer {
                helper.tearDown()
                (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = false
            }

            let payloads = try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
            let payload = payloads.first
            #expect(payload?[PayloadParameterKeys.model] == nil)
        }

        @Test("should exclude ckp from payload")
        mutating func testExcludesCkpFromPayload() async throws {
            setUpWithDeviceInfoDisabled()
            defer {
                helper.tearDown()
                (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = false
            }

            let payloads = try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
            let payload = payloads.first
            #expect(payload?[PayloadParameterKeys.ckp] == nil)
        }

        @Test("should include ts1 for event ordering")
        mutating func testIncludesTs1ForEventOrdering() async throws {
            setUpWithDeviceInfoDisabled()
            defer {
                helper.tearDown()
                (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = false
            }

            let payloads = try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
            let payload = payloads.first
            #expect(payload?[PayloadParameterKeys.ts1] != nil)
        }

        @Test("should include acc and aid")
        mutating func testIncludesAccAndAid() async throws {
            setUpWithDeviceInfoDisabled()
            defer {
                helper.tearDown()
                (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = false
            }

            let payloads = try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
            let payload = payloads.first
            #expect(payload?[PayloadParameterKeys.acc] != nil)
            #expect(payload?[PayloadParameterKeys.aid] != nil)
        }

        @Test("should set privacy_mode to match consent order L,M,D,U")
        mutating func testPrivacyModeMatchesConsent() async throws {
            setUpWithDeviceInfoDisabled()
            defer {
                helper.tearDown()
                (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = false
            }

            let payloads = try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
            let payload = payloads.first
            #expect(payload?[PayloadParameterKeys.privacyMode] as? String == "1100")
        }
    }

    @Suite("when location is disabled")
    struct WhenLocationDisabledTests {
        var helper = PayloadTestHelper.TestHelper()

        mutating func setUpWithLocationDisabled() {
            helper.setUp()
            let consentMock = DataCollectionConsentStoreMock()
            consentMock.isPrivacyControlEnabled = true
            consentMock.enabledTypes = [.mobileNetwork, .deviceInformation]
            helper.dependenciesContainer.dataCollectionConsent = consentMock
            helper.dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
                bundle: PayloadTestHelper.bundle,
                deviceCapability: helper.dependenciesContainer.deviceCapability,
                screenHandler: helper.dependenciesContainer.screenHandler,
                telephonyNetworkInfoHandler: helper.dependenciesContainer.telephonyNetworkInfoHandler,
                notificationHandler: helper.dependenciesContainer.notificationHandler,
                analyticsStatusBarOrientationGetter: helper.dependenciesContainer.analyticsStatusBarOrientationGetter,
                reachability: ReachabilityMock(),
                userStorageHandler: helper.dependenciesContainer.userStorageHandler,
                consentStore: consentMock)
            (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = true
            helper.ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
            helper.ratTracker.set(batchingDelay: 0)
            helper.expecter.dependenciesContainer = helper.dependenciesContainer
            helper.expecter.endpointURL = PayloadTestHelper.bundle.endpointAddress
            helper.expecter.databaseTableName = helper.dependenciesContainer.databaseConfiguration?.tableName
            helper.expecter.ratTracker = helper.ratTracker
        }

        @Test("should exclude loc from payload when state has location")
        mutating func testExcludesLocFromPayload() async throws {
            setUpWithLocationDisabled()
            defer {
                helper.tearDown()
                (helper.dependenciesContainer.bundle as? BundleMock)?.isPrivacyControlEnabled = false
            }

            let state = Tracking.defaultState
            state.lastKnownLocation = LocationModel.create()

            let payloads = try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent")
            let payload = payloads.first
            #expect(payload?[PayloadParameterKeys.Loc.loc] == nil)
        }
    }
}
