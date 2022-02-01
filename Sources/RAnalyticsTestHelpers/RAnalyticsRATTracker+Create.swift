import Foundation
@testable import RAnalytics

@objc public extension RAnalyticsRATTracker {
    static func create() -> RAnalyticsRATTracker {
        RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
    }
}
