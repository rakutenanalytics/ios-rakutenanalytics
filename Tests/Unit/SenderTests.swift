import Quick
import Nimble

@testable import RAnalytics

class SenderTests: QuickSpec {

    override func spec() {

        describe("RAnalyticsSender") {
            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            let databaseTableName = "testTableName"
            let payload = ["key": "value"]
            let bundle = BundleMock()

            var sender: RAnalyticsSender!
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!

            beforeEach {
                URLSessionMock.startMockingURLSession()
                // Create in-memory DB
                databaseConnection = DatabaseTestUtils.openRegularConnection()
                database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)

                sender = RAnalyticsSender(endpoint: URL(string: "https://endpoint.co.jp/")!,
                                          database: database,
                                          databaseTable: databaseTableName,
                                          bundle: bundle,
                                          session: URLSession.shared)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()

                DatabaseTestUtils.deleteTableIfExists(databaseTableName, connection: databaseConnection)
                databaseConnection = nil
                database = nil
                bundle.mutableEnableInternalSerialization = false
            }

            context("JSON serialization") {
                it("should send given payload when enableInternalSerialization is false") {
                    var isSendingCompleted = false
                    stubRATResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    bundle.mutableEnableInternalSerialization = false
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())
                }

                it("should send given payload when enableInternalSerialization is true") {
                    var isSendingCompleted = false
                    stubRATResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    bundle.mutableEnableInternalSerialization = true
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())
                }
            }

            context("when setting batching delay") {

                it("should succeed with default batching delay", closure: {
                    stubRATResponse(statusCode: 200, completion: nil)

                    sender.send(jsonObject: payload)
                    expect(sender.uploadTimerInterval).toEventually(equal(0))
                })

                it("should succeed with custom batching delay") {
                    stubRATResponse(statusCode: 200, completion: nil)

                    sender.setBatchingDelayBlock(15.0)
                    sender.send(jsonObject: payload)
                    expect(sender.uploadTimerInterval).toEventually(equal(15.0))
                }
            }

            context("when sending events to RAT") {

                it("should send given payload") {
                    var isSendingCompleted = false
                    stubRATResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())
                }

                it("should send notification when sending fails") {
                    var isSendingCompleted = false
                    stubRATResponse(statusCode: 500) {
                        isSendingCompleted = true
                    }

                    var didReceiveNotification = false
                    let queue = OperationQueue()
                    let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.RAnalyticsUploadFailure,
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

                it("should remove DB record after event is sent", closure: {
                    var isSendingCompleted = false
                    stubRATResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }
                    sender.send(jsonObject: payload)
                    expect(isSendingCompleted).toEventually(beTrue())

                    let dbContent = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
                    expect(dbContent).toAfterTimeout(beEmpty())
                })

                it("should not remove DB record before event is sent", closure: {
                    stubRATResponse(statusCode: 200, completion: nil)
                    sender.setBatchingDelayBlock(30.0)
                    sender.send(jsonObject: payload)

                    let getDBContent = { return DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection) }
                    expect(getDBContent()).toAfterTimeout(haveCount(1), timeout: 2.0)
                })

                it("should not send duplicate events when app becomes active") {
                    var isSendingCompleted = false
                    stubRATResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }

                    var uploadsToRat = 0
                    let queue = OperationQueue()
                    let uploadObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.RAnalyticsUploadSuccess,
                                                                                object: nil,
                                                                                queue: queue) { (notification) in
                        if (notification.object as? [Any])?.first as? [String: String] == payload {
                            uploadsToRat += 1
                        }
                    }

                    var didReceiveNotification = false
                    let didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                                                         object: nil,
                                                                                         queue: queue) { (_) in
                        sender.setBatchingDelayBlock(0)
                        sender.send(jsonObject: payload)

                        didReceiveNotification = true
                    }

                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: self)
                    expect(didReceiveNotification).toEventually(beTrue())
                    expect(isSendingCompleted).toEventually(beTrue())

                    let dbContent = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
                    expect(uploadsToRat).to(equal(1))
                    expect(dbContent).to(beEmpty())

                    NotificationCenter.default.removeObserver(uploadObserver)
                    NotificationCenter.default.removeObserver(didBecomeActiveObserver)
                }
            }

            // MARK: - Helpers

            func stubRATResponse(statusCode: Int, completion: (() -> Void)?) {
                sessionMock.httpResponse = HTTPURLResponse(url: URL(string: "empty")!,
                                                           statusCode: statusCode,
                                                           httpVersion: nil,
                                                           headerFields: nil)
                sessionMock.completionHandler = completion
                sessionMock.responseData = nil
                sessionMock.responseError = nil
            }
        }
    }
}
