import Testing
import SQLite3
import Foundation
@testable import RakutenAnalytics

#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsDatabase")
struct RAnalyticsDatabaseFunctionalTests {
    static let databaseParentDirectory = FileManager.SearchPathDirectory.documentDirectory
    static let databaseName = "RSDKAnalytics_Test.db"
    static let events = [mkEvent, mkAnotherEvent]
    
    var connection: SQlite3Pointer!
    var databaseURL: URL!
    var database: RAnalyticsDatabase!
    
    init() {
        databaseURL = FileManager.default.databaseFileURL(
            databaseName: Self.databaseName, databaseParentDirectory: Self.databaseParentDirectory)
        try? FileManager.default.removeItem(at: databaseURL)
    }
    
    mutating func setUp() {
        connection = RAnalyticsDatabase.mkAnalyticsDBConnection(
            databaseName: Self.databaseName, databaseParentDirectory: Self.databaseParentDirectory)
        guard let safeConnection = connection else { return }
        database = RAnalyticsDatabase.database(connection: safeConnection)
    }
    
    mutating func tearDown() {
        database?.closeConnection()
        connection = nil
        try? FileManager.default.removeItem(at: databaseURL)
    }
    
    @Test("should create database stored in a file")
    mutating func testDatabaseFileCreation() {
        setUp()
        defer { tearDown() }
        #expect(FileManager.default.fileExists(atPath: databaseURL.path) == true)
    }
    
    @Test("should insert events to database")
    mutating func testInsertEvents() async {
        setUp()
        defer { tearDown() }
        
        let testDatabase = database!
        let testConnection = connection!
        
        await withCheckedContinuation { continuation in
            testDatabase.insert(blobs: Self.events, into: "events_table", limit: 2) {
                continuation.resume()
            }
        }
        
        let eventsInDb = DatabaseTestUtils.fetchTableContents("events_table", connection: testConnection)
        #expect(eventsInDb.elementsEqual(Self.events))
    }
    
    @Test("should fetch saved events from database")
    mutating func testFetchEvents() async {
        setUp()
        defer { tearDown() }
        
        let testConnection = connection!
        DatabaseTestUtils.insert(blobs: Self.events, table: "events_table", connection: testConnection)
        
        let testDatabase = database!
        let (fetchedEvents, fetchedIds) = await withCheckedContinuation { continuation in
            testDatabase.fetchBlobs(2, from: "events_table") { blobs, ids in
                continuation.resume(returning: (blobs, ids))
            }
        }
        
        #expect(fetchedEvents?.elementsEqual(Self.events) == true)
        #expect(fetchedIds?.elementsEqual([1, 2]) == true)
    }
    
    @Test("should delete saved events according to passed IDs")
    mutating func testDeleteEvents() async {
        setUp()
        defer { tearDown() }
        
        let testConnection = connection!
        DatabaseTestUtils.insert(blobs: Self.events, table: "events_table", connection: testConnection)
        
        let testDatabase = database!
        await withCheckedContinuation { continuation in
            testDatabase.deleteBlobs(identifiers: [1, 2], in: "events_table") {
                let eventsInDb = DatabaseTestUtils.fetchTableContents("events_table", connection: testConnection)
                #expect(eventsInDb.isEmpty == true)
                continuation.resume()
            }
        }
    }
    
    static let mkEvent = #"""
        {
        "ckp": "bd8ac43958a9e7fa0f097c0a0ba5c2979299e69d",
        "ts1": 1526965941,
        "ltm": "2018-05-22 14:12:22",
        "app_name": "jp.co.rakuten.Host",
        "ua": "jp.co.rakuten.Host/1.0",
        "etype": "_rem_launch",
        "aid": 1,
        "mori": 1,
        "mnetw": 1,
        "dln": "en",
        "tzo": 9,
        "res": "414x736",
        "ver": "3.0.0",
        "cks": "D4EE83DC-815B-41D4-88D8-BE94C4B7E0E2",
        "acc": 477,
        "cka": "334A064E-3B19-45FA-BED2-A887E68FF8B3",
        "app_ver": "1.0",
        "model": "x86_64",
        "mos": "iOS 11.2",
        "online": true,
        "cp": {
        "days_since_last_use": 0,
        "days_since_first_use": 0
        }
        }
    """#.data(using: .utf8)!
    
    static let mkAnotherEvent = #"""
        {
        "ckp": "bd8ac43958a9e7fa0f097c0a0ba5c2979299e69d",
        "ts1": 1526966160,
        "ltm": "2018-05-22 14:12:22",
        "app_name": "jp.co.rakuten.Host",
        "ua": "jp.co.rakuten.Host/1.0",
        "etype": "_rem_credential_strategies",
        "aid": 1,
        "mori": 1,
        "mnetw": 1,
        "dln": "en",
        "tzo": 9,
        "res": "414x736",
        "ver": "3.0.0",
        "cks": "D4EE83DC-815B-41D4-88D8-BE94C4B7E0E2",
        "acc": 477,
        "cka": "334A064E-3B19-45FA-BED2-A887E68FF8B3",
        "app_ver": "1.0",
        "model": "x86_64",
        "mos": "iOS 11.2",
        "online": true,
        "cp": {
        "strategies": {
        "password-manager": "false"
        }
        }
        }
    """#.data(using: .utf8)!
}
