import Foundation
@testable import RakutenAnalytics

extension RAnalyticsCookieInjector {
    static func create() -> RAnalyticsCookieInjector? {
        RAnalyticsCookieInjector(dependenciesContainer: SimpleDependenciesContainer())
    }
}
