import Foundation
import Testing
@testable import RakutenAnalytics

@Suite("DataExtensions")
struct DataExtensionsTests {
    
    @Suite("hexString")
    struct HexStringTests {
        @Test("will return empty string for empty data")
        func testEmptyDataReturnsEmptyString() {
            let data = Data()
            #expect(data.hexString.isEmpty)
        }
        
        @Test("will return expected hex string from data")
        func testHexStringFromData() {
            let data = Data(base64Encoded: "EjRWeJCrze8=")!
            #expect(data.hexString == "1234567890abcdef")
        }
    }
}
