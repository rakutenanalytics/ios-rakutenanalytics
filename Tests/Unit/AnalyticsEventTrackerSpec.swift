import Quick
import Nimble
@testable import RAnalytics

final class AnalyticsEventTrackerSpec: QuickSpec {

    override func spec() {
        describe("AnalyticsEventTracker") {
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotification,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "bonjour1998"]]]
            var fileURL: URL!
            let fileManagerMock = FileManagerMock()
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId,
                                        fileManager: fileManagerMock,
                                        serializerType: JSONSerializationMock.self)
            }()
            var tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
            let delegate = AnalyticsManagerMock()
            tracker.delegate = delegate

            beforeEach {
                fileManagerMock.mockedContainerURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                fileManagerMock.fileExists = true
                fileURL = fileManagerMock.mockedContainerURL?
                    .appendingPathComponent(PushEventHandlerKeys.openCountCachedEventsFileName)
                FileManager.default.createSafeFile(at: fileURL)
            }

            afterEach {
                fileManagerMock.mockedContainerURL = nil
                JSONSerializationMock.mockedJsonObject = [[String: Any]]()
                try? FileManager.default.removeItem(at: fileURL)
                delegate.eventIsProcessed = false
            }

            context("When there is no event in the cache") {
                it("should not track an event") {
                    JSONSerializationMock.mockedJsonObject = []
                    pushEventHandler.save(events: eventsToCache, completion: { _ in
                        tracker.track()
                    })

                    expect(delegate.eventIsProcessed).toAfterTimeout(beFalse())
                }
            }

            context("When there is an event in the cache") {
                it("should track an event") {
                    JSONSerializationMock.mockedJsonObject = eventsToCache
                    pushEventHandler.save(events: eventsToCache, completion: { _ in
                        tracker.track()
                    })

                    expect(delegate.eventIsProcessed).toEventually(beTrue())
                    expect(delegate.processedEvent?.parameters as? [String: AnyHashable]).to(equal(["rid": "bonjour1998"]))
                }
            }
        }
    }
}
