import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class PushEventHandlerSpec: QuickSpec {

    override func spec() {
        describe("PushEventHandler") {
            let sentTrackingId = "a_good_tracking_id"
            let appGroupDictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "appGroupId"]
            let openCountDictionary = [PushEventHandlerKeys.openCountSentUserDefaultKey: [sentTrackingId: true]]
            let bundleMock = BundleMock()
            bundleMock.dictionary = [:]
            bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
            let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
            sharedUserDefaults?.dictionary = [:]
            let fileManagerMock = FileManagerMock()
            var fileURL: URL!
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotification,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]
            let expectedError = NSError(domain: "domain", code: 456, userInfo: nil)

            afterEach {
                JSONSerializationMock.error = nil
                fileManagerMock.fileExists = true
            }

            context("App Group User Defaults") {
                describe("isEventAlreadySent") {
                    context("RRPushAppGroupIdentifierPlistKey is not set in the main bundle") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId),
                                                                appGroupId: bundleMock.appGroupId,
                                                                fileManager: FileManager.default,
                                                                serializerType: JSONSerialization.self)

                        it("should return false when trackingIdentifier is not nil") {
                            expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                        }

                        it("should return false when trackingIdentifier is nil") {
                            expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                        }
                    }

                    context("RRPushAppGroupIdentifierPlistKey is set in the main bundle") {
                        let bundleMock: BundleMock = {
                            let bundleMock = BundleMock()
                            bundleMock.dictionary = appGroupDictionary
                            return bundleMock
                        }()

                        context("valid open count dictionary") {
                            let pushEventHandler: PushEventHandler = {
                                let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId),
                                                                        appGroupId: bundleMock.appGroupId,
                                                                        fileManager: FileManager.default,
                                                                        serializerType: JSONSerialization.self)
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = openCountDictionary
                                return pushEventHandler
                            }()

                            it("should return true when trackingIdentifier is not nil") {
                                expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beTrue())
                            }

                            it("should return false when trackingIdentifier is nil") {
                                expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                            }
                        }

                        context("invalid open count dictionary") {
                            let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId),
                                                                    appGroupId: bundleMock.appGroupId,
                                                                    fileManager: FileManager.default,
                                                                    serializerType: JSONSerialization.self)

                            it("should return false when trackingIdentifier is not nil and open count dictionary is empty") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                                expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                            }

                            it("should return false when trackingIdentifier is not nil and open count dictionary is nil") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                                expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                            }

                            it("should return false when trackingIdentifier is nil and open count dictionary is empty") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                                expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                            }

                            it("should return false when trackingIdentifier is nil and open count dictionary is nil") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                                expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                            }
                        }
                    }
                }

                describe("cacheEvent(for:)") {
                    context("The shared app group user defaults is nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: nil,
                                                                appGroupId: nil,
                                                                fileManager: FileManager.default,
                                                                serializerType: JSONSerialization.self)

                        it("should not cache the event tracking identifier") {
                            expect(pushEventHandler.cacheEvent(for: sentTrackingId)).to(beFalse())
                        }
                    }

                    context("The shared app group user defaults is not nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                                                appGroupId: bundleMock.appGroupId,
                                                                fileManager: FileManager.default,
                                                                serializerType: JSONSerialization.self)

                        it("should cache the event tracking identifier") {
                            expect(pushEventHandler.cacheEvent(for: sentTrackingId)).to(beTrue())
                        }

                        it("should set the tracking identifier caching status to true") {
                            let openSentMap = sharedUserDefaults?.object(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey) as? [String: Bool]
                            expect(openSentMap?[sentTrackingId]).to(beTrue())
                        }
                    }
                }

                describe("clearCache()") {
                    context("The shared app group user defaults is nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: nil,
                                                                appGroupId: nil,
                                                                fileManager: FileManager.default,
                                                                serializerType: JSONSerialization.self)

                        it("should return false") {
                            expect(pushEventHandler.clearCache()).to(beFalse())
                        }
                    }

                    context("The shared app group user defaults is not nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                                                appGroupId: bundleMock.appGroupId,
                                                                fileManager: FileManager.default,
                                                                serializerType: JSONSerialization.self)

                        it("should set the cache to nil") {
                            pushEventHandler.cacheEvent(for: sentTrackingId)
                            pushEventHandler.clearCache()

                            expect(sharedUserDefaults?.object(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey)).to(beNil())
                        }

                        it("should return true") {
                            expect(pushEventHandler.clearCache()).to(beTrue())
                        }
                    }
                }
            }

            context("App Group File Cache") {
                let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                                        appGroupId: bundleMock.appGroupId,
                                                        fileManager: fileManagerMock,
                                                        serializerType: JSONSerializationMock.self)

                beforeEach {
                    fileManagerMock.mockedContainerURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                    fileURL = fileManagerMock.mockedContainerURL?
                        .appendingPathComponent(PushEventHandlerKeys.openCountCachedEventsFileName)
                    FileManager.default.createSafeFile(at: fileURL)
                }

                afterEach {
                    fileManagerMock.mockedContainerURL = nil
                    JSONSerializationMock.mockedJsonObject = [[String: Any]]()
                    try? FileManager.default.removeItem(at: fileURL)
                }

                describe("cachedEvents(completion:)") {
                    context("When the cached events file container URL is nil") {
                        it("should return an error") {
                            fileManagerMock.mockedContainerURL = nil

                            var error: PushEventError?

                            pushEventHandler.cachedEvents { result in
                                if case .failure(let anError) = result {
                                    error = anError
                                }
                            }

                            expect(error).toNotEventually(beNil())
                            expect(error).to(equal(.fileUrlIsNil))
                        }
                    }

                    context("When the cached events file container does not exist") {
                        it("should return an error") {
                            fileManagerMock.fileExists = false

                            var error: PushEventError?

                            pushEventHandler.cachedEvents { result in
                                if case .failure(let anError) = result {
                                    error = anError
                                }
                            }

                            expect(error).toNotEventually(beNil())
                            expect(error).to(equal(.fileUrlIsNil))
                        }
                    }

                    context("When the parsing fails") {
                        it("should return an error") {
                            JSONSerializationMock.error = expectedError

                            var error: PushEventError?

                            pushEventHandler.cachedEvents { result in
                                if case .failure(let anError) = result {
                                    error = anError
                                }
                            }

                            expect(error).toNotEventually(beNil())
                            expect(error).to(equal(PushEventError.nativeError(error: expectedError)))
                        }
                    }

                    context("When the cached events file container exists") {
                        context("When the cached events file does not exist") {
                            it("should return an error") {
                                var error: Error?

                                try? FileManager.default.removeItem(at: fileURL)

                                pushEventHandler.cachedEvents { result in
                                    if case .failure(let anError) = result {
                                        switch anError {
                                        case .nativeError(error: let nativeError):
                                            error = nativeError
                                        default: ()
                                        }
                                    }
                                }

                                expect(error).toNotEventually(beNil())
                            }
                        }

                        context("When the cached events file exists") {
                            var fileURL: URL!

                            beforeEach {
                                fileURL = fileManagerMock.mockedContainerURL?
                                    .appendingPathComponent(PushEventHandlerKeys.openCountCachedEventsFileName)
                                FileManager.default.createSafeFile(at: fileURL)
                            }

                            afterEach {
                                try? FileManager.default.removeItem(at: fileURL)
                            }

                            context("When the cached events array is empty") {
                                it("should return an empty cached events") {
                                    let expectedEvents = [[String: Any]]()

                                    JSONSerializationMock.mockedJsonObject = expectedEvents

                                    var cachedEvents: [[String: Any]] = [[String: Any]]()

                                    pushEventHandler.cachedEvents { result in
                                        if case .success(let events) = result {
                                            cachedEvents = events
                                        }
                                    }

                                    expect(cachedEvents).toNotEventually(beNil())
                                    expect(cachedEvents.isEmpty).toEventually(beTrue())
                                }
                            }

                            context("When the cached events array is not empty") {
                                it("should return an empty cached events when the cache is incorrect") {
                                    let expectedEvents = [[String: Any]]()

                                    let incorrectCache = ["item1", "item2"]

                                    JSONSerializationMock.mockedJsonObject = incorrectCache

                                    var cachedEvents: [[String: Any]] = [[String: Any]]()

                                    pushEventHandler.cachedEvents { result in
                                        if case .success(let events) = result {
                                            cachedEvents = events
                                        }
                                    }

                                    expect(cachedEvents).toNotEventually(beNil())
                                    expect(cachedEvents as? [[String: AnyHashable]]).to(equal(expectedEvents as? [[String: AnyHashable]]))
                                }

                                it("should return the cached events when the cache is correct") {
                                    let expectedEvents = eventsToCache

                                    JSONSerializationMock.mockedJsonObject = expectedEvents

                                    var cachedEvents: [[String: Any]] = [[String: Any]]()

                                    pushEventHandler.cachedEvents { result in
                                        if case .success(let events) = result {
                                            cachedEvents = events
                                        }
                                    }

                                    expect(cachedEvents).toNotEventually(beNil())
                                    expect(cachedEvents as? [[String: AnyHashable]]).to(equal(expectedEvents as? [[String: AnyHashable]]))
                                }
                            }
                        }
                    }
                }

                describe("save(events:)") {
                    context("When the cached events file container does not exist") {
                        it("should return an error") {
                            fileManagerMock.mockedContainerURL = nil

                            var error: PushEventError?

                            pushEventHandler.save(events: eventsToCache, completion: { anError in
                                error = anError
                            })

                            expect(error).toNotEventually(beNil())
                            expect(error).to(equal(.fileUrlIsNil))
                        }
                    }

                    context("When the cached events file container exists") {
                        context("When the cached events file does not exist") {
                            it("should return an error") {
                                try? FileManager.default.removeItem(at: fileURL)

                                // Note: write(to:) does not fail when the file does not exist
                                fileManagerMock.fileExists = false

                                let mockedData: Data! = try? JSONSerialization.data(withJSONObject: eventsToCache, options: .fragmentsAllowed)

                                JSONSerializationMock.mockedData = mockedData

                                var error: PushEventError?

                                pushEventHandler.save(events: eventsToCache, completion: { anError in
                                    error = anError
                                })

                                expect(error).toNotEventually(beNil())
                                expect(error).to(equal(.fileDoesNotExist))
                            }
                        }

                        context("When the cached events file exists") {
                            context("When the cached events array is empty") {
                                it("should save an empty array") {
                                    let expectedEvents = [[String: Any]]()

                                    JSONSerializationMock.mockedJsonObject = expectedEvents

                                    var success = false

                                    pushEventHandler.save(events: eventsToCache, completion: { anError in
                                        success = anError == nil
                                    })

                                    expect(success).toEventually(beTrue())
                                }
                            }

                            context("When the cached events array is not empty") {
                                it("should save a not empty array") {
                                    let expectedEvents = eventsToCache

                                    JSONSerializationMock.mockedJsonObject = expectedEvents

                                    var success = false

                                    pushEventHandler.save(events: eventsToCache, completion: { anError in
                                        success = anError == nil
                                    })

                                    expect(success).toEventually(beTrue())
                                }
                            }

                            context("When the parsing fails") {
                                it("should not save") {
                                    JSONSerializationMock.error = expectedError

                                    var error: PushEventError?

                                    pushEventHandler.save(events: eventsToCache, completion: { anError in
                                        error = anError
                                    })

                                    expect(error).toEventuallyNot(beNil())
                                    expect(error).to(equal(PushEventError.nativeError(error: expectedError)))
                                }
                            }
                        }
                    }
                }

                describe("clearEventsCache()") {
                    context("When the cached events file container does not exist") {
                        it("should return an error") {
                            fileManagerMock.mockedContainerURL = nil

                            var error: PushEventError?

                            pushEventHandler.clearEventsCache { anError in
                                error = anError
                            }

                            expect(error).toNotEventually(beNil())
                            expect(error).to(equal(.fileUrlIsNil))
                        }
                    }

                    context("When the cached events file container exists") {
                        context("When the cached events file does not exist") {
                            it("should return an error") {
                                try? FileManager.default.removeItem(at: fileURL)

                                // Note: removeItem(at:) does not fail when the file does not exist
                                fileManagerMock.fileExists = false

                                var error: PushEventError?

                                pushEventHandler.clearEventsCache { anError in
                                    error = anError
                                }

                                expect(error).toNotEventually(beNil())
                                expect(error).to(equal(.fileDoesNotExist))
                            }
                        }

                        context("When the cached events file exists") {
                            it("should clear the cache") {
                                var success = false

                                pushEventHandler.clearEventsCache { anError in
                                    success = anError == nil
                                }

                                expect(success).toEventually(beTrue())
                            }
                        }
                    }
                }
            }
        }
    }
}
