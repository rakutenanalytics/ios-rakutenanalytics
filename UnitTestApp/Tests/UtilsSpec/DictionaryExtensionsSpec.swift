import Foundation
import Testing
@testable import RakutenAnalytics

@Suite("DictionaryExtensions")
struct DictionaryExtensionsSpec {
    
    @Suite("+=")
    struct DictionaryPlusEqualsTests {
        
        @Suite("leftDictionary is empty")
        struct LeftDictionaryEmptyTests {
            
            @Suite("rightDictionary is not empty")
            struct RightDictionaryNotEmptyTests {
                @Test("should add rightDictionary entries to leftDictionary")
                func testAddRightDictionaryEntries() {
                    var leftDictionary: [String: String] = [:]
                    let rightDictionary: [String: String] = ["key1": "value1", "key2": "value2"]
                    
                    leftDictionary += rightDictionary
                    #expect(leftDictionary["key1"] == "value1")
                    #expect(leftDictionary["key2"] == "value2")
                }
            }
            
            @Suite("rightDictionary is empty")
            struct RightDictionaryEmptyTests {
                @Test("should add nothing when there are no entries")
                func testAddNothingWhenNoEntries() {
                    var leftDictionary: [String: String] = [:]
                    let rightDictionary: [String: String] = [:]
                    
                    leftDictionary += rightDictionary
                    #expect(leftDictionary.isEmpty)
                }
            }
        }
        
        @Suite("leftDictionary is not empty")
        struct LeftDictionaryNotEmptyTests {
            
            @Suite("rightDictionary is not empty")
            struct RightDictionaryNotEmptyTests {
                @Test("should add rightDictionary entries to leftDictionary")
                func testAddRightDictionaryEntries() {
                    var leftDictionary: [String: String] = ["key3": "value3", "key4": "value4"]
                    let rightDictionary: [String: String] = ["key1": "value1", "key2": "value2"]
                    
                    leftDictionary += rightDictionary
                    #expect(leftDictionary["key1"] == "value1")
                    #expect(leftDictionary["key2"] == "value2")
                    #expect(leftDictionary["key3"] == "value3")
                    #expect(leftDictionary["key4"] == "value4")
                }
            }
            
            @Suite("rightDictionary is empty")
            struct RightDictionaryEmptyTests {
                @Test("should add nothing when there are no entries")
                func testAddNothingWhenNoEntries() {
                    var leftDictionary: [String: String] = ["key3": "value3", "key4": "value4"]
                    let rightDictionary: [String: String] = [:]
                    
                    leftDictionary += rightDictionary
                    #expect(leftDictionary["key3"] == "value3")
                    #expect(leftDictionary["key4"] == "value4")
                }
            }
        }
    }
}
