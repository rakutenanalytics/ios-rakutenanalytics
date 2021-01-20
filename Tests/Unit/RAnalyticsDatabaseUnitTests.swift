import Quick
import Nimble
import SQLite3
import class RAnalytics.RAnalyticsDatabase

class RAnalyticsDatabaseUnitTests: QuickSpec {

    override func spec() {
        describe("RAnalyticsDatabase") {

            let bigNumber = UInt(100500)
            var connection: SQlite3Pointer!
            var readonlyConnection: SQlite3Pointer!

            beforeEach {
                connection = DatabaseTestUtils.openRegularConnection()
                readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                
                sqlite3_close(connection)
                sqlite3_close(readonlyConnection)

                connection = nil
                readonlyConnection = nil
            }

            context("when calling insert(blobs:into:limit:then:)") {
                it("should create table to insert if it does not exist yet") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists = false
                    waitUntil { done in
                        db.insert(blobs: [], into: "some_table", limit: 1) {
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableExists).to(beTrue())
                }

                it("should insert blobs into provided table") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    let anotherBlob = "bar".data(using: .utf8)!

                    var insertedBlobs = [Data]()
                    waitUntil { done in
                        db.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0) {
                            insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(insertedBlobs).to(elementsEqual([blob, anotherBlob]))
                }

                it("should limit amount of records in updated table as limit passed in param") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let previousContent = [
                        "fizz".data(using: .utf8)!,
                        "bazz".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: previousContent, table: "some_table", connection: connection)

                    var tableContents = [Data]()
                    waitUntil { done in
                        db.insert(blobs: [], into: "some_table", limit: 1) {
                            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableContents).to(haveCount(1))
                }

                it("should limit both just-inserted and old entries leaving the newest ones") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let previousContent = [
                        "fizz".data(using: .utf8)!,
                        "bazz".data(using: .utf8)!
                    ]
                    let newContent = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: previousContent, table: "some_table", connection: connection)

                    var tableContents = [Data]()
                    waitUntil { done in
                        db.insert(blobs: newContent, into: "some_table", limit: 1) {
                            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableContents).to(elementsEqual([newContent.last!]))
                }

                it("should not remove previous or new records from DB if limit is 0") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let previousContent = [
                        "fizz".data(using: .utf8)!,
                        "bazz".data(using: .utf8)!
                    ]
                    let newContent = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: previousContent, table: "some_table", connection: connection)

                    var tableContents = [Data]()
                    waitUntil { done in
                        db.insert(blobs: newContent, into: "some_table", limit: 0) {
                            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableContents).to(elementsEqual(previousContent + newContent))
                }

                context("and some error occurred") {

                    it("should not create passed table") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableExists: Bool?
                        waitUntil { done in
                            db.insert(blobs: ["foo".data(using: .utf8)!], into: "some_table", limit: 0) {
                                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)
                                done()
                            }
                        }

                        expect(tableExists).to(beFalse())
                    }

                    it("should not insert records in DB") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableContents: [Data]? = nil
                        waitUntil { done in
                            db.insert(blobs: ["foo".data(using: .utf8)!], into: "some_table", limit: 0) {
                                tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }

                        expect(tableContents).to(equal([]))
                    }

                    it("should not remove old records from DB") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        DatabaseTestUtils.insert(blobs: ["foo".data(using: .utf8)!], table: "some_table", connection: connection)

                        var tableContents = [Data]()
                        waitUntil { done in
                            db.insert(blobs: ["bar".data(using: .utf8)!], into: "some_table", limit: 0) {
                                tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: readonlyConnection)
                                done()
                            }
                        }

                        expect(tableContents).to(elementsEqual(["foo".data(using: .utf8)!]))
                    }
                }
            }

            context("when calling fetch(blobs:into:limit:then:)") {

                it("should create passed table if table did not exist before") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists = false
                    waitUntil { done in
                        db.fetchBlobs(bigNumber, from: "some_table") { _, _ in
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableExists).to(beTrue())
                }
                
                it("should not create passed table if the app will terminate") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists = false
                    waitUntil { done in
                        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
                        db.fetchBlobs(bigNumber, from: "some_table") { _, _ in
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableExists).to(beFalse())
                }

                it("should fetch blobs from passed table") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedBlobs: [Data]?
                    waitUntil { done in
                        db.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }

                    expect(fetchedBlobs).to(elementsEqual([blob]))
                }

                it("should fetch ids corresponding to blobs from passed table") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedIds: [Int64]?
                    waitUntil { done in
                        db.fetchBlobs(bigNumber, from: "some_table") { _, ids in
                            fetchedIds = ids
                            done()
                        }
                    }

                    expect(fetchedIds).to(elementsEqual([1]))
                }

                it("should not fetch blobs if amount to fetch is 0") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedBlobs: [Data]? = []
                    waitUntil { done in
                        db.fetchBlobs(0, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }

                    expect(fetchedBlobs).to(beNil())
                }

                it("should not fetch identifiers if amount to fetch is 0") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedIds: [Int64]? = []
                    waitUntil { done in
                        db.fetchBlobs(0, from: "some_table") { _, ids in
                            fetchedIds = ids
                            done()
                        }
                    }

                    expect(fetchedIds).to(beNil())
                }

                it("should limit the amount of fetched blobs to amount param fetching the oldest ones first") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!,
                        "baz".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var fetchedBlobs: [Data]?
                    waitUntil { done in
                        db.fetchBlobs(2, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }

                    expect(fetchedBlobs).to(elementsEqual(["foo".data(using: .utf8)!,
                                                           "bar".data(using: .utf8)!]))
                }

                it("should limit the amount of fetched ids to amount param fetching the oldest ones first") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!,
                        "baz".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var fetchedIds: [Int64]?
                    waitUntil { done in
                        db.fetchBlobs(2, from: "some_table") { _, ids in
                            fetchedIds = ids
                            done()
                        }
                    }

                    expect(fetchedIds).to(elementsEqual([1, 2]))
                }

                context("and some error occurred") {

                    it("should not create passed table") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableExists: Bool?
                        waitUntil { done in
                            db.fetchBlobs(bigNumber, from: "some_table") { _, _ in
                                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)
                                done()
                            }
                        }

                        expect(tableExists).to(beFalse())
                    }

                    it("should not fetch blobs from DB") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        let blob = "foo".data(using: .utf8)!
                        db.insert(blob: blob, into: "some_table", limit: 0, then: { })

                        var fetchedBlobs: [Data]? = []
                        waitUntil { done in
                            db.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                                fetchedBlobs = blobs
                                done()
                            }
                        }

                        expect(fetchedBlobs).to(beNil())
                    }

                    it("should not fetch ids from DB") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        let blob = "foo".data(using: .utf8)!
                        db.insert(blob: blob, into: "some_table", limit: 0, then: { })

                        var fetchedIds: [Int64]? = []
                        waitUntil { done in
                            db.fetchBlobs(bigNumber, from: "some_table") { _, ids in
                                fetchedIds = ids
                                done()
                            }
                        }

                        expect(fetchedIds).to(beNil())
                    }
                }
            }

            describe("when calling deleteBlobs(identifiers:in:then:") {

                it("should create passed table if table did not exist before") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists: Bool?
                    waitUntil { done in
                        db.deleteBlobs(identifiers: [], in: "some_table") {
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableExists).to(beTrue())
                }

                it("should delete items for passed IDs") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var itemsInDb: [Data]?
                    waitUntil { done in
                        db.deleteBlobs(identifiers: [1, 2], in: "some_table") {
                            itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(itemsInDb).to(beEmpty())
                }

                it("should not delete items which IDs were not passed for deletion") {
                    let db = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var itemsInDb: [Data]?
                    waitUntil { done in
                        db.deleteBlobs(identifiers: [1], in: "some_table") {
                            itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(itemsInDb).to(elementsEqual(["bar".data(using: .utf8)!]))
                }

                context("and some error occurred") {

                    it("should not create passed table") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableExists: Bool?
                        waitUntil { done in
                            db.deleteBlobs(identifiers: [], in: "some_table") {
                                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)
                                done()
                            }
                        }

                        expect(tableExists).to(beFalse())
                    }

                    it("should not delete blobs from DB if some error occurred") {
                        let db = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        let blobs = ["foo".data(using: .utf8)!]
                        DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                        var itemsInDb: [Data]?
                        waitUntil { done in
                            db.deleteBlobs(identifiers: [1], in: "some_table") {
                                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }

                        expect(itemsInDb).to(elementsEqual(["foo".data(using: .utf8)!]))
                    }
                }
            }
        }
    }
}
