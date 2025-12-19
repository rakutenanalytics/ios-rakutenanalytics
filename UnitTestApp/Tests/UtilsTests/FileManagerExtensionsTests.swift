import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("FileManager")
struct FileManagerExtensionsTests {
    
    static func setup() -> (fileManager: FileManager, tempDirectoryURL: URL) {
        let fileManager = FileManager.default
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        MockFileManager.swizzleURLsMethod(toReturn: tempDirectoryURL)
        return (fileManager, tempDirectoryURL)
    }
    
    static func cleanup(fileManager: FileManager, tempDirectoryURL: URL) {
        try? fileManager.removeItem(at: tempDirectoryURL)
        MockFileManager.restoreURLsMethod()
    }
    
    // MARK: - Test databaseFileURL
    
    @Suite("databaseFileURL")
    struct DatabaseFileURLTests {
        @Suite("when analytics directory does not exist")
        struct WhenAnalyticsDirectoryDoesNotExistTests {
            @Test("creates the directory and returns the database file URL")
            func testCreatesDirectoryAndReturnsURL() {
                let (fileManager, tempDirectoryURL) = FileManagerExtensionsTests.setup()
                defer {
                    FileManagerExtensionsTests.cleanup(fileManager: fileManager, tempDirectoryURL: tempDirectoryURL)
                }
                
                let databaseName = "testDatabase.sqlite"
                let analyticsDirectoryURL = tempDirectoryURL.appendingPathComponent("com.rakuten.tech.analytics")
                
                let result = fileManager.databaseFileURL(
                    databaseName: databaseName,
                    databaseParentDirectory: .applicationSupportDirectory)
                
                #expect(result != nil)
                #expect(result?.lastPathComponent == databaseName)
                #expect(fileManager.fileExists(atPath: analyticsDirectoryURL.path) == true)
            }
        }
        
        @Suite("when analytics directory already exists")
        struct WhenAnalyticsDirectoryExistsTests {
            @Test("returns the database file URL without creating the directory")
            func testReturnsURLWithoutCreatingDirectory() {
                let (fileManager, tempDirectoryURL) = setup()
                defer {
                    cleanup(fileManager: fileManager, tempDirectoryURL: tempDirectoryURL)
                }
                
                let databaseName = "testDatabase.sqlite"
                let analyticsDirectoryURL = tempDirectoryURL.appendingPathComponent("com.rakuten.tech.analytics")
                
                try? fileManager.createDirectory(at: analyticsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                
                let result = fileManager.databaseFileURL(
                    databaseName: databaseName,
                    databaseParentDirectory: .applicationSupportDirectory)
                
                #expect(result != nil)
                #expect(result?.lastPathComponent == databaseName)
                #expect(fileManager.fileExists(atPath: analyticsDirectoryURL.path) == true)
            }
        }
    }
    
    // MARK: - Test createSafeFile
    
    @Suite("createSafeFile")
    struct CreateSafeFileTests {
        @Suite("when file does not exist")
        struct WhenFileDoesNotExistTests {
            @Test("creates the file")
            func testCreatesFile() {
                let (fileManager, tempDirectoryURL) = setup()
                defer {
                    cleanup(fileManager: fileManager, tempDirectoryURL: tempDirectoryURL)
                }
                
                let testFileURL = tempDirectoryURL.appendingPathComponent("testfile.txt")
                fileManager.createSafeFile(at: testFileURL)
                #expect(fileManager.fileExists(atPath: testFileURL.path) == true)
            }
        }
        
        @Suite("when file already exists")
        struct WhenFileExistsTests {
            @Test("does not create the file again")
            func testDoesNotCreateFileAgain() {
                let (fileManager, tempDirectoryURL) = setup()
                defer {
                    cleanup(fileManager: fileManager, tempDirectoryURL: tempDirectoryURL)
                }
                
                let testFileURL = tempDirectoryURL.appendingPathComponent("testfile.txt")
                fileManager.createFile(atPath: testFileURL.path, contents: nil, attributes: nil)
                fileManager.createSafeFile(at: testFileURL)
                #expect(fileManager.fileExists(atPath: testFileURL.path) == true)
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
