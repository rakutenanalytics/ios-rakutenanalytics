import Foundation
@testable import RAnalytics

extension RAnalyticsCookieInjector {
    static func create() -> RAnalyticsCookieInjector? {
        RAnalyticsCookieInjector(dependenciesContainer: SimpleDependenciesContainer())
    }
}
