import Quick
import Nimble
@testable import RAnalytics

final class AnalyticsEventObserverSpec: QuickSpec {

    override func spec() {
        describe("AnalyticsEventObserver") {
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotification,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]
            var fileURL: URL!
            let fileManagerMock = FileManagerMock()
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.AppGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId,
                                        fileManager: fileManagerMock,
                                        serializerType: JSONSerializationMock.self)
            }()
            let delegate = AnalyticsManagerMock()
            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            observer.delegate = delegate

            beforeEach {
                fileManagerMock.mockedContainerURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                fileManagerMock.fileExists = true
                fileURL = fileManagerMock.mockedContainerURL?
                    .appendingPathComponent(PushEventHandlerKeys.OpenCountCachedEventsFileName)
                FileManager.default.createSafeFile(at: fileURL)
            }

            afterEach {
                fileManagerMock.mockedContainerURL = nil
                JSONSerializationMock.mockedJsonObject = [[String: Any]]()
                try? FileManager.default.removeItem(at: fileURL)
                delegate.eventIsProcessed = false
            }

            context("When a Darwin Notification is observed") {
                it("should process a cached event") {
                    JSONSerializationMock.mockedJsonObject = eventsToCache
                    pushEventHandler.save(events: eventsToCache, completion: { _ in
                        DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)
                    })

                    expect(delegate.eventIsProcessed).toEventually(beTrue())
                    expect(delegate.processedEvent?.name).to(equal(RAnalyticsEvent.Name.pushNotification))
                    expect(delegate.processedEvent?.parameters as? [String: AnyHashable]).to(equal(["rid": "abcd1234"]))
                }
            }
        }
    }
}
