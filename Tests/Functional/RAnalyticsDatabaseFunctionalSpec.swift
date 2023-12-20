import Quick
import Nimble
import SQLite3
import Foundation
@testable import RakutenAnalytics

#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class RAnalyticsDatabaseFunctionalSpec: QuickSpec {

    override func spec() {
        describe("RAnalyticsDatabase") {
            let databaseParentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let databaseName = "RSDKAnalytics_Test.db"
            let events = [mkEvent, mkAnotherEvent]
            var connection: SQlite3Pointer!
            var databaseURL: URL!
            var database: RAnalyticsDatabase!

            beforeSuite {
                databaseURL = FileManager.default.databaseFileURL(databaseName: databaseName, databaseParentDirectory: databaseParentDirectory)

                try? FileManager.default.removeItem(at: databaseURL)
            }

            beforeEach {
                connection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseName,
                                                                        databaseParentDirectory: databaseParentDirectory)
                database = RAnalyticsDatabase.database(connection: connection)
            }

            afterEach {
                database.closeConnection()
                connection = nil

                try? FileManager.default.removeItem(at: databaseURL)
            }

            it("should create database stored in a file") {
                expect(FileManager.default.fileExists(atPath: databaseURL.path)).to(beTrue())
            }

            it("should insert events to database") {
                var eventsInDb: [Data]?
                waitUntil { done in
                    database.insert(blobs: events, into: "events_table", limit: 2) {
                        eventsInDb = DatabaseTestUtils.fetchTableContents("events_table", connection: connection)
                        done()
                    }
                }

                expect(eventsInDb).to(elementsEqual(events))
            }

            it("should fetch saved events from database") {
                DatabaseTestUtils.insert(blobs: events, table: "events_table", connection: connection)

                var fetchedEvents: [Data]?
                var fetchedIds: [Int64]?
                waitUntil { done in
                    database.fetchBlobs(2, from: "events_table") { blobs, ids in
                        fetchedEvents = blobs
                        fetchedIds = ids
                        done()
                    }
                }

                expect(fetchedEvents).to(elementsEqual(events))
                expect(fetchedIds).to(elementsEqual([1, 2]))
            }

            it("should delete saved events according to passed IDs") {
                DatabaseTestUtils.insert(blobs: events, table: "events_table", connection: connection)

                var eventsInDb: [Data]?
                waitUntil { done in
                    database.deleteBlobs(identifiers: [1, 2], in: "events_table") {
                        eventsInDb = DatabaseTestUtils.fetchTableContents("events_table", connection: connection)
                        done()
                    }
                }

                expect(eventsInDb).to(beEmpty())
            }
        }
    }

    let mkEvent = #"""
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

    let mkAnotherEvent = #"""
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
