import Quick
import Nimble
@testable import RAnalytics

final class AnalyticsEventIntegrationSpec: QuickSpec {

    override func spec() {
        describe("AnalyticsEventIntegration") {
            let pushEventHandler: PushEventHandler = {
                return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"),
                                        appGroupId: "group.test",
                                        fileManager: FileManager.default,
                                        serializerType: JSONSerialization.self)
            }()

            let analyticsManager = AnalyticsManagerMock()

            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            observer.delegate = analyticsManager

            it("should process the event") {
                AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotification,
                                          parameters: ["rid": "helloworld2021"],
                                          pushEventHandler: pushEventHandler)

                expect(analyticsManager.eventIsProcessed).toEventually(beTrue())
                expect(analyticsManager.processedEvent?.name).to(equal(RAnalyticsEvent.Name.pushNotification))
                expect(analyticsManager.processedEvent?.parameters as? [String: AnyHashable]).to(equal(["rid": "helloworld2021"]))
            }
        }
    }
}
