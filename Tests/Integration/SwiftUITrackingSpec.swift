import Quick
import Nimble
import Foundation
import ViewInspector
import SwiftUI
@testable import RAnalytics

#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

struct RView: View, Inspectable {
    @available(iOS 13.0.0, *)
    var body: some View {
        rviewOnAppear(pageName: "MyView", with: MainDependenciesContainer.analyticsManager) {
        }
    }
}

final class SwiftUITrackingSpec: QuickSpec {
    override func spec() {
        let view = RView()
        let sessionMock = URLSessionMock.mock(originalInstance: .shared)

        describe("SwiftUITracking") {
            beforeEach {
                URLSessionMock.startMockingURLSession()
                sessionMock.stubResponse(statusCode: 200)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("should track pv event with pgn equal to MyView when the pageName is MyView") {
                if #available(iOS 13.0, *) {
                    var taskIsCompleted = false

                    sessionMock.onCompletedTask = {
                        taskIsCompleted = true
                    }

                    try view.inspect().view(RView.self).callOnAppear()

                    expect(taskIsCompleted).toEventually(beTrue(), timeout: .seconds(5))
                    expect(sessionMock.sentRequest).toEventuallyNot(beNil())

                    let ratPayload = sessionMock.sentRequest?.httpBody?.ratPayload
                    let json = ratPayload?.pageVisitJSON

                    expect(json?[PayloadParameterKeys.pgn] as? String).to(equal("MyView"))

                } else {
                    // Can't test on iOS < iOS 13.0
                    // Don't call `assertionFailure` in order to let the tests run on lower versions of Xcode
                }
            }
        }
    }
}
