import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - UserIdentifierSelectorTests

@Suite("UserIdentifierSelector")
struct UserIdentifierSelectorTests {
    static let notificationName = Notification.Name(rawValue: "com.rakuten.esd.sdk.events.login.other")
    let dependenciesContainer = SimpleContainerMock()
    
    mutating func setUp() {
        dependenciesContainer.userStorageHandler = UserDefaultsMock()
    }
    
    @Suite("selectedTrackingIdentifier")
    struct SelectedTrackingIdentifierTests {
        @Test("should return nil at initialization")
        func testShouldReturnNilAtInitialization() {
            var spec = UserIdentifierSelectorTests()
            spec.setUp()
            
            let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: spec.dependenciesContainer)
            let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
            #expect(userIdentifierSelector.selectedTrackingIdentifier == nil)
        }
        
        @Suite("trackingIdentifier is nil")
        struct TrackingIdentifierIsNilTests {
            @Test("should return userID when userID is set to non-empty value")
            func testShouldReturnUserIDWhenUserIDIsSetToNonEmptyValue() async throws {
                var spec = UserIdentifierSelectorTests()
                spec.setUp()
                
                (spec.dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: spec.dependenciesContainer)
                let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
                
                externalCollector.userIdentifier = "userID"
                NotificationCenter.default.post(name: UserIdentifierSelectorTests.notificationName, object: nil)
                
                try await TestingHelpers.eventually(timeout: 2.0) {
                    userIdentifierSelector.selectedTrackingIdentifier == "userID"
                }
            }
            
            @Test("should return nil when userID is nil")
            func testShouldReturnNilWhenUserIDIsNil() async throws {
                var spec = UserIdentifierSelectorTests()
                spec.setUp()
                
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: spec.dependenciesContainer)
                let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
                
                externalCollector.userIdentifier = nil
                NotificationCenter.default.post(name: UserIdentifierSelectorTests.notificationName, object: nil)
                
                try await TestingHelpers.eventually(timeout: 2.0) {
                    userIdentifierSelector.selectedTrackingIdentifier == nil
                }
            }
        }
        
        @Suite("trackingIdentifier is not nil")
        struct TrackingIdentifierIsNotNilTests {
            @Test("should return userID when userID is set to non-empty value")
            func testShouldReturnUserIDWhenUserIDIsSetToNonEmptyValue() async throws {
                var spec = UserIdentifierSelectorTests()
                spec.setUp()
                
                (spec.dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: spec.dependenciesContainer)
                let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
                
                externalCollector.userIdentifier = "userID"
                NotificationCenter.default.post(name: UserIdentifierSelectorTests.notificationName, object: "trackingID")
                
                try await TestingHelpers.eventually(timeout: 2.0) {
                    userIdentifierSelector.selectedTrackingIdentifier == "userID"
                }
            }
            
            @Test("should return trackingID when userID is nil")
            func testShouldReturnTrackingIDWhenUserIDIsNil() async throws {
                var spec = UserIdentifierSelectorTests()
                spec.setUp()
                
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: spec.dependenciesContainer)
                let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
                
                externalCollector.userIdentifier = nil
                NotificationCenter.default.post(name: UserIdentifierSelectorTests.notificationName, object: "trackingID")
                
                try await TestingHelpers.eventually(timeout: 2.0) {
                    userIdentifierSelector.selectedTrackingIdentifier == "trackingID"
                }
            }
        }
    }
}
