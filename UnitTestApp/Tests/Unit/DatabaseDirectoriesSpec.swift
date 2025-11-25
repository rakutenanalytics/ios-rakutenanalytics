// swiftlint:disable line_length

import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - DatabaseDirectoriesSpec

final class DatabaseDirectoriesSpec: QuickSpec {
    override class func spec() {
        describe("FileManager") {
            describe("databaseFileURL(databaseName:databaseParentDirectory:)") {
                let databaseName = "MyDatabase.db"

                context("when databaseParentDirectory is documentDirectory") {
                    it("should return Documents/MyDatabase.db") {
                        let databaseFileURL = FileManager.default.databaseFileURL(databaseName: databaseName, databaseParentDirectory: .documentDirectory)
                        expect(databaseFileURL?.absoluteString.hasSuffix("Documents/MyDatabase.db")).to(beTrue())
                    }
                }

                context("when databaseParentDirectory is applicationSupportDirectory") {
                    it("should return Library/Application Support/com.rakuten.tech.analytics/MyDatabase.db") {
                        let databaseFileURL = FileManager.default.databaseFileURL(databaseName: databaseName, databaseParentDirectory: .applicationSupportDirectory)
                        expect(databaseFileURL?.absoluteString.hasSuffix("Library/Application%20Support/com.rakuten.tech.analytics/MyDatabase.db")).to(beTrue())
                    }
                }

                context("when databaseParentDirectory is not handled") {
                    it("should return nil") {
                        let databaseFileURL = FileManager.default.databaseFileURL(databaseName: databaseName, databaseParentDirectory: .cachesDirectory)
                        expect(databaseFileURL).to(beNil())
                    }
                }
            }
        }
    }
}

// swiftlint:enable line_length
