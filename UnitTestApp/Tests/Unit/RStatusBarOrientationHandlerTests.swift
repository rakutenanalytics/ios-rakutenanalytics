import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RStatusBarOrientationHandler")
struct RStatusBarOrientationHandlerTests {
    @Suite("mori")
    struct MoriTests {
        @Suite("executed on the Main Thread")
        struct ExecutedOnMainThreadTests {
            @Test("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .portrait")
            func testShouldEqualPortraitWhenStatusBarOrientationIsPortrait() {
                #expect(RStatusBarOrientationHandler(application: ApplicationMock(.portrait)).mori == .portrait)
            }
            
            @Test("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .portraitUpsideDown")
            func testShouldEqualPortraitWhenStatusBarOrientationIsPortraitUpsideDown() {
                #expect(RStatusBarOrientationHandler(application: ApplicationMock(.portraitUpsideDown)).mori == .portrait)
            }
            
            @Test("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals .landscapeLeft")
            func testShouldEqualLandscapeWhenStatusBarOrientationIsLandscapeLeft() {
                #expect(RStatusBarOrientationHandler(application: ApplicationMock(.landscapeLeft)).mori == .landscape)
            }
            
            @Test("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals .landscapeRight")
            func testShouldEqualLandscapeWhenStatusBarOrientationIsLandscapeRight() {
                #expect(RStatusBarOrientationHandler(application: ApplicationMock(.landscapeRight)).mori == .landscape)
            }
            
            @Test("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .unknown")
            func testShouldEqualPortraitWhenStatusBarOrientationIsUnknown() {
                #expect(RStatusBarOrientationHandler(application: ApplicationMock(.unknown)).mori == .portrait)
            }
            
            @Test("should equal RMoriType.portrait if UIApplication.shared is not available")
            func testShouldEqualPortraitWhenApplicationIsNil() {
                #expect(RStatusBarOrientationHandler(application: nil).mori == .portrait)
            }

            @Test("should use the application that becomes available after SDK initialization")
            func testShouldUseApplicationThatBecomesAvailableAfterSDKInitialization() {
                var application: StatusBarOrientationGettable?
                let provider = RAnalyticsApplicationOrientationProvider { application }
                let handler = RStatusBarOrientationHandler(application: provider)

                #expect(handler.mori == .portrait)

                application = ApplicationMock(.landscapeLeft)
                #expect(handler.mori == .landscape)
            }
        }
        
        @Suite("executed on other Thread")
        struct ExecutedOnOtherThreadTests {
            @Test("should equal RMoriType.portrait if UIApplication.shared.statusBarOrientation equals .portrait")
            func testShouldEqualPortraitWhenStatusBarOrientationIsPortrait() {
                let queue = DispatchQueue(label: "com.analytics.status-bar-orientation-handler-spec.queue", qos: .default)
                var result: RMoriType = .landscape
                
                queue.sync {
                    result = RStatusBarOrientationHandler(application: ApplicationMock(.portrait)).mori
                }
                
                #expect(result == .portrait)
            }
            
            @Test("should equal RMoriType.landscape if UIApplication.shared.statusBarOrientation equals .landscape")
            func testShouldEqualLandscapeWhenStatusBarOrientationIsLandscape() {
                let queue = DispatchQueue(label: "com.analytics.status-bar-orientation-handler-spec.queue", qos: .default)
                var result: RMoriType = .portrait
                
                queue.sync {
                    result = RStatusBarOrientationHandler(application: ApplicationMock(.landscapeLeft)).mori
                }
                
                #expect(result == .landscape)
            }
        }
    }
}
