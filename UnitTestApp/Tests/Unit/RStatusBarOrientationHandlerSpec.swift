import Quick
import Nimble
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class RStatusBarOrientationHandlerSpec: QuickSpec {
    override class func spec() {
        describe("RStatusBarOrientationHandler") {
            describe("mori") {
                context("executed on the Main Thread") {
                    it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .portrait") {
                        expect(RStatusBarOrientationHandler(application: ApplicationMock(.portrait)).mori).to(equal(.portrait))
                    }
                    it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .portraitUpsideDown") {
                        expect(RStatusBarOrientationHandler(application: ApplicationMock(.portraitUpsideDown)).mori).to(equal(.portrait))
                    }
                    it("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals .landscapeLeft") {
                        expect(RStatusBarOrientationHandler(application: ApplicationMock(.landscapeLeft)).mori).to(equal(.landscape))
                    }
                    it("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals .landscapeRight") {
                        expect(RStatusBarOrientationHandler(application: ApplicationMock(.landscapeRight)).mori).to(equal(.landscape))
                    }
                    it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .unknown") {
                        expect(RStatusBarOrientationHandler(application: ApplicationMock(.unknown)).mori).to(equal(.portrait))
                    }
                    it("should equal RMoriType.portrait if UIApplication.shared is not available") {
                        expect(RStatusBarOrientationHandler(application: nil).mori).to(equal(.portrait))
                    }
                }
                context("executed on other Thread") {
                    it("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .portrait") {
                        let queue = DispatchQueue(label: "com.analytics.status-bar-orientation-handler-spec.queue", qos: .default)
                        var result: RMoriType = .landscape
                        
                        queue.sync {
                            result = RStatusBarOrientationHandler(application: ApplicationMock(.portrait)).mori
                        }
                        
                        expect(result).to(equal(.portrait))
                    }
                    
                    it("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals .landscape") {
                        let queue = DispatchQueue(label: "com.analytics.status-bar-orientation-handler-spec.queue", qos: .default)
                        var result: RMoriType = .portrait
                        
                        queue.sync {
                            result = RStatusBarOrientationHandler(application: ApplicationMock(.landscapeLeft)).mori
                        }
                        
                        expect(result).to(equal(.landscape))
                    }
                }

            }
        }
    }
}
