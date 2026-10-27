// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable line_length

import Testing
import SQLite3
import Foundation
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsDatabase")
struct RAnalyticsDatabaseTests {
    static let bigNumber = UInt(100500)

    var connection: SQlite3Pointer!
    var readonlyConnection: SQlite3Pointer!
    let bundle = BundleMock()

    func tearDown() {
        DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)

        sqlite3_close_v2(connection)
        sqlite3_close_v2(readonlyConnection)

        bundle.isManualInitializationEnabled = false
    }

    @Suite("when calling insert(blobs:into:limit:)")
    struct InsertBlobsTests {
        static let bigNumber = RAnalyticsDatabaseTests.bigNumber

        var connection: SQlite3Pointer!
        var readonlyConnection: SQlite3Pointer!
        let bundle = BundleMock()

        init() {
            connection = DatabaseTestUtils.openRegularConnection()
            readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
        }

        func tearDown() {
            DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)

            sqlite3_close_v2(connection)
            sqlite3_close_v2(readonlyConnection)

            bundle.isManualInitializationEnabled = false
        }

        @Test("should create table to insert if it does not exist yet")
        func testCreatesTableToInsertIfItDoesNotExistYet() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)

            var tableExists = false
            database.enabled = true
            await database.insert(blobs: [], into: "some_table", limit: 1)
            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)

            #expect(tableExists == true)
        }

        @Test("should insert blobs into provided table")
        func testInsertsBlobsIntoProvidedTable() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blob = "foo".data(using: .utf8)!
            let anotherBlob = "bar".data(using: .utf8)!

            var insertedBlobs = [Data]()
            database.enabled = true
            await database.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0)
            insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

            #expect(insertedBlobs == [blob, anotherBlob])
        }

        @Suite("when manual initialization is enabled")
        struct WhenManualInitializationIsEnabledTests {
            var connection: SQlite3Pointer!
            let bundle = BundleMock()

            init() {
                connection = DatabaseTestUtils.openRegularConnection()
            }

            func tearDown() {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                sqlite3_close_v2(connection)
                bundle.isManualInitializationEnabled = false
            }

            @Test("should not insert given blobs if SDK not initialized")
            func testShouldNotInsertGivenBlobsIfSDKNotInitialized() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: connection)
                let blob = "foo".data(using: .utf8)!
                let anotherBlob = "bar".data(using: .utf8)!

                bundle.isManualInitializationEnabled = true

                var insertedBlobs = [Data]()
                database.enabled = false
                await database.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0)
                insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

                #expect(insertedBlobs.isEmpty)
            }

            @Test("should insert given blobs if SDK initialized")
            func testShouldInsertGivenBlobsIfSDKInitialized() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: connection)
                let blob = "foo".data(using: .utf8)!
                let anotherBlob = "bar".data(using: .utf8)!

                bundle.isManualInitializationEnabled = true

                var insertedBlobs = [Data]()
                database.enabled = true
                await database.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0)
                insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

                #expect(insertedBlobs == [blob, anotherBlob])
            }
        }

        @Test("should limit amount of records in updated table as limit passed in param")
        func testLimitsAmountOfRecordsInUpdatedTableAsLimitPassedInParam() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let previousContent = [
                "fizz".data(using: .utf8)!,
                "bazz".data(using: .utf8)!
            ]
            DatabaseTestUtils.insert(blobs: previousContent, table: "some_table", connection: connection)

            var tableContents = [Data]()
            database.enabled = true
            await database.insert(blobs: [], into: "some_table", limit: 1)
            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

            #expect(tableContents.count == 1)
        }

        @Test("should limit both just-inserted and old entries leaving the newest ones")
        func testLimitsBothJustInsertedAndOldEntriesLeavingTheNewestOnes() async throws {
            defer { tearDown() }

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
            database.enabled = true
            await database.insert(blobs: newContent, into: "some_table", limit: 1)
            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

            #expect(tableContents == [newContent.last!])
        }

        @Test("should not remove previous or new records from database if limit is 0")
        func testShouldNotRemovePreviousOrNewRecordsFromDatabaseIfLimitIsZero() async throws {
            defer { tearDown() }

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
            database.enabled = true
            await database.insert(blobs: newContent, into: "some_table", limit: 0)
            tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

            #expect(tableContents == previousContent + newContent)
        }

        @Suite("and some error occurred")
        struct AndSomeErrorOccurredTests {
            var readonlyConnection: SQlite3Pointer!
            var connection: SQlite3Pointer!

            init() {
                connection = DatabaseTestUtils.openRegularConnection()
                readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
            }

            func tearDown() {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                sqlite3_close_v2(connection)
                sqlite3_close_v2(readonlyConnection)
            }

            @Test("should not create passed table")
            func testShouldNotCreatePassedTable() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                var tableExists: Bool?
                database.enabled = true
                await database.insert(blobs: ["foo".data(using: .utf8)!], into: "some_table", limit: 0)
                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)

                #expect(tableExists == false)
            }

            @Test("should not insert records in database")
            func testShouldNotInsertRecordsInDatabase() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                var tableContents: [Data]?
                database.enabled = true
                await database.insert(blobs: ["foo".data(using: .utf8)!], into: "some_table", limit: 0)
                tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

                #expect(tableContents == [])
            }

            @Test("should not remove old records from database")
            func testShouldNotRemoveOldRecordsFromDatabase() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                DatabaseTestUtils.insert(blobs: ["foo".data(using: .utf8)!], table: "some_table", connection: connection)

                var tableContents = [Data]()
                database.enabled = true
                await database.insert(blobs: ["bar".data(using: .utf8)!], into: "some_table", limit: 0)
                tableContents = DatabaseTestUtils.fetchTableContents("some_table", connection: readonlyConnection)

                #expect(tableContents == ["foo".data(using: .utf8)!])
            }
        }
    }

    @Suite("when calling fetchBlobs(_:from:)")
    struct FetchBlobsTests {
        static let bigNumber = RAnalyticsDatabaseTests.bigNumber

        var connection: SQlite3Pointer!
        var readonlyConnection: SQlite3Pointer!
        let bundle = BundleMock()

        init() {
            connection = DatabaseTestUtils.openRegularConnection()
            readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
        }

        func tearDown() {
            DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
            sqlite3_close_v2(connection)
            sqlite3_close_v2(readonlyConnection)
            bundle.isManualInitializationEnabled = false
        }

        @Test("should create passed table if table did not exist before")
        func testCreatesPassedTableIfTableDidNotExistBefore() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)

            var tableExists = false
            database.enabled = true
            _ = await database.fetchBlobs(Self.bigNumber, from: "some_table")
            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)

            #expect(tableExists == true)
        }

        @Test("should not create passed table if the app will terminate")
        func testShouldNotCreatePassedTableIfTheAppWillTerminate() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)

            var tableExists = false
            NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
            database.enabled = true
            _ = await database.fetchBlobs(Self.bigNumber, from: "some_table")
            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)

            #expect(tableExists == false)
        }

        @Test("should fetch blobs from passed table")
        func testFetchesBlobsFromPassedTable() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blob = "foo".data(using: .utf8)!
            DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

            var fetchedBlobs: [Data]?
            database.enabled = true
            let (blobs, _) = await database.fetchBlobs(Self.bigNumber, from: "some_table")
            fetchedBlobs = blobs

            #expect(fetchedBlobs == [blob])
        }

        @Suite("when manual initialization is enabled")
        struct WhenManualInitializationIsEnabledTests {
            var connection: SQlite3Pointer!
            let bundle = BundleMock()

            init() {
                connection = DatabaseTestUtils.openRegularConnection()
            }

            func tearDown() {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                sqlite3_close_v2(connection)
                bundle.isManualInitializationEnabled = false
            }

            @Test("should not fetch given blobs if SDK not initialized")
            func testShouldNotFetchGivenBlobsIfSDKNotInitialized() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: connection)
                let blob = "foo".data(using: .utf8)!
                DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                bundle.isManualInitializationEnabled = true

                var fetchedBlobs: [Data]?
                database.enabled = false
                let (blobs, _) = await database.fetchBlobs(FetchBlobsTests.bigNumber, from: "some_table")
                fetchedBlobs = blobs

                #expect(fetchedBlobs == nil)
            }

            @Test("should fetch given blobs if SDK initialized")
            func testShouldFetchGivenBlobsIfSDKInitialized() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: connection)
                let blob = "foo".data(using: .utf8)!
                DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

                bundle.isManualInitializationEnabled = true

                var fetchedBlobs: [Data]?
                database.enabled = true
                let (blobs, _) = await database.fetchBlobs(FetchBlobsTests.bigNumber, from: "some_table")
                fetchedBlobs = blobs

                #expect(fetchedBlobs == [blob])
            }
        }

        @Test("should fetch blobs from passed table")
        func testFetchesBlobsFromPassedTableDuplicate() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blob = "foo".data(using: .utf8)!
            DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

            var fetchedBlobs: [Data]?
            database.enabled = true
            let (blobs, _) = await database.fetchBlobs(Self.bigNumber, from: "some_table")
            fetchedBlobs = blobs

            #expect(fetchedBlobs == [blob])
        }

        @Test("should handle nil blob data gracefully")
        func testHandlesNilBlobDataGracefully() async throws {
            defer { tearDown() }

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
            database.enabled = true
            let (blobs, _) = await database.fetchBlobs(Self.bigNumber, from: "some_table")
            fetchedBlobs = blobs

            #expect(fetchedBlobs == nil)
        }

        @Test("should fetch ids corresponding to blobs from passed table")
        func testFetchesIdsCorrespondingToBlobsFromPassedTable() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blob = "foo".data(using: .utf8)!
            DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)
            var fetchedIds: [Int64]?
            database.enabled = true
            let (_, ids) = await database.fetchBlobs(Self.bigNumber, from: "some_table")
            fetchedIds = ids

            #expect(fetchedIds == [1])
        }

        @Test("should not fetch blobs if amount to fetch is 0")
        func testShouldNotFetchBlobsIfAmountToFetchIsZero() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blob = "foo".data(using: .utf8)!
            DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

            var fetchedBlobs: [Data]? = []
            database.enabled = true
            let (blobs, _) = await database.fetchBlobs(0, from: "some_table")
            fetchedBlobs = blobs

            #expect(fetchedBlobs == nil)
        }

        @Test("should not fetch identifiers if amount to fetch is 0")
        func testShouldNotFetchIdentifiersIfAmountToFetchIsZero() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blob = "foo".data(using: .utf8)!
            DatabaseTestUtils.insert(blobs: [blob], table: "some_table", connection: connection)

            var fetchedIds: [Int64]? = []
            database.enabled = true
            let (_, ids) = await database.fetchBlobs(0, from: "some_table")
            fetchedIds = ids

            #expect(fetchedIds == nil)
        }

        @Test("should limit the amount of fetched blobs to amount param fetching the oldest ones first")
        func testLimitsTheAmountOfFetchedBlobsToAmountParamFetchingTheOldestOnesFirst() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blobs = [
                "foo".data(using: .utf8)!,
                "bar".data(using: .utf8)!,
                "baz".data(using: .utf8)!
            ]
            DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

            var fetchedBlobs: [Data]?
            database.enabled = true
            let (resultBlobs, _) = await database.fetchBlobs(2, from: "some_table")
            fetchedBlobs = resultBlobs

            #expect(fetchedBlobs == ["foo".data(using: .utf8)!,
                                     "bar".data(using: .utf8)!])
        }

        @Test("should limit the amount of fetched ids to amount param fetching the oldest ones first")
        func testLimitsTheAmountOfFetchedIdsToAmountParamFetchingTheOldestOnesFirst() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blobs = [
                "foo".data(using: .utf8)!,
                "bar".data(using: .utf8)!,
                "baz".data(using: .utf8)!
            ]
            DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

            var fetchedIds: [Int64]?
            database.enabled = true
            let (_, ids) = await database.fetchBlobs(2, from: "some_table")
            fetchedIds = ids

            #expect(fetchedIds == [1, 2])
        }

        @Suite("and some error occurred")
        struct AndSomeErrorOccurredTests {
            var readonlyConnection: SQlite3Pointer!
            var connection: SQlite3Pointer!

            init() {
                connection = DatabaseTestUtils.openRegularConnection()
                readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
            }

            func tearDown() {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                sqlite3_close_v2(connection)
                sqlite3_close_v2(readonlyConnection)
            }

            @Test("should not create passed table")
            func testShouldNotCreatePassedTable() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                var tableExists: Bool?
                database.enabled = true
                _ = await database.fetchBlobs(FetchBlobsTests.bigNumber, from: "some_table")
                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)

                #expect(tableExists == false)
            }

            @Test("should not fetch blobs from database")
            func testShouldNotFetchBlobsFromDatabase() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                let blob = "foo".data(using: .utf8)!
                database.enabled = true
                await database.insert(blob: blob, into: "some_table", limit: 0)

                var fetchedBlobs: [Data]? = []
                database.enabled = true
                let (blobs, _) = await database.fetchBlobs(FetchBlobsTests.bigNumber, from: "some_table")
                fetchedBlobs = blobs

                #expect(fetchedBlobs == nil)
            }

            @Test("should not fetch ids from database")
            func testShouldNotFetchIdsFromDatabase() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                let blob = "foo".data(using: .utf8)!
                database.enabled = true
                await database.insert(blob: blob, into: "some_table", limit: 0)

                var fetchedIds: [Int64]? = []
                database.enabled = true
                let (_, ids) = await database.fetchBlobs(FetchBlobsTests.bigNumber, from: "some_table")
                fetchedIds = ids

                #expect(fetchedIds == nil)
            }
        }
    }

    @Suite("when calling deleteBlobs(identifiers:in:)")
    struct DeleteBlobsTests {
        var connection: SQlite3Pointer!
        let bundle = BundleMock()

        init() {
            connection = DatabaseTestUtils.openRegularConnection()
        }

        func tearDown() {
            DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
            sqlite3_close_v2(connection)
            bundle.isManualInitializationEnabled = false
        }

        @Test("should not create passed table if table did not exist before")
        func testShouldNotCreatePassedTableIfTableDidNotExistBefore() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)

            var tableExists: Bool?
            database.enabled = true
            await database.deleteBlobs(identifiers: [], in: "some_table")
            tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: connection)

            #expect(tableExists == false)
        }

        @Test("should delete items for passed IDs")
        func testDeletesItemsForPassedIDs() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blobs = [
                "foo".data(using: .utf8)!,
                "bar".data(using: .utf8)!
            ]
            DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

            var itemsInDb: [Data]?
            database.enabled = true
            await database.deleteBlobs(identifiers: [1, 2], in: "some_table")
            itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

            #expect(itemsInDb?.isEmpty == true)
        }

        @Suite("when manual initialization is enabled")
        struct WhenManualInitializationIsEnabledTests {
            var connection: SQlite3Pointer!
            let bundle = BundleMock()

            init() {
                connection = DatabaseTestUtils.openRegularConnection()
            }

            func tearDown() {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                sqlite3_close_v2(connection)
                bundle.isManualInitializationEnabled = false
            }

            @Test("should not delete given items if SDK not initialized")
            func testShouldNotDeleteGivenItemsIfSDKNotInitialized() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: connection)
                let blobs = [
                    "foo".data(using: .utf8)!,
                    "bar".data(using: .utf8)!
                ]
                DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                bundle.isManualInitializationEnabled = true

                var itemsInDb: [Data]?
                database.enabled = false
                await database.deleteBlobs(identifiers: [1, 2], in: "some_table")
                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

                #expect(itemsInDb?.isEmpty == false)
            }

            @Test("should delete given items if SDK initialized")
            func testShouldDeleteGivenItemsIfSDKInitialized() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: connection)
                let blobs = [
                    "foo".data(using: .utf8)!,
                    "bar".data(using: .utf8)!
                ]
                DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                bundle.isManualInitializationEnabled = true

                var itemsInDb: [Data]?
                database.enabled = true
                await database.deleteBlobs(identifiers: [1, 2], in: "some_table")
                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

                #expect(itemsInDb?.isEmpty == true)
            }
        }

        @Test("should not delete items which IDs were not passed for deletion")
        func testShouldNotDeleteItemsWhichIDsWereNotPassedForDeletion() async throws {
            defer { tearDown() }

            let database = DatabaseTestUtils.mkDatabase(connection: connection)
            let blobs = [
                "foo".data(using: .utf8)!,
                "bar".data(using: .utf8)!
            ]
            DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

            var itemsInDb: [Data]?
            database.enabled = true
            await database.deleteBlobs(identifiers: [1], in: "some_table")
            itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

            #expect(itemsInDb == ["bar".data(using: .utf8)!])
        }

        @Suite("and some error occurred")
        struct AndSomeErrorOccurredTests {
            var readonlyConnection: SQlite3Pointer!
            var connection: SQlite3Pointer!

            init() {
                connection = DatabaseTestUtils.openRegularConnection()
                readonlyConnection = DatabaseTestUtils.openReadonlyConnection()
            }

            func tearDown() {
                DatabaseTestUtils.deleteTableIfExists("some_table", connection: connection)
                sqlite3_close_v2(connection)
                sqlite3_close_v2(readonlyConnection)
            }

            @Test("should not create passed table")
            func testShouldNotCreatePassedTable() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)

                var tableExists: Bool?
                database.enabled = true
                await database.deleteBlobs(identifiers: [], in: "some_table")
                tableExists = DatabaseTestUtils.isTablePresent("some_table", connection: readonlyConnection)

                #expect(tableExists == false)
            }

            @Test("should not delete blobs from database if some error occurred")
            func testShouldNotDeleteBlobsFromDatabaseIfSomeErrorOccurred() async throws {
                defer { tearDown() }

                let database = DatabaseTestUtils.mkDatabase(connection: readonlyConnection)
                let blobs = ["foo".data(using: .utf8)!]
                DatabaseTestUtils.insert(blobs: blobs, table: "some_table", connection: connection)

                var itemsInDb: [Data]?
                database.enabled = true
                await database.deleteBlobs(identifiers: [1], in: "some_table")
                itemsInDb = DatabaseTestUtils.fetchTableContents("some_table", connection: connection)

                #expect(itemsInDb == ["foo".data(using: .utf8)!])
            }
        }
    }

    @Suite("when calling mkAnalyticsDBConnection")
    struct MkAnalyticsDBConnectionTests {
        @Suite("applicationSupportDirectory")
        struct ApplicationSupportDirectoryTests {
            @Test("should open a connection to given database file name")
            func testShouldOpenAConnectionToGivenDatabaseFileName() {
                let connection: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "db",
                    databaseParentDirectory: .applicationSupportDirectory)
                #expect(DatabaseTestUtils.databaseName(connection: connection)?.hasSuffix("/db") == true)
                sqlite3_close_v2(connection)
            }

            @Test("should be able to open multiple connections to given database file name")
            func testShouldBeAbleToOpenMultipleConnectionsToGivenDatabaseFileName() {
                let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "db",
                    databaseParentDirectory: .applicationSupportDirectory)
                let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "db",
                    databaseParentDirectory: .applicationSupportDirectory)
                #expect(DatabaseTestUtils.databaseName(connection: connectionA) == DatabaseTestUtils.databaseName(connection: connectionB))

                sqlite3_close_v2(connectionA)
                sqlite3_close_v2(connectionB)
            }

            @Test("should open a connection to in-memory database in case of error")
            func testShouldOpenAConnectionToInMemoryDatabaseInCaseOfError() {
                let connection: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .applicationSupportDirectory) // using invalid path to generate error
                #expect(DatabaseTestUtils.databaseName(connection: connection) != nil)
                #expect(DatabaseTestUtils.databaseName(connection: connection) == "") // in-memory databases return empty string as a name

                sqlite3_close_v2(connection)
            }

            @Test("should be able to open multiple connections to in-memory database")
            func testShouldBeAbleToOpenMultipleConnectionsToInMemoryDatabase() {
                let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .applicationSupportDirectory)
                let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .applicationSupportDirectory)
                #expect(DatabaseTestUtils.databaseName(connection: connectionA) == "")
                #expect(DatabaseTestUtils.databaseName(connection: connectionB) == "")

                sqlite3_close_v2(connectionA)
                sqlite3_close_v2(connectionB)
            }

            @Test("should open connection to the same in-memory database")
            func testShouldOpenConnectionToTheSameInMemoryDatabase() async throws {
                let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .applicationSupportDirectory)
                let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .applicationSupportDirectory)
                let databaseA = DatabaseTestUtils.mkDatabase(connection: connectionA)

                let blob = "foo".data(using: .utf8)!
                let anotherBlob = "bar".data(using: .utf8)!

                databaseA.enabled = true
                await databaseA.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0)
                let insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connectionB)
                #expect(insertedBlobs == [blob, anotherBlob])

                sqlite3_close_v2(connectionA)
                sqlite3_close_v2(connectionB)
            }
        }

        @Suite("documentDirectory")
        struct DocumentDirectoryTests {
            @Test("should open a connection to given database file name")
            func testShouldOpenAConnectionToGivenDatabaseFileName() {
                let connection: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "db",
                    databaseParentDirectory: .documentDirectory)
                #expect(DatabaseTestUtils.databaseName(connection: connection)?.hasSuffix("/db") == true)
                sqlite3_close_v2(connection)
            }

            @Test("should be able to open multiple connections to given database file name")
            func testShouldBeAbleToOpenMultipleConnectionsToGivenDatabaseFileName() {
                let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "db",
                    databaseParentDirectory: .documentDirectory)
                let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "db",
                    databaseParentDirectory: .documentDirectory)
                #expect(DatabaseTestUtils.databaseName(connection: connectionA) == DatabaseTestUtils.databaseName(connection: connectionB))

                sqlite3_close_v2(connectionA)
                sqlite3_close_v2(connectionB)
            }

            @Test("should open a connection to in-memory database in case of error")
            func testShouldOpenAConnectionToInMemoryDatabaseInCaseOfError() {
                let connection: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .documentDirectory) // using invalid path to generate error
                #expect(DatabaseTestUtils.databaseName(connection: connection) != nil)
                #expect(DatabaseTestUtils.databaseName(connection: connection) == "") // in-memory databases return empty string as a name

                sqlite3_close_v2(connection)
            }

            @Test("should be able to open multiple connections to in-memory database")
            func testShouldBeAbleToOpenMultipleConnectionsToInMemoryDatabase() {
                let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .documentDirectory)
                let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .documentDirectory)
                #expect(DatabaseTestUtils.databaseName(connection: connectionA) == "")
                #expect(DatabaseTestUtils.databaseName(connection: connectionB) == "")

                sqlite3_close_v2(connectionA)
                sqlite3_close_v2(connectionB)
            }

            @Test("should open connection to the same in-memory database")
            func testShouldOpenConnectionToTheSameInMemoryDatabase() async throws {
                let connectionA: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .documentDirectory)
                let connectionB: SQlite3Pointer! = RAnalyticsDatabase.mkAnalyticsDBConnection(
                    databaseName: "",
                    databaseParentDirectory: .documentDirectory)
                let databaseA = DatabaseTestUtils.mkDatabase(connection: connectionA)

                let blob = "foo".data(using: .utf8)!
                let anotherBlob = "bar".data(using: .utf8)!

                databaseA.enabled = true
                await databaseA.insert(blobs: [blob, anotherBlob], into: "some_table", limit: 0)
                let insertedBlobs = DatabaseTestUtils.fetchTableContents("some_table", connection: connectionB)
                #expect(insertedBlobs == [blob, anotherBlob])

                sqlite3_close_v2(connectionA)
                sqlite3_close_v2(connectionB)
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable line_length
