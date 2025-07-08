// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable line_length

import Quick
import Nimble
import SQLite3
import Foundation
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class RAnalyticsDatabaseSpec: QuickSpec {

    override class func spec() {
        describe("RAnalyticsDatabase") {

            let bigNumber = UInt(100500)
            var connection: SQlite3Pointer!
            var readonlyConnection: SQlite3Pointer!
            let bundle = BundleMock()

            beforeEach {
                connection = DatabaseTestUtils.openRegularConnection()
                readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)

                sqlite3_close_v2(connection)
                sqlite3_close_v2(readonlyConnection)

                connection = nil
                readonlyConnection = nil
                
                bundle.isManualInitializationEnabled = false
                AnalyticsManager.isConfigured = true
            }

            context("when calling insert(blobs:into:limit:then:)") {
                it("should create table to insert if it does not exist yet") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists = false
                    waitUntil { done in
                        database.insert(blobs: [], into: "some_table", limit: 1) {
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableExists).to(beTrue())
                }

                it("should insert blobs into provided table") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    let anotherBlob = "bar".data(using: .utf8)!

                    var insertedBlobs = [Data]()
                    waitUntil { done in
                        database.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0) {
                            insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }
                    expect(insertedBlobs).to(elementsEqual([blob, anotherBlob]))
                }
                
                context("when manual initialization is enabled") {
                    it("should not insert given blobs if SDK not initialized") {
                        let database = DatabaseTestUtils.mkDatabase(connection: connection)
                        let blob = "foo".data(using: .utf8)!
                        let anotherBlob = "bar".data(using: .utf8)!
                        
                        bundle.isManualInitializationEnabled = true
                        AnalyticsManager.isConfigured = false

                        var insertedBlobs = [Data]()
                        waitUntil { done in
                            database.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0) {
                                insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }
                        expect(insertedBlobs).to(beEmpty())
                    }
                    
                    it("should insert given blobs if SDK initialized") {
                        let database = DatabaseTestUtils.mkDatabase(connection: connection)
                        let blob = "foo".data(using: .utf8)!
                        let anotherBlob = "bar".data(using: .utf8)!
                        
                        bundle.isManualInitializationEnabled = true
                        AnalyticsManager.configure()

                        var insertedBlobs = [Data]()
                        waitUntil { done in
                            database.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0) {
                                insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }
                        expect(insertedBlobs).to(elementsEqual([blob, anotherBlob]))
                    }
                }

                it("should limit amount of records in updated table as limit passed in param") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let previousContent = [
                        "fizz".data(using: .utf8)!,
                        "bazz".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: previousContent, table: "some_table", connection: connection)

                    var tableContents = [Data]()
                    waitUntil { done in
                        database.insert(blobs: [], into: "some_table", limit: 1) {
                            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableContents).to(haveCount(1))
                }

                it("should limit both just-inserted and old entries leaving the newest ones") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
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
                        database.insert(blobs: newContent, into: "some_table", limit: 1) {
                            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableContents).to(elementsEqual([newContent.last!]))
                }

                it("should not remove previous or new records from database if limit is 0") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
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
                        database.insert(blobs: newContent, into: "some_table", limit: 0) {
                            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }

                    expect(tableContents).to(elementsEqual(previousContent + newContent))
                }

                context("and some error occurred") {
                    it("should not create passed table") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableExists: Bool?
                        waitUntil { done in
                            database.insert(blobs: ["foo".data(using: .utf8)!], into: "some_table", limit: 0) {
                                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)
                                done()
                            }
                        }
                        expect(tableExists).to(beFalse())
                    }

                    it("should not insert records in database") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableContents: [Data]?
                        waitUntil { done in
                            database.insert(blobs: ["foo".data(using: .utf8)!], into: "some_table", limit: 0) {
                                tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }
                        expect(tableContents).to(equal([]))
                    }

                    it("should not remove old records from database") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        DatabaseTestUtils.insert(blobs: ["foo".data(using: .utf8)!], table: "some_table", connection: connection)

                        var tableContents = [Data]()
                        waitUntil { done in
                            database.insert(blobs: ["bar".data(using: .utf8)!], into: "some_table", limit: 0) {
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
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists = false
                    waitUntil { done in
                        database.fetchBlobs(bigNumber, from: "some_table") { _, _ in
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }
                    expect(tableExists).to(beTrue())
                }

                it("should not create passed table if the app will terminate") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists = false
                    waitUntil { done in
                        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
                        database.fetchBlobs(bigNumber, from: "some_table") { _, _ in
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }
                    expect(tableExists).to(beFalse())
                }

                it("should fetch blobs from passed table") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedBlobs: [Data]?
                    waitUntil { done in
                        database.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }
                    expect(fetchedBlobs).to(elementsEqual([blob]))
                }
                
                context("when manual initialization is enabled") {
                    it("should not fetch given blobs if SDK not initialized") {
                        let database = DatabaseTestUtils.mkDatabase(connection: connection)
                        let blob = "foo".data(using: .utf8)!
                        DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)
                        
                        bundle.isManualInitializationEnabled = true
                        AnalyticsManager.isConfigured = false

                        var fetchedBlobs: [Data]?
                        waitUntil { done in
                            database.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                                fetchedBlobs = blobs
                                done()
                            }
                        }
                        expect(fetchedBlobs).to(beNil())
                    }
                    
                    it("should fetch given blobs if SDK initialized") {
                        let database = DatabaseTestUtils.mkDatabase(connection: connection)
                        let blob = "foo".data(using: .utf8)!
                        DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)
                        
                        bundle.isManualInitializationEnabled = true
                        AnalyticsManager.configure()

                        var fetchedBlobs: [Data]?
                        waitUntil { done in
                            database.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                                fetchedBlobs = blobs
                                done()
                            }
                        }
                        expect(fetchedBlobs).to(elementsEqual([blob]))
                    }
                }
                
                it("should fetch blobs from passed table") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)
                    
                    var fetchedBlobs: [Data]?
                    waitUntil { done in
                        database.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }
                    expect(fetchedBlobs).to(elementsEqual([blob]))
                }
                
                it("should handle nil blob data gracefully") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let query = "CREATE TABLE IF NOT EXISTS some_table (id INTEGER PRIMARY KEY, data BLOB)"
                    var statement: OpaquePointer?
                    sqlite3_prepare_v2(connection, query, -1, &statement, nil)
                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                    
                    let insertQuery = "INSERT INTO some_table (data) VALUES (NULL)"
                    sqlite3_prepare_v2(connection, insertQuery, -1, &statement, nil)
                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                    
                    var fetchedBlobs: [Data]?
                    waitUntil { done in
                        database.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }
                    expect(fetchedBlobs).to(beNil())
                }

                it("should fetch ids corresponding to blobs from passed table") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)
                    var fetchedIds: [Int64]?
                    waitUntil { done in
                        database.fetchBlobs(bigNumber, from: "some_table") { _, ids in
                            fetchedIds = ids
                            done()
                        }
                    }
                    expect(fetchedIds).to(elementsEqual([1]))
                }

                it("should not fetch blobs if amount to fetch is 0") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedBlobs: [Data]? = []
                    waitUntil { done in
                        database.fetchBlobs(0, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }
                    expect(fetchedBlobs).to(beNil())
                }

                it("should not fetch identifiers if amount to fetch is 0") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blob = "foo".data(using: .utf8)!
                    DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                    var fetchedIds: [Int64]? = []
                    waitUntil { done in
                        database.fetchBlobs(0, from: "some_table") { _, ids in
                            fetchedIds = ids
                            done()
                        }
                    }
                    expect(fetchedIds).to(beNil())
                }

                it("should limit the amount of fetched blobs to amount param fetching the oldest ones first") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!,
                        "baz".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var fetchedBlobs: [Data]?
                    waitUntil { done in
                        database.fetchBlobs(2, from: "some_table") { blobs, _ in
                            fetchedBlobs = blobs
                            done()
                        }
                    }
                    expect(fetchedBlobs).to(elementsEqual(["foo".data(using: .utf8)!,
                                                           "bar".data(using: .utf8)!]))
                }

                it("should limit the amount of fetched ids to amount param fetching the oldest ones first") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!,
                        "baz".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var fetchedIds: [Int64]?
                    waitUntil { done in
                        database.fetchBlobs(2, from: "some_table") { _, ids in
                            fetchedIds = ids
                            done()
                        }
                    }
                    expect(fetchedIds).to(elementsEqual([1, 2]))
                }

                context("and some error occurred") {
                    it("should not create passed table") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableExists: Bool?
                        waitUntil { done in
                            database.fetchBlobs(bigNumber, from: "some_table") { _, _ in
                                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)
                                done()
                            }
                        }
                        expect(tableExists).to(beFalse())
                    }

                    it("should not fetch blobs from database") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        let blob = "foo".data(using: .utf8)!
                        database.insert(blob: blob, into: "some_table", limit: 0, then: { })

                        var fetchedBlobs: [Data]? = []
                        waitUntil { done in
                            database.fetchBlobs(bigNumber, from: "some_table") { blobs, _ in
                                fetchedBlobs = blobs
                                done()
                            }
                        }
                        expect(fetchedBlobs).to(beNil())
                    }

                    it("should not fetch ids from database") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        let blob = "foo".data(using: .utf8)!
                        database.insert(blob: blob, into: "some_table", limit: 0, then: { })

                        var fetchedIds: [Int64]? = []
                        waitUntil { done in
                            database.fetchBlobs(bigNumber, from: "some_table") { _, ids in
                                fetchedIds = ids
                                done()
                            }
                        }
                        expect(fetchedIds).to(beNil())
                    }
                }
            }

            describe("when calling deleteBlobs(identifiers:in:then:") {
                it("should not create passed table if table did not exist before") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)

                    var tableExists: Bool?
                    waitUntil { done in
                        database.deleteBlobs(identifiers: [], in: "some_table") {
                            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)
                            done()
                        }
                    }
                    expect(tableExists).to(beFalse())
                }

                it("should delete items for passed IDs") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var itemsInDb: [Data]?
                    waitUntil { done in
                        database.deleteBlobs(identifiers: [1, 2], in: "some_table") {
                            itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }
                    expect(itemsInDb).to(beEmpty())
                }
                
                context("when manual initialization is enabled") {
                    it("should not delete given items if SDK not initialized") {
                        let database = DatabaseTestUtils.mkDatabase(connection: connection)
                        let blobs = [
                            "foo".data(using: .utf8)!,
                            "bar".data(using: .utf8)!
                        ]
                        DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)
                        
                        bundle.isManualInitializationEnabled = true
                        AnalyticsManager.isConfigured = false

                        var itemsInDb: [Data]?
                        waitUntil { done in
                            database.deleteBlobs(identifiers: [1, 2], in: "some_table") {
                                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }
                        expect(itemsInDb).toNot(beEmpty())
                    }
                    
                    it("should delete given items if SDK initialized") {
                        let database = DatabaseTestUtils.mkDatabase(connection: connection)
                        let blobs = [
                            "foo".data(using: .utf8)!,
                            "bar".data(using: .utf8)!
                        ]
                        DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)
                        
                        bundle.isManualInitializationEnabled = true
                        AnalyticsManager.configure()

                        var itemsInDb: [Data]?
                        waitUntil { done in
                            database.deleteBlobs(identifiers: [1, 2], in: "some_table") {
                                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }
                        expect(itemsInDb).to(beEmpty())
                    }
                }

                it("should not delete items which IDs were not passed for deletion") {
                    let database = DatabaseTestUtils.mkDatabase(connection: connection)
                    let blobs = [
                        "foo".data(using: .utf8)!,
                        "bar".data(using: .utf8)!
                    ]
                    DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                    var itemsInDb: [Data]?
                    waitUntil { done in
                        database.deleteBlobs(identifiers: [1], in: "some_table") {
                            itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                            done()
                        }
                    }
                    expect(itemsInDb).to(elementsEqual(["bar".data(using: .utf8)!]))
                }

                context("and some error occurred") {
                    it("should not create passed table") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                        var tableExists: Bool?
                        waitUntil { done in
                            database.deleteBlobs(identifiers: [], in: "some_table") {
                                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)
                                done()
                            }
                        }
                        expect(tableExists).to(beFalse())
                    }

                    it("should not delete blobs from database if some error occurred") {
                        let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                        let blobs = ["foo".data(using: .utf8)!]
                        DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                        var itemsInDb: [Data]?
                        waitUntil { done in
                            database.deleteBlobs(identifiers: [1], in: "some_table") {
                                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)
                                done()
                            }
                        }
                        expect(itemsInDb).to(elementsEqual(["foo".data(using: .utf8)!]))
                    }
                }
            }

            context("when calling mkAnalyticsDBConnection") {
                func verify(_ databaseParentDirectory: FileManager.SearchPathDirectory) {
                    it("should open a connection to given database file name") {
                        let connection: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "db",
                                                                                                     databaseParentDirectory: databaseParentDirectory)
                        expect(DatabaseTestUtils.databaseName(connection: connection)).to(endWith("/db"))
                    }

                    it("should be able to open multiple connections to given database file name") {
                        let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "db",
                                                                                                      databaseParentDirectory: databaseParentDirectory)
                        let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "db",
                                                                                                      databaseParentDirectory: databaseParentDirectory)
                        expect(DatabaseTestUtils.databaseName(connection: connectionA)).to(equal(DatabaseTestUtils.databaseName(connection: connectionB)))
                    }

                    it("should open a connection to in-memory database in case of error") {
                        let connection: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "",
                                                                                                     databaseParentDirectory: databaseParentDirectory) // using invalid path to generate error
                        expect(DatabaseTestUtils.databaseName(connection: connection)).toNot(beNil())
                        expect(DatabaseTestUtils.databaseName(connection: connection)).to(equal("")) // in-memory databases return empty string as a name
                    }

                    it("should be able to open multiple connections to in-memory database") {
                        let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "",
                                                                                                      databaseParentDirectory: databaseParentDirectory)
                        let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "",
                                                                                                      databaseParentDirectory: databaseParentDirectory)
                        expect(DatabaseTestUtils.databaseName(connection: connectionA)).to(equal(""))
                        expect(DatabaseTestUtils.databaseName(connection: connectionB)).to(equal(""))
                    }

                    it("should open connection to the same in-memory database") {
                        let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "",
                                                                                                      databaseParentDirectory: databaseParentDirectory)
                        let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: "",
                                                                                                      databaseParentDirectory: databaseParentDirectory)
                        let databaseA = DatabaseTestUtils.mkDatabase(connection: connectionA)

                        waitUntil { done in
                            let blob = "foo".data(using: .utf8)!
                            let anotherBlob = "bar".data(using: .utf8)!

                            databaseA.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0) {
                                let insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connectionB)
                                expect(insertedBlobs).to(elementsEqual([blob, anotherBlob]))
                                done()
                            }
                        }
                    }
                }

                verify(.applicationSupportDirectory)
                verify(.documentDirectory)
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable line_length
