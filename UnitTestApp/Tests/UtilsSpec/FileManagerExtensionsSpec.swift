import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class FileManagerExtensionsSpec: QuickSpec {
    override class func spec() {
        describe("FileManager") {
            var fileManager: FileManager!
            var tempDirectoryURL: URL!

            beforeEach {
                fileManager = FileManager.default
                tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
                try? fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                MockFileManager.swizzleURLsMethod(toReturn: tempDirectoryURL)
            }

            afterEach {
                try? fileManager.removeItem(at: tempDirectoryURL)
                MockFileManager.restoreURLsMethod()
            }

            // MARK: - Test databaseFileURL

            describe("databaseFileURL") {
                context("when analytics directory does not exist") {
                    it("creates the directory and returns the database file URL") {
                        let databaseName = "testDatabase.sqlite"
                        let analyticsDirectoryURL = tempDirectoryURL.appendingPathComponent("com.rakuten.tech.analytics")

                        let result = fileManager.databaseFileURL(databaseName: databaseName, databaseParentDirectory: .applicationSupportDirectory)

                        expect(result).toNot(beNil())
                        expect(result?.lastPathComponent).to(equal(databaseName))
                        expect(fileManager.fileExists(atPath: analyticsDirectoryURL.path)).to(beTrue())
                    }
                }

                context("when analytics directory already exists") {
                    it("returns the database file URL without creating the directory") {
                        let databaseName = "testDatabase.sqlite"
                        let analyticsDirectoryURL = tempDirectoryURL.appendingPathComponent("com.rakuten.tech.analytics")

                        try? fileManager.createDirectory(at: analyticsDirectoryURL, withIntermediateDirectories: true, attributes: nil)

                        let result = fileManager.databaseFileURL(databaseName: databaseName, databaseParentDirectory: .applicationSupportDirectory)

                        expect(result).toNot(beNil())
                        expect(result?.lastPathComponent).to(equal(databaseName))
                        expect(fileManager.fileExists(atPath: analyticsDirectoryURL.path)).to(beTrue())
                    }
                }
            }

            // MARK: - Test createSafeFile

            describe("createSafeFile") {
                context("when file does not exist") {
                    it("creates the file") {
                        let testFileURL = tempDirectoryURL.appendingPathComponent("testfile.txt")
                        fileManager.createSafeFile(at: testFileURL)
                        expect(fileManager.fileExists(atPath: testFileURL.path)).to(beTrue())
                    }
                }

                context("when file already exists") {
                    it("does not create the file again") {
                        let testFileURL = tempDirectoryURL.appendingPathComponent("testfile.txt")
                        fileManager.createFile(atPath: testFileURL.path, contents: nil, attributes: nil)
                        fileManager.createSafeFile(at: testFileURL)
                        expect(fileManager.fileExists(atPath: testFileURL.path)).to(beTrue())
                    }
                }
            }
        }
    }
}

// MARK: - Mock FileManager for Swizzling

class MockFileManager: FileManager {
    private static var originalURLsMethod: Method?
    private static var swizzledURLsMethod: Method?

    @objc func mockURLs(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return [MockFileManager.mockedDirectoryURL]
    }

    static var mockedDirectoryURL: URL!

    static func swizzleURLsMethod(toReturn directoryURL: URL) {
        mockedDirectoryURL = directoryURL

        let originalSelector = #selector(FileManager.urls(for:in:))
        let swizzledSelector = #selector(MockFileManager.mockURLs(for:in:))

        originalURLsMethod = class_getInstanceMethod(FileManager.self, originalSelector)
        swizzledURLsMethod = class_getInstanceMethod(MockFileManager.self, swizzledSelector)

        if let originalMethod = originalURLsMethod, let swizzledMethod = swizzledURLsMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    static func restoreURLsMethod() {
        guard let originalMethod = originalURLsMethod, let swizzledMethod = swizzledURLsMethod else { return }
        method_exchangeImplementations(swizzledMethod, originalMethod)
    }
}
