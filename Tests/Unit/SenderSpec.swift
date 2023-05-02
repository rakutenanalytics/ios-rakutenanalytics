import Quick
import Nimble
import Foundation
import UIKit
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class SenderSpec: QuickSpec {

    override func spec() {

        describe("RAnalyticsSender") {
            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            let databaseTableName = "testTableName"
            let payload = ["key": "value"]
            let bundle = BundleMock()
            var userDefaultsMock: UserDefaultsMock!

            var sender: RAnalyticsSender!
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!

            beforeEach {
                URLSessionMock.startMockingURLSession()
                // Create in-memory DB
                databaseConnection = DatabaseTestUtils.openRegularConnection()
                database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
                userDefaultsMock = UserDefaultsMock([:])

                sender = RAnalyticsSender(endpoint: URL(string: "https://endpoint.co.jp/")!,
                                          database: database,
                                          databaseTable: databaseTableName,
                                          bundle: bundle,
                                          session: URLSession.shared,
                                          userStorageHandler: userDefaultsMock)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()

                sender.setBatchingDelayBlock(0)

                sender.uploadTimer?.invalidate()

                DatabaseTestUtils.deleteTableIfExists(databaseTableName, connection: databaseConnection)
                database.closeConnection()
                databaseConnection = nil
                database = nil
                bundle.mutableEnableInternalSerialization = false
            }

            context("initialization") {
                it("should set enableBackgroundTimerUpdate to false") {
                    var isNone = false

                    if case .none = sender.backgroundTimerEnabler {
                        isNone = true
                    }

                    expect(isNone).to(beTrue())
                }
            }

            context("JSON serialization") {
                it("should send given payload when enableInternalSerialization is false") {
                    var isSendingCompleted = false
                    sessionMock.stubResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    bundle.mutableEnableInternalSerialization = false
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())
                }

                it("should send given payload when enableInternalSerialization is true") {
                    var isSendingCompleted = false
                    sessionMock.stubResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    bundle.mutableEnableInternalSerialization = true
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())
                }
            }

            describe("enableBackgroundTimerUpdate") {
                let geoScheduleStartTimeKey = "RATGeoScheduleStartTime"
                var isSendingCompleted = false

                beforeEach {
                    sender = RAnalyticsSender(endpoint: URL(string: "https://endpoint.co.jp/")!,
                                              database: database,
                                              databaseTable: databaseTableName,
                                              bundle: bundle,
                                              session: URLSession.shared,
                                              maxUploadInterval: 900.0,
                                              userStorageHandler: userDefaultsMock)
                }

                context("When setting enableBackgroundTimerUpdate to false") {
                    beforeEach {
                        sender.backgroundTimerEnabler = .none
                        isSendingCompleted = false
                    }

                    context("When the batching delay is set to 0") {
                        beforeEach {
                            sender.setBatchingDelayBlock(0.0)
                        }

                        context("When not sending data") {
                            it("should not set the start date") {
                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).to(equal(0.0))
                            }
                        }

                        context("When sending data") {
                            beforeEach {
                                sessionMock.stubResponse(statusCode: 200) {
                                    isSendingCompleted = true
                                }
                                sender.send(jsonObject: payload)
                            }

                            it("should not set the start date") {
                                expect(isSendingCompleted).toEventually(beTrue())

                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).to(equal(0.0))
                            }
                        }
                    }

                    context("When the batching delay is set to 900.0") {
                        beforeEach {
                            sender.setBatchingDelayBlock(900.0)
                        }

                        context("When not sending data") {
                            it("should not set the start date") {
                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).to(equal(0.0))
                            }
                        }

                        context("When sending data") {
                            beforeEach {
                                sender.send(jsonObject: payload)
                            }

                            it("should not set the start date") {
                                let getDBContent = { DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection) }
                                expect(getDBContent()).toAfterTimeout(haveCount(1), timeout: 2.0)

                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).to(equal(0.0))
                            }
                        }
                    }
                }

                context("When setting enableBackgroundTimerUpdate to true") {
                    beforeEach {
                        sender.backgroundTimerEnabler = .enabled(startTimeKey: geoScheduleStartTimeKey)
                    }

                    context("When the batching delay is set to 0") {
                        beforeEach {
                            sender.setBatchingDelayBlock(0.0)
                        }

                        context("When not sending data") {
                            it("should not set the start date") {
                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).to(equal(0.0))
                            }
                        }

                        context("When sending data") {
                            beforeEach {
                                sessionMock.stubResponse(statusCode: 200) {
                                    isSendingCompleted = true
                                }
                                sender.send(jsonObject: payload)
                            }

                            it("should not set the start date") {
                                expect(isSendingCompleted).toEventually(beTrue())

                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).toNot(equal(0.0))
                            }
                        }
                    }

                    context("When the batching delay is set to 900.0") {
                        beforeEach {
                            sender.setBatchingDelayBlock(900.0)
                        }

                        context("When not sending data") {
                            it("should not set the start date") {
                                expect(userDefaultsMock.double(forKey: geoScheduleStartTimeKey)).to(equal(0.0))
                            }
                        }

                        context("When sending data") {
                            beforeEach {
                                sender.send(jsonObject: payload)
                            }

                            it("should set the schedule start date") {
                                let getDBContent = { DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection) }
                                expect(getDBContent()).toAfterTimeout(haveCount(1), timeout: 2.0)

                                let starteDateTime = userDefaultsMock.double(forKey: geoScheduleStartTimeKey)

                                expect(starteDateTime).to(beGreaterThan(0.0))
                            }

                            context("Then the app goes to foreground") {
                                it("should set an updated uploadTimerInterval") {
                                    let getDBContent = { DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection) }
                                    expect(getDBContent()).toAfterTimeout(haveCount(1), timeout: 2.0)

                                    let scheduleElapsedTime = userDefaultsMock.double(forKey: geoScheduleStartTimeKey)

                                    expect(scheduleElapsedTime).to(beGreaterThan(0.0))

                                    sleep(3)

                                    sender.appDidBecomeActive()

                                    let elapsedTime = Date().timeIntervalSince1970 - scheduleElapsedTime

                                    expect(ceil(sender.uploadTimerInterval)).to(beLessThanOrEqualTo(ceil(900.0 - elapsedTime)))
                                }
                            }
                        }
                    }
                }
            }

            context("when setting batching delay") {

                it("should succeed with default batching delay", closure: {
                    sessionMock.stubResponse(statusCode: 200)

                    sender.send(jsonObject: payload)
                    expect(sender.uploadTimerInterval).toEventually(equal(0))
                })

                it("should succeed with custom batching delay") {
                    sessionMock.stubResponse(statusCode: 200)

                    sender.setBatchingDelayBlock(15.0)
                    sender.send(jsonObject: payload)
                    expect(sender.uploadTimerInterval).toEventually(equal(15.0))
                }
            }

            context("when sending events to RAT") {

                it("should send given payload") {
                    var isSendingCompleted = false
                    sessionMock.stubResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())
                }

                context("When sending fails") {
                    context("When the batching delay is > 0") {
                        it("should send RAnalyticsUploadFailure notification") {
                            sender.setBatchingDelayBlock(0.1)
                            verifyRAnalyticsUploadFailure()
                        }
                    }

                    context("When the batching delay is 0") {
                        it("should send RAnalyticsUploadFailure notification") {
                            sender.setBatchingDelayBlock(0)
                            verifyRAnalyticsUploadFailure()
                        }
                    }

                    func verifyRAnalyticsUploadFailure() {
                        var isSendingCompleted = false
                        sessionMock.stubResponse(statusCode: 500) {
                            isSendingCompleted = true
                        }

                        var didReceiveNotification = false
                        let queue = OperationQueue()
                        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.RAnalyticsUploadFailure,
                                                                              object: nil,
                                                                              queue: queue) { (notification) in
                            let error = notification.userInfo?[NSUnderlyingErrorKey] as? Error
                            expect(error).toNot(beNil())
                            expect(error?.localizedDescription).to(equal("invalid_response"))
                            didReceiveNotification = true
                        }

                        sender.send(jsonObject: payload)
                        expect(isSendingCompleted).toEventually(beTrue())
                        expect(didReceiveNotification).toEventually(beTrue())

                        NotificationCenter.default.removeObserver(observer)
                    }
                }

                it("should remove DB record after event is sent", closure: {
                    var isSendingCompleted = false
                    sessionMock.stubResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())

                    let dbContent = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
                    expect(dbContent).toAfterTimeout(beEmpty())
                })

                it("should not remove DB record before event is sent", closure: {
                    sessionMock.stubResponse(statusCode: 200)
                    sender.setBatchingDelayBlock(30.0)
                    sender.send(jsonObject: payload)

                    let getDBContent = { DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection) }
                    expect(getDBContent()).toAfterTimeout(haveCount(1), timeout: 2.0)
                })

                // This test is temporarily disabled.
                // It should be fixed in this ticket:
                // https://jira.rakuten-it.com/jira/browse/SDKCF-5304
                //                it("should not send duplicate events when app becomes active") {
                //                    var isSendingCompleted = false
                //                    sessionMock.stubResponse(statusCode: 200) {
                //                        isSendingCompleted = true
                //                    }
                //
                //                    var uploadsToRat = 0
                //                    let queue = OperationQueue()
                //                    let uploadObserver = NotificationCenter.default.addObserver(forName: Notification.Name.RAnalyticsUploadSuccess,
                //                                                                                object: nil,
                //                                                                                queue: queue) { (notification) in
                //                        if (notification.object as? [Any])?.first as? [String: String] == payload {
                //                            uploadsToRat += 1
                //                        }
                //                    }
                //
                //                    var didReceiveNotification = false
                //                    let didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                //                                                                                         object: nil,
                //                                                                                         queue: queue) { _ in
                //                        sender.send(jsonObject: payload)
                //                        didReceiveNotification = true
                //                    }
                //
                //                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: self)
                //                    expect(didReceiveNotification).toEventually(beTrue())
                //                    expect(isSendingCompleted).toEventually(beTrue())
                //
                //                    let getDBContent = { return DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection) { errorMsg in
                //                        fail(errorMsg)
                //                    }}
                //                    expect(getDBContent()).toAfterTimeout(haveCount(0), timeout: 2.0)
                //
                //                    expect(uploadsToRat).to(equal(1))
                //
                //                    NotificationCenter.default.removeObserver(uploadObserver)
                //                    NotificationCenter.default.removeObserver(didBecomeActiveObserver)
                //                }
            }
        }
    }
}
