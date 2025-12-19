// swiftlint:disable line_length

import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - DatabaseDirectoriesTests

@Suite("FileManager")
struct DatabaseDirectoriesTests {
    @Suite("databaseFileURL(databaseName:databaseParentDirectory:)")
    struct DatabaseFileURLTests {
        static let databaseName = "MyDatabase.db"

        @Suite("when databaseParentDirectory is documentDirectory")
        struct WhenDatabaseParentDirectoryIsDocumentDirectoryTests {
            @Test("should return Documents/MyDatabase.db")
            func testReturnsDocumentsPath() {
                let databaseFileURL = FileManager.default.databaseFileURL(databaseName: DatabaseFileURLTests.databaseName, databaseParentDirectory: .documentDirectory)
                #expect(databaseFileURL?.absoluteString.hasSuffix("Documents/MyDatabase.db") == true)
            }
        }

        @Suite("when databaseParentDirectory is applicationSupportDirectory")
        struct WhenDatabaseParentDirectoryIsApplicationSupportDirectoryTests {
            @Test("should return Library/Application Support/com.rakuten.tech.analytics/MyDatabase.db")
            func testReturnsApplicationSupportPath() {
                let databaseFileURL = FileManager.default.databaseFileURL(databaseName: DatabaseFileURLTests.databaseName, databaseParentDirectory: .applicationSupportDirectory)
                #expect(databaseFileURL?.absoluteString.hasSuffix("Library/Application%20Support/com.rakuten.tech.analytics/MyDatabase.db") == true)
            }
        }

        @Suite("when databaseParentDirectory is not handled")
        struct WhenDatabaseParentDirectoryIsNotHandledTests {
            @Test("should return nil")
            func testReturnsNil() {
                let databaseFileURL = FileManager.default.databaseFileURL(databaseName: DatabaseFileURLTests.databaseName, databaseParentDirectory: .cachesDirectory)
                #expect(databaseFileURL == nil)
            }
        }
    }
}

// swiftlint:enable line_length
