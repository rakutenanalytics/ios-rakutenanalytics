import Quick
import Nimble
import UIKit

private final class ApplicationMock: AnalyticsStatusBarOrientationGettable {
    private let injectedValue: UIInterfaceOrientation
    init(_ injectedValue: UIInterfaceOrientation) {
        self.injectedValue = injectedValue
    }

    var analyticsStatusBarOrientation: UIInterfaceOrientation {
        injectedValue
    }
}

final class RStatusBarOrientationHandlerSpec: QuickSpec {
    override func spec() {
        describe("RStatusBarOrientationHandler") {
            describe("mori") {
                it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals UIInterfaceOrientation.portrait") {
                    expect(RStatusBarOrientationHandler(application: ApplicationMock(.portrait)).mori).to(equal(.portrait))
                }
                it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals UIInterfaceOrientation.portraitUpsideDown") {
                    expect(RStatusBarOrientationHandler(application: ApplicationMock(.portraitUpsideDown)).mori).to(equal(.portrait))
                }
                it("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals UIInterfaceOrientation.landscapeLeft") {
                    expect(RStatusBarOrientationHandler(application: ApplicationMock(.landscapeLeft)).mori).to(equal(.landscape))
                }
                it("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals UIInterfaceOrientation.landscapeRight") {
                    expect(RStatusBarOrientationHandler(application: ApplicationMock(.landscapeRight)).mori).to(equal(.landscape))
                }
                it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals UIInterfaceOrientation.unknown") {
                    expect(RStatusBarOrientationHandler(application: ApplicationMock(.unknown)).mori).to(equal(.portrait))
                }
                it("should equal RMoriType.portrait if UIApplication.shared is not available") {
                    expect(RStatusBarOrientationHandler(application: nil).mori).to(equal(.portrait))
                }
            }
        }
    }
}
