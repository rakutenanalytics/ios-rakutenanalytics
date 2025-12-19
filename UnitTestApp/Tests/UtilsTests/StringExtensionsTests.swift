import Foundation
import Testing
@testable import RakutenAnalytics

@Suite("StringExtensions")
struct StringExtensionsTests {
    
    @Suite("addEncodingForRFC3986UnreservedCharacters")
    struct AddEncodingForRFC3986UnreservedCharactersTests {
        
        @Suite("The string to encode is empty")
        struct EmptyStringTests {
            @Test("should return empty string")
            func testReturnsEmptyString() {
                let str = ""
                #expect(str.addEncodingForRFC3986UnreservedCharacters() == "")
            }
        }
        
        @Suite("The string to encode is not empty")
        struct NonEmptyStringTests {
            @Test("should return the same string when it does not contain RFC3986 reserved characters")
            func testReturnsSameStringForNoReservedCharacters() {
                let str = "sentence"
                #expect(str.addEncodingForRFC3986UnreservedCharacters() == "sentence")
            }
            
            @Test("should return the encoded string when it contains RFC3986 reserved characters")
            func testReturnsEncodedStringForReservedCharacters() {
                let str = "sentence:#[]@!$&'()*+,;="
                #expect(str.addEncodingForRFC3986UnreservedCharacters() == "sentence%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")
            }
        }
    }
    
    @Suite("Subscript")
    struct SubscriptTests {
        @Suite("Range in bounds")
        struct RangeInBoundsTests {
            @Test("should return a substring")
            func testReturnsSubstring() {
                #expect("hello"[2..<4] == "ll")
            }
        }
    }
}
